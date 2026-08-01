import Foundation
import Testing
@testable import Astera

/// UI tests cannot import the app module, so `AsteraUITestCase.Mode` repeats the cycle modes by
/// raw value. That copy is exactly the kind of duplication that rots silently: add a mode, and
/// `CycleModeUITests` keeps passing while never launching it.
///
/// This test is the tripwire. If it fails, add the new mode to `AsteraUITestCase.Mode` and bump
/// the count here.
@Suite("Cycle mode coverage")
struct CycleModeCoverageTests {

    /// Kept in sync by hand with `AsteraUITestCase.Mode.allCases`.
    static let modesCoveredByUITests: Set<String> = [
        "regular", "irregular", "pcos", "endometriosis", "iud", "hormonalBC",
        "perimenopause", "surgicalMenopause", "pregnant", "postLoss",
        "ttc", "postpartum", "trackingOnT", "notSure",
    ]

    @Test("Every CycleMode is exercised by the end-to-end suite")
    func everyModeIsCovered() {
        let actual = Set(CycleMode.allCases.map(\.rawValue))
        let missing = actual.subtracting(Self.modesCoveredByUITests)
        let stale = Self.modesCoveredByUITests.subtracting(actual)

        #expect(missing.isEmpty, "CycleModes with no end-to-end coverage: \(missing.sorted())")
        #expect(stale.isEmpty, "AsteraUITestCase.Mode lists modes that no longer exist: \(stale.sorted())")
    }

    @Test("Every mode has a display name that is not just its raw value")
    func everyModeIsPresentable() {
        for mode in CycleMode.allCases {
            #expect(!mode.displayName.isEmpty, "\(mode.rawValue) has no display name")
            #expect(mode.displayName != mode.rawValue, "\(mode.rawValue) shows its raw value to users")
        }
    }

    /// `allChoices` is ordered by hand, so it cannot be derived from `allCases`. A fifteenth mode
    /// added to the enum without picker copy would otherwise be invisible in both screens that
    /// offer the choice, with no failure anywhere.
    @Test("Every mode is offered in the picker, exactly once, with copy")
    func everyModeIsOffered() {
        let offered = CycleMode.allChoices.map(\.value)

        let missing = Set(CycleMode.allCases).subtracting(offered).map(\.rawValue).sorted()
        #expect(Set(offered) == Set(CycleMode.allCases), "Modes missing picker copy: \(missing)")
        #expect(offered.count == Set(offered).count, "A mode is offered more than once")

        for choice in CycleMode.allChoices {
            #expect(!choice.title.isEmpty, "\(choice.value.rawValue) has no picker title")
            #expect(!choice.subtitle.isEmpty, "\(choice.value.rawValue) has no picker subtitle")
            #expect(choice.title != choice.subtitle, "\(choice.value.rawValue) repeats itself")
        }
    }

    /// The age gate is the only thing that removes an option, and it removes exactly one.
    @Test("Hiding fertility content drops trying-to-conceive and nothing else")
    func fertilityGateDropsOnlyTTC() {
        let shown = CycleMode.choices(hidingFertilityContent: false).map(\.value)
        let gated = CycleMode.choices(hidingFertilityContent: true).map(\.value)

        #expect(Set(shown).subtracting(gated) == [.ttc])
        #expect(gated.contains(.ttc) == false, "Under-18s must not be offered a fertility mode")
    }
}

/// Onboarding and Settings ask the same four questions. They read one list each now; these check
/// the lists themselves are whole, since a missing option is silent in both screens at once.
@Suite("Profile picker copy")
struct ProfileChoiceTests {

    @Test("Every profile enum offers all of its cases")
    func everyCaseIsOffered() {
        #expect(Set(Pronouns.choices.map(\.value)) == Set(Pronouns.allCases))
        #expect(Set(Salutation.choices.map(\.value)) == Set(Salutation.allCases))
        #expect(Set(RelationshipStructure.choices.map(\.value)) == Set(RelationshipStructure.allCases))
    }

    @Test("Every option says something, and says two different things")
    func everyOptionHasCopy() {
        func check<T>(_ choices: [ProfileChoice<T>], _ name: String) {
            for choice in choices {
                #expect(!choice.title.isEmpty, "\(name) has an option with no title")
                #expect(!choice.subtitle.isEmpty, "\(name) option \"\(choice.title)\" has no subtitle")
                #expect(choice.title != choice.subtitle, "\(name) option \"\(choice.title)\" repeats itself")
            }
        }
        check(Pronouns.choices, "Pronouns")
        check(Salutation.choices, "Salutation")
        check(RelationshipStructure.choices, "RelationshipStructure")
        check(CycleMode.allChoices, "CycleMode")
    }
}
