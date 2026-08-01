import Foundation

/// One row in a profile picker: the phrase the user taps, and the line of reassurance under it.
///
/// Every one of these choices is offered twice, once in onboarding and again in Settings when the
/// user changes their mind. Both screens used to carry their own copy of the list, and two of the
/// twenty-seven rows had already drifted apart:
///
///     Pronouns, "something else"     onboarding said "Tell us what fits."
///                                    Settings said   "Whatever fits."
///     Salutation, "use my own words" onboarding said "Type your own greeting."
///                                    Settings said   "Type the exact greeting you want."
///
/// Nobody decided that. It is what happens to a fact written down twice. The wording that shipped
/// in onboarding won, on the grounds that it is the copy every user reads.
struct ProfileChoice<Value: Hashable>: Identifiable {
    let value: Value
    /// Completes the question the screen asks, so it is lowercase unless it is a proper noun or,
    /// for greetings, the literal words Astera will say back.
    let title: String
    /// One line on what picking this actually changes. Never a restatement of the title.
    let subtitle: String
    /// How the Settings row names this choice once it is made.
    ///
    /// Usually the title again, but the row completes a different sentence: "Tracking with, just
    /// me" reads worse than "Tracking with, solo", and "We call you, something else" worse than
    /// "We call you, your own words". Those two exceptions were the reason Settings kept a whole
    /// second switch, most of which agreed with this list and quietly might not have.
    let summary: String

    var id: Value { value }

    init(_ value: Value, _ title: String, _ subtitle: String, summary: String? = nil) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
        self.summary = summary ?? title
    }
}

extension ProfileChoice where Value: RawRepresentable, Value.RawValue == String {
    /// Stable handle for the end-to-end tests, so a test selects an option by what it is rather
    /// than by matching its copy. Otherwise every wording change breaks a test, which teaches
    /// people to stop changing wording.
    var accessibilityID: String { "choice.\(value.rawValue)" }
}

extension Pronouns {
    static let choices: [ProfileChoice<Pronouns>] = [
        .init(.sheHer, "she / her", "She is on day 14 of her cycle."),
        .init(.heHim, "he / him", "He is on day 14 of his cycle."),
        .init(.theyThem, "they / them", "They are on day 14 of their cycle."),
        .init(.custom, "something else", "Tell us what fits.", summary: "your own words"),
    ]
}

extension Salutation {
    static let choices: [ProfileChoice<Salutation>] = [
        .init(.none, "Hello.", "Quiet, neutral, the default."),
        .init(.person, "Hey there.", "Warm, no assumptions."),
        .init(.woman, "Hey, lady.", "If that feels right."),
        .init(.girl, "Hey, girlie 🌸", "A little more familiar."),
        .init(.custom, "use my own words", "Type your own greeting."),
    ]
}

extension RelationshipStructure {
    static let choices: [ProfileChoice<RelationshipStructure>] = [
        .init(.single, "just me", "The simplest setup.", summary: "solo"),
        .init(.partneredTracking, "a partner who tracks too", "Partner sync is coming later, if you'd like it."),
        .init(.partneredNotTracking, "a partner who doesn't", "Nobody is going to bug them about anything."),
        .init(.polyamorous, "polyamorous", "Same options. No assumptions about structure."),
    ]
}

extension CycleMode {
    /// Every mode, in the order they are offered.
    ///
    /// Deliberately not derived from `allCases`: the order here is editorial, running from the
    /// commonplace to the harder situations, and it should not change because someone reorders
    /// the enum. `CycleModeCoverageTests` asserts the two stay in step.
    static let allChoices: [ProfileChoice<CycleMode>] = [
        .init(.regular, "regular cycles", "Usually within a few days of the same length."),
        .init(.irregular, "irregular cycles", "Length varies a lot, with no clear pattern."),
        .init(.pcos, "PCOS", "Ovulation prompts stay off unless you ask for them."),
        .init(.endometriosis, "endometriosis", "Pain logging up front, wider confidence bands, and no pretending to know more than we do."),
        .init(.iud, "have an IUD", "Lighter or absent bleeds are normal here, not a missed period."),
        .init(.hormonalBC, "on hormonal birth control", "Pill, patch, ring, implant, or injection. Withdrawal bleeds and absent bleeds are both normal."),
        .init(.perimenopause, "perimenopause", "Variable cycles are expected, not a tracking failure."),
        .init(.surgicalMenopause, "after surgical menopause or hysterectomy", "No cycle predictions. The rest of the app is still here for you."),
        .init(.pregnant, "pregnant", "We'll switch to a week-by-week view. Your cycle history stays right where it is."),
        .init(.postLoss, "after pregnancy loss", "Your history stays exactly as it was. Cycle reminders go quiet until you tell us you're ready."),
        .init(.ttc, "trying to conceive", "A fertility window with confidence bands. No countdown, no comparison."),
        .init(.postpartum, "postpartum", "Periods come back when they come back. No \"late\" alerts here."),
        .init(.trackingOnT, "tracking on T", "Cycle changes on T are real and varied. No bleed forecasts."),
        .init(.notSure, "not sure yet", "That's completely fine. You can change this any time, and nothing you log gets lost."),
    ]

    /// Takes the boolean rather than a `UserProfile`, because onboarding asks this question before
    /// a profile exists and has only a birth year to go on. `AgeMode` owns the rule itself.
    static func choices(hidingFertilityContent: Bool) -> [ProfileChoice<CycleMode>] {
        hidingFertilityContent ? allChoices.filter { $0.value != .ttc } : allChoices
    }
}

// MARK: - The question each picker asks

// Onboarding and Settings put the same question at the top of the same choice. The line beneath it
// differs by context (onboarding reassures a new user, Settings reassures someone changing their
// mind), so subtitles stay with their screens.

extension Pronouns { static let question = "What words should we use?" }
extension Salutation { static let question = "How should we greet you?" }
extension RelationshipStructure {
    static let question = "Who's in this with you?"
    /// The only one of the four where both screens say the same thing underneath, too.
    static let questionSubtitle = "Affects only optional partner features."
}
extension CycleMode { static let question = "Where are you right now?" }

// MARK: - Looking a choice back up

extension Pronouns {
    var summary: String { Self.choices.first { $0.value == self }?.summary ?? rawValue }
}
extension Salutation {
    var summary: String { Self.choices.first { $0.value == self }?.summary ?? rawValue }
}
extension RelationshipStructure {
    var summary: String { Self.choices.first { $0.value == self }?.summary ?? rawValue }
}
