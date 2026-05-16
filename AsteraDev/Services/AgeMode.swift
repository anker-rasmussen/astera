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
}

extension UserProfile {
    var ageNow: Int { AgeMode.age(forBirthYear: birthYear) }
    var isTeen: Bool { AgeMode.isTeen(birthYear: birthYear) }
    var hideFertilityContent: Bool { AgeMode.hideFertilityContent(birthYear: birthYear) }
}
