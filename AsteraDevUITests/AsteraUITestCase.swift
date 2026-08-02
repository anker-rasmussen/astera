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

    /// The app under test, set by `launchApp`. Held here so the helpers below can reach the scroll
    /// view and the screen bounds without every call site passing them back in.
    private(set) var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        app = nil
        super.tearDown()
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
        self.app = app
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
        self.app = app
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
    // Every screen worth testing is a scrolling list of controls, and each trap below cost real
    // time the first time it was hit. They live on the base class so no suite has to rediscover
    // them, and they all forward `file` and `line` so a failure points at the test rather than
    // at the helper.

    /// Scrolls the element into view and taps it, failing if it could not be reached.
    ///
    /// The reachability check is the point. `XCUIElement.tap()` on an off-screen element does not
    /// fail: it taps that element's frame centre, wherever that lands. A test that misses reports
    /// the app as broken, which is how two of these cost an afternoon.
    func tap(
        _ element: XCUIElement,
        _ what: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        element.requireExistence(what, file: file, line: line)
        scrollIntoView(element)
        XCTAssertTrue(
            element.isHittable,
            "Expected \(what) to be reachable, but it could not be scrolled into view",
            file: file,
            line: line
        )
        element.tap()
    }

    /// Flips a toggle by tapping the switch, not the row.
    ///
    /// A SwiftUI `Toggle` publishes one accessibility element spanning the whole row, so the centre
    /// that `tap()` aims at is over the descriptive text and nothing happens. The switch is a
    /// separate, unlabelled element inside that row, and finding it is indifferent to how tall the
    /// row wrapped or how far it scrolled.
    func flip(
        _ toggle: XCUIElement,
        _ what: String = "the toggle",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        toggle.requireExistence(what, file: file, line: line)
        scrollIntoView(toggle)
        XCTAssertTrue(
            toggle.isHittable,
            "Expected \(what) to be reachable, but it could not be scrolled into view",
            file: file,
            line: line
        )
        switchControl(within: toggle).tap()
    }

    /// Scrolls until the element is somewhere it can actually be tapped.
    ///
    /// Two passes. Coarse swipes get it on screen, in whichever direction it lies, because a test
    /// that scrolls down to a toggle and then reaches back up for a row near the top is ordinary.
    /// Then measured nudges put it clear of the status bar and the tab bar.
    ///
    /// The second pass is the one that matters, and only a short screen shows why. `isHittable`
    /// is true when any part of the element is on screen, including a part something else is
    /// drawing over. A swipe travels slightly more than a screen height, so on a 375x667 phone a
    /// 58pt row goes from `minY = 662`, a sliver above the tab bar, to `minY = -18`, a sliver
    /// under the status bar. Both report hittable; a tap at either lands on furniture. There is no
    /// swipe count that fixes that, which is why the sweep only has to get the element into the
    /// scroll view's neighbourhood and `settle` does the rest.
    ///
    /// Deliberately query-light. An earlier version polled `element.frame` in a settle loop inside
    /// a retry loop, and each of those reads is an accessibility query against the whole tree. It
    /// turned a twenty-second test into four minutes without ever failing, which is its own kind
    /// of broken. One `frame` read per swipe is affordable; ten per swipe is not.
    func scrollIntoView(_ element: XCUIElement) {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.exists else { return }

        if !element.isHittable {
            // Guess the direction, then correct it. A zero frame usually means the element is
            // further down and the accessibility tree has not realised it, but a row that
            // scrolled off the top gets derealised too and reads the same. Guessing wrong and
            // never recovering is how a test spends thirty swipes travelling away from its
            // target, so an exhausted sweep turns around and tries the other way.
            let frame = element.frame
            let liesBelow = frame == .zero || frame.minY >= 0
            if !sweep(scrollView, toward: element, down: liesBelow) {
                sweep(scrollView, toward: element, down: !liesBelow)
            }
        }

        settle(scrollView, so: element)
    }

    /// Swipes one way until the element is reachable or the content stops moving.
    ///
    /// The exit condition is the content, not a swipe count. A cap tuned to one screen is a test
    /// that passes on one machine: the same twelve swipes that clear Settings on a 17 Pro fall
    /// short of the notification toggles on the 375x667 screen CI picks. `limit` is only a
    /// backstop against a view that scrolls forever.
    @discardableResult
    private func sweep(
        _ scrollView: XCUIElement,
        toward element: XCUIElement,
        down: Bool,
        limit: Int = 30
    ) -> Bool {
        var lastFrame = element.frame
        for _ in 0..<limit {
            if element.isHittable { return true }
            down ? scrollView.swipeUp() : scrollView.swipeDown()
            let frame = element.frame
            // `frame` is zero until the element enters the accessibility tree, so a repeat
            // reading only means the content stopped once there is a real one to repeat.
            if frame == lastFrame && frame != .zero { break }
            lastFrame = frame
        }
        return element.isHittable
    }

    /// Nudges the content until the element sits clear of the status bar and the tab bar.
    ///
    /// Correcting in one direction only is not enough: the sweep can leave the element off either
    /// edge. A row taller than the gap between them gets its top aligned and nothing more, since
    /// there is nowhere to put it that clears both.
    ///
    /// The bounds are the furniture, not a fraction of the screen, and the difference is not
    /// cosmetic. An earlier version reserved the top 14%, which no phone's status bar occupies,
    /// so it decided perfectly visible rows in a sheet needed pushing down. Dragging down inside
    /// a sheet whose list is already at the top is the dismiss gesture, and two picker tests
    /// started saving the value they opened with.
    private func settle(_ scrollView: XCUIElement, so element: XCUIElement) {
        let top = app.frame.height * 0.09
        let tabBar = app.tabBars.firstMatch
        let tabBarTop = tabBar.exists ? tabBar.frame.minY : 0
        let bottom = tabBarTop > 0 ? tabBarTop : app.frame.height * 0.92

        for _ in 0..<3 {
            let frame = element.frame
            guard frame != .zero else { return }

            let tallerThanTheGap = frame.height > bottom - top
            let travel: CGFloat
            if frame.minY < top || (frame.maxY > bottom && tallerThanTheGap) {
                travel = top - frame.minY + 8
            } else if frame.maxY > bottom {
                travel = -(frame.maxY - bottom + 8)
            } else {
                return
            }

            // Below a scroll view's own pan slop the drag moves nothing, so asking for it costs
            // a press, a hold and an idle wait to end up exactly where we started.
            guard abs(travel) > 12 else { return }
            nudge(scrollView, by: travel)

            // Content at its end cannot give any more; further nudges would only rubber-band it.
            if element.frame == frame { return }
        }
    }

    /// Drags the content by a measured distance, with no momentum.
    ///
    /// A swipe would move most of a screen and overshoot. So would a flick: dragging after a
    /// 0.05s press is read as one, and the scroll view keeps travelling after the finger lifts,
    /// which is how a 267pt correction ended up throwing the row off the top instead. Pressing
    /// first, moving slowly, and holding at the end makes the distance asked for the distance
    /// travelled.
    private func nudge(_ scrollView: XCUIElement, by travel: CGFloat) {
        let height = app.frame.height
        let clamped = max(-height * 0.5, min(height * 0.5, travel))
        // Start from the half of the screen the drag is heading away from, so both ends stay
        // well inside the scroll view.
        let start = scrollView.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: clamped < 0 ? 0.7 : 0.3)
        )
        start.press(
            forDuration: 0.3,
            thenDragTo: start.withOffset(CGVector(dx: 0, dy: clamped)),
            withVelocity: .slow,
            thenHoldForDuration: 0.1
        )
    }

    /// The bare switch inside a labelled toggle row, or the row itself if there isn't one.
    ///
    /// Picks the nearest by centre rather than the first that overlaps. Settings stacks toggles
    /// directly on top of each other, and a row tall enough to wrap its explainer can span a
    /// neighbour's switch as well as its own. Taking the first overlap would then flip the wrong
    /// setting, and the test would fail describing the right one.
    func switchControl(within row: XCUIElement) -> XCUIElement {
        let bounds = row.frame
        let candidates = app.switches.allElementsBoundByIndex.filter {
            $0.identifier.isEmpty
                && $0.frame.width < bounds.width
                && $0.frame.midY >= bounds.minY
                && $0.frame.midY <= bounds.maxY
        }
        let nearest = candidates.min {
            abs($0.frame.midY - bounds.midY) < abs($1.frame.midY - bounds.midY)
        }
        return nearest ?? row
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
    /// A switch's state, which XCUITest reports as the string "0" or "1" in `value`.
    ///
    /// Worth a name: `XCTAssertFalse(toggle.isOn)` says what the test means, where
    /// `XCTAssertEqual(toggle.value as? String, "0")` says how the framework happens to spell it.
    var isOn: Bool { (value as? String) == "1" }

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
}
