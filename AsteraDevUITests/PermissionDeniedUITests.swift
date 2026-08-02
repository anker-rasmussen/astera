import XCTest

/// End-to-end cover for what Astera does when a system permission is refused (Guideline 5.1.1).
///
/// The guideline is not satisfied by showing an error. It asks that the app keep working without
/// the permission, so every test here ends by going back to Today and checking the app is still
/// usable. An app that wedged on a refused permission would pass a test that only looked for the
/// error text.
///
/// Each permission gets a positive case as well as a negative one. Without the positive case, a
/// toggle that never turns on for any reason would satisfy the whole file.
///
/// The stub these drive is `DebugPermissions`, whose doc comment sets out what is faked (the value
/// the request returns) and what still runs for real (the branch Settings takes on it, the
/// `@AppStorage` write-back, the recovery copy). The system dialog itself is out of reach of any
/// test, which is the reason for the seam.
///
/// **Split into three classes on purpose.** XCUITest hands a whole class to one simulator clone,
/// so three classes shard across workers where one would not. Same reasoning as `CycleModeUITests`.
class PermissionUITestCase: AsteraUITestCase {

    /// Finds a Settings control by identifier, scrolls it into view, and insists it can be
    /// reached.
    ///
    /// That insistence is load-bearing: `tap()` on an off-screen element does not fail, it taps
    /// whatever is at those coordinates. The first version of these tests did exactly that and
    /// reported the toggle as broken.
    @discardableResult
    func settingsControl(_ identifier: String, _ what: String,
                         file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let control = settingsElement(identifier, what, file: file, line: line)
        XCTAssertTrue(
            control.isHittable,
            "Expected \(what) to be reachable, but it could not be scrolled into view",
            file: file, line: line
        )
        return control
    }

    /// The same lookup without the reachability requirement, for a control that is deliberately
    /// disabled and so can never be hittable.
    @discardableResult
    func settingsElement(_ identifier: String, _ what: String,
                         file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        // Ask for the switch first: a Toggle's identifier is also carried by wrapper elements that
        // are never hittable, and querying by type gets the control rather than the wrapper.
        let byType = app.switches[identifier]
        let control = byType.exists ? byType : app.descendants(matching: .any)[identifier]
        control.requireExistence(what, file: file, line: line)
        scrollIntoView(control)
        return control
    }

    /// The point of the guideline. A refused permission may cost you that one feature and nothing
    /// else, so the tracker itself has to still be there afterwards.
    func assertTrackingStillWorks(after refusal: String,
                                  file: StaticString = #filePath, line: UInt = #line) {
        app.tabBars.buttons["Today"].requireExistence("the Today tab", file: file, line: line).tap()
        // `buttons[...]` rather than `descendants(matching: .any)[...]`: the broad query walks the
        // whole tree and matches on identifier or label depending on element type, which is slower
        // and vaguer than asking for the control we mean.
        app.buttons["Log today"].requireExistence(
            "the log button after \(refusal), because refusing costs that feature and no other",
            file: file, line: line
        )
        XCTAssertEqual(app.state, .runningForeground, "App left the foreground after \(refusal)",
                       file: file, line: line)
    }

    /// Asserts the recovery text is showing, or is not.
    func assertRecoveryText(_ identifier: String, isShowing expected: Bool, _ why: String,
                            file: StaticString = #filePath, line: UInt = #line) {
        let text = app.descendants(matching: .any)[identifier]
        if expected {
            text.requireExistence(why, file: file, line: line)
        } else {
            text.requireAbsence(why, file: file, line: line)
        }
    }
}

// MARK: - Calendar

final class CalendarPermissionUITests: PermissionUITestCase {

    func testRefusingCalendarLeavesTheToggleOffAndSaysHowToChangeIt() {
        launchApp(tab: .settings, calendar: .denied)
        let toggle = settingsControl("settings.calendar.toggle", "the calendar toggle")

        flip(toggle)

        assertRecoveryText("settings.calendar.denied", isShowing: true, "the recovery text naming Settings → Astera → Calendars")
        XCTAssertFalse(toggle.isOn, "The calendar toggle after a refusal should be off")
        assertTrackingStillWorks(after: "refusing Calendar")
    }

    /// Parental controls, not a choice. Same dead end for the user, so it has to reach the same
    /// recovery text rather than silently doing nothing.
    func testRestrictedCalendarIsHandledLikeARefusal() {
        launchApp(tab: .settings, calendar: .restricted)
        let toggle = settingsControl("settings.calendar.toggle", "the calendar toggle")

        flip(toggle)

        assertRecoveryText("settings.calendar.denied", isShowing: true, "the recovery text when Calendar is restricted")
        XCTAssertFalse(toggle.isOn, "The calendar toggle when restricted should be off")
        assertTrackingStillWorks(after: "a restricted Calendar")
    }

    /// The positive case. Without it, a toggle broken for every input would pass the two above.
    func testGrantingCalendarTurnsTheToggleOnWithNoError() {
        launchApp(tab: .settings, calendar: .granted)
        let toggle = settingsControl("settings.calendar.toggle", "the calendar toggle")

        flip(toggle)

        XCTAssertTrue(toggle.isOn, "The calendar toggle after being granted should be on")
        assertRecoveryText("settings.calendar.denied", isShowing: false, "the recovery text, since access was granted")
    }

    /// iOS 17 can grant write-only access. Astera only writes, so that is enough, and treating it
    /// as a refusal would nag a user who already said yes.
    func testWriteOnlyCalendarAccessIsEnough() {
        launchApp(tab: .settings, calendar: .writeOnly)
        let toggle = settingsControl("settings.calendar.toggle", "the calendar toggle")

        flip(toggle)

        XCTAssertTrue(toggle.isOn, "The calendar toggle with write-only access should be on")
        assertRecoveryText("settings.calendar.denied", isShowing: false, "the recovery text, since write-only is all Astera needs")
    }
}

// MARK: - Apple Health

final class HealthPermissionUITests: PermissionUITestCase {

    func testRefusingHealthLeavesTheToggleOffAndSaysHowToChangeIt() {
        launchApp(tab: .settings, health: .denied)
        let toggle = settingsControl("settings.health.toggle", "the Apple Health toggle")

        flip(toggle)

        assertRecoveryText("settings.health.denied", isShowing: true, "the recovery text naming the Health app")
        XCTAssertFalse(toggle.isOn, "The Apple Health toggle after a refusal should be off")
        assertTrackingStillWorks(after: "refusing Apple Health")
    }

    func testGrantingHealthTurnsTheToggleOnWithNoError() {
        launchApp(tab: .settings, health: .granted)
        let toggle = settingsControl("settings.health.toggle", "the Apple Health toggle")

        flip(toggle)

        XCTAssertTrue(toggle.isOn, "The Apple Health toggle after being granted should be on")
        assertRecoveryText("settings.health.denied", isShowing: false, "the recovery text, since access was granted")
    }

    /// Not a refusal: a device with no Health support at all. Offering a toggle that cannot work,
    /// or an import that can never find anything, would be a dead end rather than an explanation.
    func testWhereHealthIsUnavailableTheToggleIsDisabledAndTheImportIsHidden() {
        launchApp(tab: .settings, health: .unavailable)
        let toggle = settingsElement("settings.health.toggle", "the Apple Health toggle")

        XCTAssertFalse(toggle.isEnabled, "The toggle should be disabled where Health is unavailable")

        let copy = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        XCTAssertTrue(
            copy.contains("Apple Health isn't available on this device"),
            "The subtitle should explain why the toggle is disabled"
        )

        assertRecoveryText("settings.health.import", isShowing: false, "the import button, which cannot work without Apple Health")
        assertTrackingStillWorks(after: "finding Apple Health unavailable")
    }

    // MARK: - Importing history

    /// A refusal and an empty Apple Health are different situations with different fixes, and
    /// Astera used to conflate them: a refused import reported "Apple Health doesn't have any
    /// menstrual flow yet", sending the user off to add data they already had.
    func testRefusingTheImportSaysItWasRefusedRatherThanEmpty() {
        launchApp(tab: .settings, health: .denied)

        settingsControl("settings.health.import", "the import button").tap()

        assertRecoveryText("settings.health.importDenied", isShowing: true, "the text saying access was refused")

        let copy = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        XCTAssertFalse(
            copy.contains("doesn't have any menstrual flow yet"),
            "A refusal must not be reported as Apple Health being empty"
        )
        assertTrackingStillWorks(after: "refusing the Apple Health import")
    }

    /// The other half of that pair. With access granted and nothing in Apple Health on a fresh
    /// simulator, the empty message is the correct one and the refusal message is wrong.
    func testAnEmptyAppleHealthSaysItIsEmptyRatherThanRefused() {
        launchApp(tab: .settings, health: .granted)

        settingsControl("settings.health.import", "the import button").tap()

        app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS %@", "doesn't have any menstrual flow yet"))
            .firstMatch
            .requireExistence("the empty-Apple-Health message")
        assertRecoveryText("settings.health.importDenied", isShowing: false, "the refusal text, since access was granted")
    }
}

// MARK: - Notifications

final class NotificationPermissionUITests: PermissionUITestCase {

    func testRefusingNotificationsLeavesTheToggleOffAndSaysHowToChangeIt() {
        launchApp(tab: .settings, notifications: .denied)
        let toggle = settingsControl("settings.notifications.threeDays", "the three-days-out reminder toggle")

        flip(toggle)

        assertRecoveryText("settings.notifications.denied", isShowing: true, "the recovery text naming Settings → Astera → Notifications")
        XCTAssertFalse(toggle.isOn, "The reminder toggle after a refusal should be off")
        assertTrackingStillWorks(after: "refusing notifications")
    }

    func testGrantingNotificationsTurnsTheToggleOnWithNoError() {
        launchApp(tab: .settings, notifications: .authorized)
        let toggle = settingsControl("settings.notifications.today", "the around-today reminder toggle")

        flip(toggle)

        XCTAssertTrue(toggle.isOn, "The reminder toggle after being granted should be on")
        assertRecoveryText("settings.notifications.denied", isShowing: false, "the recovery text, since notifications were allowed")
    }

    /// Provisional authorisation delivers quietly to the notification centre without a prompt.
    /// It is a yes, and treating it as a refusal would turn off reminders that do get delivered.
    func testProvisionalAuthorisationCountsAsGranted() {
        launchApp(tab: .settings, notifications: .provisional)
        let toggle = settingsControl("settings.notifications.today", "the around-today reminder toggle")

        flip(toggle)

        XCTAssertTrue(toggle.isOn, "The reminder toggle with provisional authorisation should be on")
        assertRecoveryText("settings.notifications.denied", isShowing: false, "the recovery text, since provisional delivery works")
    }

    /// Documents current behaviour rather than endorsing it. Dismissing the system prompt without
    /// choosing leaves the status `notDetermined`, and Astera shows the same copy as an outright
    /// refusal: "System notifications are turned off for Astera." Nothing is broken, but the
    /// sentence is not true yet, and the fix it recommends (a trip to the Settings app) is not the
    /// one that would work (tapping the toggle again).
    func testDismissingThePromptLeavesTheToggleOffAndTheAppUsable() {
        launchApp(tab: .settings, notifications: .notDetermined)
        let toggle = settingsControl("settings.notifications.threeDays", "the three-days-out reminder toggle")

        flip(toggle)

        XCTAssertFalse(toggle.isOn, "The reminder toggle after the prompt was dismissed should be off")
        assertTrackingStillWorks(after: "dismissing the notification prompt")
    }
}
