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
    ///   - calendar, health, notifications: stub the system's answer for that permission. Omit to
    ///     use the real system, which on a simulator means the dialog nobody can tap.
    @discardableResult
    func launchApp(
        tab: Tab = .today,
        mode: Mode = .regular,
        birthYear: Int? = nil,
        cycles: Int? = nil,
        openSheet: Sheet? = nil,
        calendar: CalendarPermission? = nil,
        health: HealthPermission? = nil,
        notifications: NotificationPermission? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["ASTERA_FORCE_HOME"] = "1"
        app.launchEnvironment["ASTERA_INITIAL_TAB"] = tab.rawValue
        app.launchEnvironment["ASTERA_SEED_MODE"] = mode.rawValue
        if let birthYear { app.launchEnvironment["ASTERA_SEED_BIRTH_YEAR"] = String(birthYear) }
        if let cycles { app.launchEnvironment["ASTERA_SEED_CYCLES"] = String(cycles) }
        if let openSheet { app.launchEnvironment["ASTERA_OPEN_SHEET"] = openSheet.rawValue }
        if let calendar { app.launchEnvironment["ASTERA_PERMISSION_CALENDAR"] = calendar.rawValue }
        if let health { app.launchEnvironment["ASTERA_PERMISSION_HEALTH"] = health.rawValue }
        if let notifications { app.launchEnvironment["ASTERA_PERMISSION_NOTIFICATIONS"] = notifications.rawValue }
        app.launch()
        return app
    }

    // MARK: - Permission stubs
    //
    // These mirror `DebugPermissions` in the app. A raw value the app does not understand trips
    // an assertion there rather than falling back to the real system, so a typo in a test cannot
    // quietly turn into a test that passes for the wrong reason.

    enum CalendarPermission: String {
        case granted, writeOnly, denied, restricted, notRequested
    }

    enum HealthPermission: String {
        case granted, denied, unavailable
    }

    enum NotificationPermission: String {
        case authorized, provisional, denied, notDetermined
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

    // MARK: - Reaching and tapping things reliably
    //
    // These live on the base class rather than on one suite because every screen worth testing is
    // a scrolling list of controls, and each of the traps below cost an hour the first time. A
    // suite that does not inherit them will rediscover them.

    /// Scrolls until the element is wholly inside the viewport, above the tab bar.
    ///
    /// `scrollTo` stops as soon as `isHittable`, which is true when a sliver of a tall row shows,
    /// and a tap then lands under the tab bar. Finishing the job with `swipeUp()` was worse: a
    /// swipe moves most of a screen, so nudging a row nine points flung it four hundred points off
    /// the top. Only a drag of a measured distance can move content by the amount actually needed.
    func bringFullyOnScreen(_ element: XCUIElement, in app: XCUIApplication) {
        let scrollView = app.scrollViews.firstMatch
        scrollView.scrollTo(element)

        let safeBottom = app.frame.height * 0.82
        for _ in 0..<4 {
            let overhang = element.frame.maxY - safeBottom
            guard overhang > 1 else { return }
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -overhang - 8)))
            waitForFrameToSettle(element)
        }
    }

    /// Scrolls the element into view and taps it, failing if it could not be reached.
    ///
    /// `XCUIElement.tap()` on an off-screen element does not fail. It taps the element's frame
    /// centre, wherever that happens to be, so a test that misses reports the app as broken.
    func tapReliably(
        _ element: XCUIElement,
        _ what: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        element.requireExistence(what, file: file, line: line)
        bringFullyOnScreen(element, in: app)
        XCTAssertTrue(element.isHittable, "\(what) exists but could not be scrolled into view", file: file, line: line)
        element.tap()
    }

    /// Flips a toggle by tapping the switch, not the row.
    ///
    /// A SwiftUI `Toggle` publishes one accessibility element spanning the whole row, so the centre
    /// `tap()` aims at is over the descriptive text and does nothing. The switch is a separate,
    /// unlabelled element inside that row; finding it is indifferent to how tall the row wrapped.
    func flip(_ toggle: XCUIElement, in app: XCUIApplication) {
        bringFullyOnScreen(toggle, in: app)
        waitForFrameToSettle(toggle)
        switchControl(for: toggle, in: app).tap()
    }

    func switchControl(for row: XCUIElement, in app: XCUIApplication) -> XCUIElement {
        let bounds = row.frame
        let control = app.switches.allElementsBoundByIndex.first {
            $0.identifier.isEmpty
                && $0.frame.width < bounds.width
                && $0.frame.midY >= bounds.minY
                && $0.frame.midY <= bounds.maxY
        }
        return control ?? row
    }

    /// A coordinate tap resolves against the frame at the moment it is computed, and scrolling
    /// decelerates, so a frame read mid-glide sends the tap somewhere else.
    func waitForFrameToSettle(_ element: XCUIElement, attempts: Int = 10) {
        var previous = element.frame
        for _ in 0..<attempts {
            Thread.sleep(forTimeInterval: 0.15)
            let current = element.frame
            if current == previous { return }
            previous = current
        }
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

    /// Scrolls the receiver (a scroll view) until `element` is on screen, or until the content
    /// stops moving.
    ///
    /// The swipe cap used to be 12, which was enough for Settings on the simulator this was
    /// written against and not enough for the notification toggles on the shorter one CI picks.
    /// A cap tuned to one screen size is a test that passes on one machine, so the real exit
    /// condition is the content no longer moving; the cap is only a backstop against a view that
    /// scrolls forever.
    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 30) {
        var swipes = 0
        var lastFrame = element.frame
        while !element.isHittable && swipes < maxSwipes {
            swipeUp()
            swipes += 1
            let reached = element.frame
            // `frame` is zero until the element enters the accessibility tree, so only trust a
            // repeat reading once it has a real one.
            if reached == lastFrame && reached != .zero { break }
            lastFrame = reached
        }
    }
}
