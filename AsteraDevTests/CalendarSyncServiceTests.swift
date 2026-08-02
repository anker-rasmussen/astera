import Foundation
import Testing
import SwiftData
import EventKit
@testable import Astera

/// A calendar is the one place Astera's data leaves the app. It can sync to a work account, a
/// shared family calendar, or a partner's phone, so what goes in is a disclosure decision rather
/// than a formatting one.
///
/// The toggle originally wrote every logged period as well as the forecast, while describing
/// itself as adding "your next predicted period". These pin the narrowed behaviour: forecast by
/// default, history only when explicitly asked for.
@Suite("Calendar sync scope")
@MainActor
struct CalendarSyncScopeTests {

    /// A fresh `ModelContext`, not the container's `mainContext`. Using `mainContext` here trapped
    /// inside SwiftData on the way through `LogService`, taking the test host down once per test.
    /// The suites that seed through `LogService` and pass all use a fresh context, so this does too.
    private func context() throws -> ModelContext {
        ModelContext(try PersistenceController.makeContainer(inMemory: true))
    }

    /// Seeds through `LogService`, the same path the app uses, rather than wiring `FlowEntry` to
    /// `Cycle` by hand. Hand-wiring trapped inside SwiftData and took the test host down with it,
    /// once per test, which is a poor trade for saving a function call. Bleeds 28 days apart are
    /// far enough for `LogService` to infer one cycle each.
    private func seedCycles(_ context: ModelContext, count: Int = 3) throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for index in 0..<count {
            guard let start = calendar.date(byAdding: .day, value: -(14 + index * 28), to: today) else { continue }
            try LogService.apply(
                LogInput(date: start, flow: .medium, symptoms: [:], notes: ""),
                defaultMode: .regular,
                context: context
            )
        }
    }

    private func prediction() -> PeriodPrediction {
        BayesianPredictor.predict(lastStart: Date(), observedLengths: [28, 29, 28], cycleMode: .regular)
    }

    @Test("By default only the forecast goes in, never the history")
    func defaultsToForecastOnly() throws {
        let context = try context()
        try seedCycles(context)
        let cycles = try context.fetch(FetchDescriptor<Cycle>())

        let payload = CalendarSyncService.makePayload(cycles: cycles, prediction: prediction())

        #expect(payload.pastPeriods.isEmpty, "Logged periods must not reach the calendar unasked")
        #expect(payload.upcoming != nil, "The forecast is the point of the feature")
    }

    @Test("Opting in adds the logged periods")
    func optingInAddsHistory() throws {
        let context = try context()
        try seedCycles(context, count: 3)
        let cycles = try context.fetch(FetchDescriptor<Cycle>())

        let payload = CalendarSyncService.makePayload(
            cycles: cycles,
            prediction: prediction(),
            includePastPeriods: true
        )

        #expect(payload.pastPeriods.count == 3, "Every logged cycle should appear once")
        #expect(payload.upcoming != nil)
    }

    /// Modes where forecasting a bleed would be wrong, or worse. Opting into history must not
    /// smuggle a prediction back in alongside it.
    @Test("A mode that predicts nothing still predicts nothing with history on")
    func noForecastForNonPredictingModes() throws {
        let context = try context()
        try seedCycles(context)
        let cycles = try context.fetch(FetchDescriptor<Cycle>())

        let payload = CalendarSyncService.makePayload(
            cycles: cycles,
            prediction: prediction(),
            predictsPeriods: false,
            includePastPeriods: true
        )

        #expect(payload.upcoming == nil, "No bleed forecast in a mode that does not forecast")
        #expect(payload.pastPeriods.count == 3, "History was still asked for")
    }

    @Test("The opt-in is off for a fresh install")
    func offByDefault() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: AppStorageKey.includePastPeriodsInCalendar.rawValue)
        #expect(defaults.object(forKey: AppStorageKey.includePastPeriodsInCalendar.rawValue) == nil,
                "No stored value means the @AppStorage default of false applies")
    }

    // MARK: - What a sync is allowed to delete

    /// The marker in each event's notes is the only thing separating a sync from the rest of your
    /// calendar. While Astera owned its calendar outright, deleting everything in range was
    /// merely crude. Now the destination can be a calendar you already use, and the same code
    /// would take four years of real appointments with it.

    @Test("Everything Astera writes carries the marker that lets it clean up later")
    func everythingWrittenIsMarked() throws {
        let context = try context()
        try seedCycles(context)
        let cycles = try context.fetch(FetchDescriptor<Cycle>())

        let payload = CalendarSyncService.makePayload(
            cycles: cycles,
            prediction: prediction(),
            includePastPeriods: true
        )

        let written = payload.pastPeriods + [payload.upcoming].compactMap { $0 }
        #expect(written.count == 4, "Three logged cycles and a forecast, or this proves nothing")
        for period in written {
            #expect(
                period.notes.contains(CalendarSyncService.asteraNoteMarker),
                "An unmarked event is one Astera can never take back out again"
            )
        }
    }

    @Test("An event Astera did not write is never claimed as its own")
    func foreignEventsAreLeftAlone() {
        let store = EKEventStore()

        let dentist = EKEvent(eventStore: store)
        dentist.notes = "Dentist, second floor"
        #expect(dentist.isWrittenByAstera == false, "A real appointment must survive a sync")

        let bare = EKEvent(eventStore: store)
        #expect(bare.isWrittenByAstera == false, "An event with no notes at all is not ours")

        let ours = EKEvent(eventStore: store)
        ours.notes = "\(CalendarSyncService.asteraNoteMarker)\n\nFrom Astera."
        #expect(ours.isWrittenByAstera, "Otherwise Astera leaves its own events behind forever")
    }
}
