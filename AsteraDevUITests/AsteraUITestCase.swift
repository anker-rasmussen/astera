import XCTest

/// Shared harness for the end-to-end tests.
///
/// The app already ships a DEBUG-only launch hook (`RootView.seedDemoIfNeeded`): setting
/// `ASTERA_FORCE_HOME=1` skips onboarding and seeds three cycles of demo data, and
/// `ASTERA_INITIAL_TAB` picks the starting tab. Every test here uses that rather than
/// driving the onboarding flow, so a failure points at the screen under test.
class AsteraUITestCase: XCTestCase {

    /// Generous but bounded. Anything slower than this on a warm simulator is a real problem.
    static let timeout: TimeInterval = 20

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Launches the app past onboarding, on the given tab, with demo data seeded.
    @discardableResult
    func launchApp(tab: Tab = .today, seedMode: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["ASTERA_FORCE_HOME"] = "1"
        app.launchEnvironment["ASTERA_INITIAL_TAB"] = tab.rawValue
        if let seedMode {
            app.launchEnvironment["ASTERA_SEED_MODE"] = seedMode
        }
        app.launch()
        return app
    }

    enum Tab: String {
        case today
        case history
        case settings
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

    /// Scrolls the receiver (a scroll view) until `element` is on screen, or gives up.
    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 12) {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            swipeUp()
            swipes += 1
        }
    }
}
