import Foundation

/// Centralised age-related logic: teen detection + the gentle gate for under-9 users.
/// Spec §9: auto-enabled for ages 11–17 (we use < 18 as a slightly looser bound),
/// gentle gate at < 9, ttc/fertility hidden in teen mode.
enum AgeMode {
    static let minAdvisedAge = 9
    static let teenThreshold = 18
    /// Sex-related logging is hidden below this age, regardless of the per-user toggle.
    /// Set to 16 (UK age of consent) which is older than the broader teen threshold for
    /// fertility content but younger than 18.
    static let sexualContentThreshold = 16

    /// Nobody alive was born before this many years ago, and nobody at all was born after this
    /// year. Deliberately generous at the old end: the point is to exclude nonsense, not to
    /// judge, and the cost of a range that is a decade too kind is nothing.
    static let maxPlausibleAge = 120

    /// The years a birth year is allowed to be.
    ///
    /// The pickers are built from this range, which is the reason it exists. An input that cannot
    /// express an invalid year needs no validation, no error copy and no rejected save. Before
    /// this, both birth year fields took any four digits: `3000` saved happily and then read as
    /// an age of minus a thousand, which every age gate treats as a small child.
    static var validBirthYears: ClosedRange<Int> {
        let thisYear = Calendar.current.component(.year, from: Date())
        return (thisYear - maxPlausibleAge)...thisYear
    }

    /// Pulls a year into range, for values that predate the pickers or arrive from an import.
    static func clampBirthYear(_ year: Int) -> Int {
        min(max(year, validBirthYears.lowerBound), validBirthYears.upperBound)
    }

    static func age(forBirthYear year: Int, on date: Date = Date()) -> Int {
        Calendar.current.component(.year, from: date) - year
    }

    static func isTeen(birthYear: Int) -> Bool {
        let a = age(forBirthYear: birthYear)
        return a < teenThreshold && a >= minAdvisedAge
    }

    static func isUnderAdvisedAge(birthYear: Int) -> Bool {
        age(forBirthYear: birthYear) < minAdvisedAge
    }

    /// A gentle, non-blocking note shown when a birth year suggests very young users.
    static func gentleGateMessage(birthYear: Int) -> String? {
        if isUnderAdvisedAge(birthYear: birthYear) {
            return "Astera is built for ages 9 and up. If that's not you yet, talk to a trusted adult about cycles. They're better than any app for the early years."
        }
        return nil
    }

    /// Whether to filter TTC (and future fertility tools) out of cycle-mode pickers.
    static func hideFertilityContent(birthYear: Int) -> Bool {
        let a = age(forBirthYear: birthYear)
        return a < teenThreshold
    }

    /// Whether to hard-hide sex-related logging chips (painful sex, sex, protected sex)
    /// AND the corresponding settings toggle. Always true for under-16s; for 16+ users
    /// the chips remain hidden by default and can be revealed via the in-settings toggle.
    static func hideSexualContent(birthYear: Int) -> Bool {
        age(forBirthYear: birthYear) < sexualContentThreshold
    }

    /// Forces age-gated settings back to safe defaults if the user's birth year now puts
    /// them below the relevant threshold. Call this whenever birthYear changes (profile edit,
    /// onboarding) and as a safety net on app launch. The premise: consent doesn't carry
    /// across an age change. If they were 17 and turned on sexual activity, then changed
    /// their birth year to make themselves 15, the toggle should go back to off.
    static func reconcileAgeGatedSettings(birthYear: Int, defaults: UserDefaults = .standard) {
        if hideSexualContent(birthYear: birthYear) {
            defaults.set(false, forKey: AppStorageKey.showSexualActivity.rawValue)
        }
    }
}

extension UserProfile {
    var ageNow: Int { AgeMode.age(forBirthYear: birthYear) }
    var isTeen: Bool { AgeMode.isTeen(birthYear: birthYear) }
    var hideFertilityContent: Bool { AgeMode.hideFertilityContent(birthYear: birthYear) }
}
