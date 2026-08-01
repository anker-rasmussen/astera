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
}
