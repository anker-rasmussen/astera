import XCTest

/// Shared harness for the end-to-end tests.
///
/// Tests start from a seeded state rather than driving onboarding, so a failure points at the
/// screen under test. `DebugSeed` in the app reads these values from the launch environment and
/// is compiled out of release builds. `OnboardingUITests` is the exception: it deliberately skips
/// the seed so it can walk the real first-run flow.
class AsteraUITestCase: XCTestCase {

    /// Generous but bounded. Anything slower than this on a warm simulator is a real problem.
    static let timeout: TimeInterval = 20

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Launches past onboarding in the state the test needs.
    ///
    /// - Parameters:
    ///   - mode: any `CycleMode` raw value, e.g. `"perimenopause"`.
    ///   - birthYear: drives the age gates. Omit for an adult.
    ///   - cycles: number of seeded past cycles. `0` gives the empty first-run state.
    @discardableResult
    func launchApp(
        tab: Tab = .today,
        mode: Mode = .regular,
        birthYear: Int? = nil,
        cycles: Int? = nil,
        openSheet: Sheet? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["ASTERA_FORCE_HOME"] = "1"
        app.launchEnvironment["ASTERA_INITIAL_TAB"] = tab.rawValue
        app.launchEnvironment["ASTERA_SEED_MODE"] = mode.rawValue
        if let birthYear { app.launchEnvironment["ASTERA_SEED_BIRTH_YEAR"] = String(birthYear) }
        if let cycles { app.launchEnvironment["ASTERA_SEED_CYCLES"] = String(cycles) }
        if let openSheet { app.launchEnvironment["ASTERA_OPEN_SHEET"] = openSheet.rawValue }
        app.launch()
        return app
    }

    /// Launches with no seeding at all, at the first onboarding step.
    @discardableResult
    func launchFreshInstall() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    enum Tab: String {
        case today, history, settings
    }

    enum Sheet: String {
        case log, why
    }

    /// Mirrors `CycleMode`. UI tests cannot import the app module, so the raw values are repeated
    /// here; `HomeModeUITests.testEveryModeIsCovered` asserts this list stays complete.
    enum Mode: String, CaseIterable {
        case regular, irregular, pcos, endometriosis, iud, hormonalBC
        case perimenopause, surgicalMenopause, pregnant, postLoss
        case ttc, postpartum, trackingOnT, notSure
    }

    // MARK: - Birth years for the age gates

    /// `AgeMode` thresholds: gentle note under 9, sexual content hidden under 16, fertility
    /// content hidden under 18. Computed from the current year so they never expire.
    enum Age {
        private static var thisYear: Int { Calendar.current.component(.year, from: Date()) }
        static var adult: Int { thisYear - 30 }
        static var teenAboveSexualThreshold: Int { thisYear - 17 }
        static var underSexualThreshold: Int { thisYear - 15 }
        static var underAdvisedAge: Int { thisYear - 7 }
    }
}

extension XCUIElement {
    /// Waits for the element and fails the test with a useful message if it never appears.
    @discardableResult
    func requireExistence(
        _ what: String,
        timeout: TimeInterval = AsteraUITestCase.timeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            waitForExistence(timeout: timeout),
            "Expected \(what) to appear within \(Int(timeout))s",
            file: file,
            line: line
        )
        return self
    }

    /// Asserts the element never shows up. Used for the age gates, where the whole point is
    /// absence. Costs a short wait, so keep the timeout small.
    func requireAbsence(
        _ what: String,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            waitForExistence(timeout: timeout),
            "Expected \(what) NOT to be present",
            file: file,
            line: line
        )
    }

    /// Scrolls the receiver (a scroll view) until `element` is on screen, or gives up.
    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 12) {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            swipeUp()
            swipes += 1
        }
    }
}
