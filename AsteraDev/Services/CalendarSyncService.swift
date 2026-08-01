import Foundation
import EventKit
import UIKit

enum CalendarSyncService {
    static let calendarTitle = "Astera"
    static let asteraNoteMarker = "astera-period-prediction"

    enum AuthorizationState {
        case notRequested
        case denied
        case granted
        case writeOnly
        case restricted
    }

    static var currentAuthorization: AuthorizationState {
        #if DEBUG
        if let stub = DebugPermissions.calendar { return stub }
        #endif
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: return .notRequested
        case .denied: return .denied
        case .authorized: return .granted
        case .writeOnly: return .writeOnly
        case .fullAccess: return .granted
        case .restricted: return .restricted
        @unknown default: return .notRequested
        }
    }

    /// Asks for Calendar access. Returns the resulting authorization state.
    @discardableResult
    static func requestAccess() async -> AuthorizationState {
        #if DEBUG
        // Before touching EKEventStore: asking it would put the real system dialog on screen,
        // which no test can dismiss.
        if let stub = DebugPermissions.calendar { return stub }
        #endif
        let store = EKEventStore()
        do {
            if #available(iOS 17.0, *) {
                _ = try await store.requestFullAccessToEvents()
            } else {
                _ = try await store.requestAccess(to: .event)
            }
        } catch {
            return .denied
        }
        return currentAuthorization
    }

    /// Snapshot of what the calendar needs to know. Built on the main actor before the sync runs in the background.
    struct SyncPayload: Sendable {
        struct Period: Sendable {
            let start: Date
            let end: Date
            let title: String
            let notes: String
        }
        let pastPeriods: [Period]
        let upcoming: Period?
    }

    /// Build a snapshot of the upcoming prediction, and past bleed clusters if the user asked for
    /// them. Run on the main actor; pass the payload to `sync(_:)`.
    ///
    /// Pass `predictsPeriods: false` to omit the upcoming-period event (pregnancy / post-loss /
    /// postpartum modes).
    ///
    /// `includePastPeriods` defaults to false, and the default is the point. A calendar is the one
    /// place Astera's data leaves the app: it can sync to a work account, a shared family
    /// calendar, or a partner's phone. A forecast of one upcoming period is a small thing to find
    /// there. Two years of logged bleeds is not, and it is not what someone turning on a toggle
    /// labelled "add your periods to a calendar" is likely to have pictured.
    @MainActor
    static func makePayload(
        cycles: [Cycle],
        prediction: PeriodPrediction,
        predictsPeriods: Bool = true,
        includePastPeriods: Bool = false
    ) -> SyncPayload {
        let cal = Calendar.current
        var past: [SyncPayload.Period] = []

        for cycle in includePastPeriods ? cycles : [] {
            let bleedDays = (cycle.flowEntries ?? [])
                .filter { $0.intensity.rawValue >= FlowIntensity.light.rawValue }
                .map { cal.startOfDay(for: $0.day) }
                .sorted()

            if let first = bleedDays.first, let last = bleedDays.last {
                past.append(.init(
                    start: first,
                    end: last,
                    title: "Period",
                    notes: "\(asteraNoteMarker)\n\nFrom Astera. \(bleedDays.count) day\(bleedDays.count == 1 ? "" : "s") of bleed logged."
                ))
            } else {
                // Cycle has no bleed flow entries; fall back to the recorded start date as a single-day period.
                let day = cal.startOfDay(for: cycle.startDate)
                past.append(.init(
                    start: day,
                    end: day,
                    title: "Period",
                    notes: "\(asteraNoteMarker)\n\nFrom Astera. Period start (no flow detail logged)."
                ))
            }
        }

        // Future or current prediction. Only include if it's not already in the past (older than 14 days back)
        // and the active mode wants period predictions at all.
        let cutoff = cal.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let upcoming: SyncPayload.Period?
        if predictsPeriods && prediction.upperBound >= cutoff {
            upcoming = SyncPayload.Period(
                start: cal.startOfDay(for: prediction.lowerBound),
                end: cal.startOfDay(for: prediction.upperBound),
                title: PeriodPrediction.expectedLabel,
                notes: "\(asteraNoteMarker)\n\nFrom Astera. \(prediction.confidenceLabel). Estimates only, not medical advice."
            )
        } else {
            upcoming = nil
        }

        return SyncPayload(pastPeriods: past, upcoming: upcoming)
    }

    /// Writes past bleed periods + upcoming prediction into the dedicated "Astera" calendar.
    /// Replaces any prior Astera-written events. This is the single source of truth from Astera into your calendar.
    static func sync(_ payload: SyncPayload) throws {
        let store = EKEventStore()
        guard let calendar = try ensureCalendar(in: store) else {
            throw CalendarSyncError.noWritableSource
        }
        try removeAsteraEvents(in: calendar, store: store)

        for past in payload.pastPeriods {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = past.title
            event.startDate = past.start
            event.endDate = past.end
            event.isAllDay = true
            event.notes = past.notes
            try store.save(event, span: .thisEvent, commit: false)
        }

        if let upcoming = payload.upcoming {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = upcoming.title
            event.startDate = upcoming.start
            event.endDate = upcoming.end
            event.isAllDay = true
            event.notes = upcoming.notes
            try store.save(event, span: .thisEvent, commit: false)
        }

        try store.commit()
    }

    /// Convenience for prediction-only syncs (used when we don't have cycles handy).
    static func sync(prediction: PeriodPrediction) throws {
        let payload = SyncPayload(
            pastPeriods: [],
            upcoming: .init(
                start: Calendar.current.startOfDay(for: prediction.lowerBound),
                end: Calendar.current.startOfDay(for: prediction.upperBound),
                title: PeriodPrediction.expectedLabel,
                notes: "\(asteraNoteMarker)\n\nFrom Astera. \(prediction.confidenceLabel). Estimates only, not medical advice."
            )
        )
        try sync(payload)
    }

    /// Removes Astera events but leaves the calendar itself, so re-enabling sync is instant.
    static func clearEvents() throws {
        let store = EKEventStore()
        guard let calendar = findCalendar(in: store) else { return }
        try removeAsteraEvents(in: calendar, store: store)
    }

    // MARK: - Internals

    private static func removeAsteraEvents(in calendar: EKCalendar, store: EKEventStore) throws {
        let windowStart = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        let windowEnd = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
        let predicate = store.predicateForEvents(withStart: windowStart, end: windowEnd, calendars: [calendar])
        for event in store.events(matching: predicate) {
            try store.remove(event, span: .thisEvent, commit: false)
        }
        try store.commit()
    }

    private static func findCalendar(in store: EKEventStore) -> EKCalendar? {
        store.calendars(for: .event).first { $0.title == calendarTitle && $0.allowsContentModifications }
    }

    private static func ensureCalendar(in store: EKEventStore) throws -> EKCalendar? {
        if let existing = findCalendar(in: store) { return existing }
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = calendarTitle
        calendar.cgColor = UIColor(red: 0.612, green: 0.290, blue: 0.322, alpha: 1).cgColor

        let preferredSource: EKSource? = store.sources.first(where: { $0.sourceType == .calDAV }) ?? store.sources.first(where: { $0.sourceType == .local })
        guard let source = preferredSource else { return nil }
        calendar.source = source

        try store.saveCalendar(calendar, commit: true)
        return calendar
    }
}

enum CalendarSyncError: Error {
    case noWritableSource
}
