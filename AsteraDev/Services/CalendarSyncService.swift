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
        guard let calendar = try resolveCalendar(in: store) else {
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
    ///
    /// Clears both possible homes, not just the current one. A destination that changed while
    /// sync was off would otherwise leave events behind in the calendar nobody is looking at.
    static func clearEvents() throws {
        let store = EKEventStore()
        for calendar in [chosenCalendar(in: store), findCalendar(in: store)].compactMap({ $0 }) {
            try removeAsteraEvents(in: calendar, store: store)
        }
    }

    // MARK: - Internals

    /// Removes only the events Astera wrote, identified by the marker in their notes.
    ///
    /// The marker check is not defensive tidiness, it is the whole safety of this function. It
    /// used to delete every event the predicate returned, which was survivable only while Astera
    /// owned the calendar outright. The moment the destination can be a calendar you already use,
    /// that same code deletes four years of your real appointments on the first sync.
    private static func removeAsteraEvents(in calendar: EKCalendar, store: EKEventStore) throws {
        let windowStart = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        let windowEnd = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
        let predicate = store.predicateForEvents(withStart: windowStart, end: windowEnd, calendars: [calendar])
        for event in store.events(matching: predicate) where event.isWrittenByAstera {
            try store.remove(event, span: .thisEvent, commit: false)
        }
        try store.commit()
    }

    private static func findCalendar(in store: EKEventStore) -> EKCalendar? {
        store.calendars(for: .event).first { $0.title == calendarTitle && $0.allowsContentModifications }
    }

    // MARK: - Where the events go

    /// The calendar Astera writes to: one you picked, or its own.
    ///
    /// Falls back rather than failing, because `calendarIdentifier` is not a durable handle. It
    /// changes on a restore, on a reinstall, and when the account the calendar belonged to is
    /// removed. A stale identifier means the calendar you chose is gone, and the useful answer to
    /// that is Astera's own calendar rather than an error about a calendar you no longer have.
    private static func resolveCalendar(in store: EKEventStore) throws -> EKCalendar? {
        if let chosen = chosenCalendar(in: store) { return chosen }
        return try ensureCalendar(in: store)
    }

    private static func chosenCalendar(in store: EKEventStore) -> EKCalendar? {
        guard let identifier = destinationIdentifier(),
              let calendar = store.calendar(withIdentifier: identifier),
              calendar.allowsContentModifications
        else { return nil }
        return calendar
    }

    /// Nil when Astera should use its own calendar.
    ///
    /// Stored as a string because `@AppStorage` has no optional, so "no choice made" and "chose
    /// Astera's own" are both the empty string on disk and both nil here. The `defaults`
    /// parameter follows `AgeMode.reconcileAgeGatedSettings`, so a test can hand in a suite of
    /// its own instead of writing to the real preferences.
    static func destinationIdentifier(in defaults: UserDefaults = .standard) -> String? {
        let stored = defaults.string(forKey: AppStorageKey.calendarDestination.rawValue)
        return (stored?.isEmpty ?? true) ? nil : stored
    }

    static func setDestinationIdentifier(_ identifier: String?, in defaults: UserDefaults = .standard) {
        defaults.set(identifier ?? "", forKey: AppStorageKey.calendarDestination.rawValue)
    }

    /// Choosing a destination needs to list your calendars, which write-only access cannot do.
    /// iOS offers "Add Events Only" at the prompt, and taking it is a perfectly good answer, so
    /// this is a real state rather than a corner case: those users keep the dedicated calendar.
    static var canChooseDestination: Bool {
        currentAuthorization == .granted
    }

    /// Points Astera at a different calendar, taking its events out of the old one on the way.
    ///
    /// Doing the removal first matters. Skip it and every calendar you ever chose keeps a stale
    /// copy of your cycle, which is the opposite of what someone changing this setting wants.
    static func moveDestination(to identifier: String?) throws {
        if destinationIdentifier() != identifier {
            try? clearEvents()
        }
        setDestinationIdentifier(identifier)
    }

    /// The name to show for the current destination.
    static func destinationName() -> String {
        guard canChooseDestination else { return calendarTitle }
        let store = EKEventStore()
        return chosenCalendar(in: store)?.title ?? calendarTitle
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

extension EKEvent {
    /// Whether Astera wrote this event, by the marker it puts in the notes of everything it
    /// creates. The only thing standing between a sync and someone else's appointments.
    var isWrittenByAstera: Bool {
        notes?.contains(CalendarSyncService.asteraNoteMarker) == true
    }
}
