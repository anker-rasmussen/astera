import XCTest

/// Proves the launch-environment hooks every other suite depends on.
///
/// If these fail, failures elsewhere are meaningless: a test asserting "the teen gate hides this
/// control" proves nothing if the birth year never reached the profile. Keep this suite first.
final class SeedHarnessUITests: AsteraUITestCase {

    func testSkipsOnboardingAndLandsOnHome() {
        let app = launchApp()
        app.staticTexts["TODAY"].requireExistence("the Today header, meaning onboarding was skipped")
    }

    func testInitialTabHookOpensSettings() {
        let app = launchApp(tab: .settings)
        app.staticTexts["ASTERA · SETTINGS"].requireExistence("the Settings header")
    }

    func testCycleSeedReachesTheDatabase() {
        let app = launchApp(cycles: 3)
        app.staticTexts["No cycle logged yet."]
            .requireAbsence("the empty state, because three cycles were seeded")
    }

    func testZeroCyclesGivesTheEmptyFirstRunState() {
        let app = launchApp(cycles: 0)
        app.staticTexts["No cycle logged yet."]
            .requireExistence("the empty state a first-run user sees")
    }

    /// The birth year has to survive into the persisted profile, not just the environment.
    func testBirthYearHookReachesTheProfile() {
        let year = Age.teenAboveSexualThreshold
        let app = launchApp(tab: .settings, birthYear: year)
        let born = app.buttons["settings.profile.birthYear"]
            .requireExistence("the Born row in Settings")
        XCTAssertTrue(
            born.label.contains(String(year)),
            "Born row should show the seeded birth year \(year). Label was: \(born.label)"
        )
    }

    /// The old hook understood six modes out of fourteen. This one is driven off the enum.
    func testModeHookAcceptsAModeTheOldSwitchDidNotKnow() {
        let app = launchApp(tab: .settings, mode: .trackingOnT)
        let row = app.buttons["settings.profile.cycleMode"]
            .requireExistence("the cycle mode row in Settings")
        XCTAssertTrue(
            row.label.localizedCaseInsensitiveContains("tracking on t"),
            "Seeded mode should be reflected in Settings. Label was: \(row.label)"
        )
    }
}
