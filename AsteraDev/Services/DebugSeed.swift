#if DEBUG
import Foundation
import SwiftData

/// Launch-environment seeding, so end-to-end tests can start on any screen in any state without
/// driving onboarding first. Compiled out of release builds entirely.
///
/// Every knob is read from the environment rather than baked in, so a test states the state it
/// needs and a reader of that test can see it:
///
///     ASTERA_FORCE_HOME=1              skip onboarding
///     ASTERA_SEED_MODE=perimenopause   any CycleMode raw value
///     ASTERA_SEED_BIRTH_YEAR=2012      drives the age gates in AgeMode
///     ASTERA_SEED_CYCLES=0             number of past cycles; 0 gives the empty first-run state
///     ASTERA_INITIAL_TAB=settings      today | history | settings
///     ASTERA_OPEN_SHEET=log            log | why
enum DebugSeed {
    static let defaultBirthYear = 1995
    static let defaultCycleCount = 3

    private static func value(_ key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }

    static var isEnabled: Bool { value("ASTERA_FORCE_HOME") == "1" }

    /// Any CycleMode raw value. Driven off the enum rather than a hand-written switch, so a new
    /// mode is testable the moment it exists instead of silently falling back to `.regular`.
    static var mode: CycleMode {
        guard let raw = value("ASTERA_SEED_MODE") else { return .regular }
        guard let mode = CycleMode(rawValue: raw) else {
            assertionFailure("ASTERA_SEED_MODE=\(raw) is not a CycleMode raw value")
            return .regular
        }
        return mode
    }

    static var birthYear: Int {
        value("ASTERA_SEED_BIRTH_YEAR").flatMap(Int.init) ?? defaultBirthYear
    }

    static var cycleCount: Int {
        value("ASTERA_SEED_CYCLES").flatMap(Int.init) ?? defaultCycleCount
    }

    /// Wipes anything a previous launch left behind, then inserts a profile and `cycleCount`
    /// past cycles roughly 28 days apart, most recent first.
    ///
    /// The reset matters: the SwiftData store and UserDefaults both survive between launches of
    /// the same install, so without it a test inherits whatever the previous test seeded and
    /// quietly asserts against the wrong state.
    static func apply(in context: ModelContext) {
        reset(context)

        let profile = UserProfile(
            pronouns: .theyThem,
            salutation: .girl, // demo: warm "Hey, girlie 🌸" greeting
            relationshipStructure: .single,
            cycleMode: mode,
            birthYear: birthYear
        )
        context.insert(profile)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 14, 42, 70 days ago, and so on backwards for higher counts.
        for index in 0..<max(0, cycleCount) {
            let daysAgo = 14 + (index * 28)
            guard let startDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let cycle = Cycle(startDate: startDate, modeAtStart: mode)
            context.insert(cycle)

            for (offset, intensity) in [FlowIntensity.medium, .medium, .light].enumerated() {
                guard let day = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }
                let flow = FlowEntry(day: day, intensity: intensity, source: .manual)
                flow.cycle = cycle
                context.insert(flow)
            }
        }

        try? context.save()

        // The profile was inserted in this pass, so RootView's @Query hasn't seen it yet. Reconcile
        // from the seeded value directly, or an under-16 seed would keep an adult's toggle state.
        AgeMode.reconcileAgeGatedSettings(birthYear: birthYear)
    }

    private static func reset(_ context: ModelContext) {
        try? context.delete(model: FlowEntry.self)
        try? context.delete(model: SymptomEntry.self)
        try? context.delete(model: PredictionSnapshot.self)
        try? context.delete(model: Cycle.self)
        try? context.delete(model: UserProfile.self)

        // Logging preferences are @AppStorage, so they outlive the store too. Put every key back
        // to the value a fresh install would have.
        let defaults = UserDefaults.standard
        for (key, value) in [
            (AppStorageKey.requiresAppLock, false),
            (AppStorageKey.showInCalendar, false),
            (AppStorageKey.syncToHealth, false),
            (AppStorageKey.notifyPeriodInThreeDays, false),
            (AppStorageKey.notifyPeriodToday, false),
            (AppStorageKey.showSexualActivity, false),
            (AppStorageKey.showCravingsLogging, false),
            (AppStorageKey.showSymptomsLogging, true),
            (AppStorageKey.showLifestyleLogging, false),
        ] as [(AppStorageKey, Bool)] {
            defaults.set(value, forKey: key.rawValue)
        }

        try? context.save()
    }
}
#endif
