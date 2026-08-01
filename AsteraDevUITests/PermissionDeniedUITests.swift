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

    /// Scrolls the named control into view, which the accessibility tree only populates on
    /// approach, and refuses to hand back something that cannot be tapped.
    ///
    /// That last part is load-bearing. `XCUIElement.tap()` on an off-screen element does not fail,
    /// it taps the element's frame centre, which lands on whatever happens to be there. The first
    /// version of these tests did exactly that and reported the toggle as broken.
    @discardableResult
    func settingsControl(_ app: XCUIApplication, _ identifier: String, _ what: String) -> XCUIElement {
        let control = settingsElement(app, identifier, what)
        XCTAssertTrue(control.isHittable, "\(what) exists but could not be scrolled into view")
        return control
    }

    /// The same lookup without the hittability requirement, for a control that is deliberately
    /// disabled and so can never be hittable.
    @discardableResult
    func settingsElement(_ app: XCUIApplication, _ identifier: String, _ what: String) -> XCUIElement {
        // Ask for the switch first: a Toggle's identifier is also carried by wrapper elements
        // that are never hittable, and a query by type gets the control rather than the wrapper.
        let byType = app.switches[identifier]
        let control = byType.exists ? byType : app.descendants(matching: .any)[identifier]
        control.requireExistence(what)
        app.scrollViews.firstMatch.scrollTo(control)
        return control
    }

    /// The point of the guideline. A refused permission is allowed to cost you that feature and
    /// nothing else, so the tracker itself has to still be there.
    func assertTrackingStillWorks(_ app: XCUIApplication, after refusal: String) {
        app.tabBars.buttons["Today"].requireExistence("the Today tab").tap()
        // `buttons[...]`, not `descendants(matching: .any)[...]`: the broad query walks the whole
        // tree and matches on identifier or label depending on element type, which is both slower
        // and vaguer than asking for the control we mean.
        app.buttons["Log today"]
            .requireExistence("the log button after \(refusal), because refusing costs that feature and no other")
        XCTAssertEqual(app.state, .runningForeground, "App left the foreground after \(refusal)")
    }

    func assertToggle(_ toggle: XCUIElement, isOn expected: Bool, _ what: String) {
        XCTAssertEqual(
            toggle.value as? String,
            expected ? "1" : "0",
            "\(what) should be \(expected ? "on" : "off")"
        )
    }
}

// MARK: - Calendar

final class CalendarPermissionUITests: PermissionUITestCase {

    func testRefusingCalendarLeavesTheToggleOffAndSaysHowToChangeIt() {
        let app = launchApp(tab: .settings, calendar: .denied)
        let toggle = settingsControl(app, "settings.calendar.toggle", "the calendar toggle")

        flip(toggle, in: app)

        app.descendants(matching: .any)["settings.calendar.denied"]
            .requireExistence("the recovery text naming Settings → Astera → Calendars")
        assertToggle(toggle, isOn: false, "The calendar toggle after a refusal")
        assertTrackingStillWorks(app, after: "refusing Calendar")
    }

    /// Parental controls, not a choice. Same dead end for the user, so it has to reach the same
    /// recovery text rather than silently doing nothing.
    func testRestrictedCalendarIsHandledLikeARefusal() {
        let app = launchApp(tab: .settings, calendar: .restricted)
        let toggle = settingsControl(app, "settings.calendar.toggle", "the calendar toggle")

        flip(toggle, in: app)

        app.descendants(matching: .any)["settings.calendar.denied"]
            .requireExistence("the recovery text when Calendar is restricted")
        assertToggle(toggle, isOn: false, "The calendar toggle when restricted")
        assertTrackingStillWorks(app, after: "a restricted Calendar")
    }

    /// The positive case. Without it, a toggle broken for every input would pass the two above.
    func testGrantingCalendarTurnsTheToggleOnWithNoError() {
        let app = launchApp(tab: .settings, calendar: .granted)
        let toggle = settingsControl(app, "settings.calendar.toggle", "the calendar toggle")

        flip(toggle, in: app)

        assertToggle(toggle, isOn: true, "The calendar toggle after being granted")
        app.descendants(matching: .any)["settings.calendar.denied"]
            .requireAbsence("the recovery text, since access was granted")
    }

    /// iOS 17 can grant write-only access. Astera only writes, so that is enough, and treating it
    /// as a refusal would nag a user who already said yes.
    func testWriteOnlyCalendarAccessIsEnough() {
        let app = launchApp(tab: .settings, calendar: .writeOnly)
        let toggle = settingsControl(app, "settings.calendar.toggle", "the calendar toggle")

        flip(toggle, in: app)

        assertToggle(toggle, isOn: true, "The calendar toggle with write-only access")
        app.descendants(matching: .any)["settings.calendar.denied"]
            .requireAbsence("the recovery text, since write-only is all Astera needs")
    }
}

// MARK: - Apple Health

final class HealthPermissionUITests: PermissionUITestCase {

    func testRefusingHealthLeavesTheToggleOffAndSaysHowToChangeIt() {
        let app = launchApp(tab: .settings, health: .denied)
        let toggle = settingsControl(app, "settings.health.toggle", "the Apple Health toggle")

        flip(toggle, in: app)

        app.descendants(matching: .any)["settings.health.denied"]
            .requireExistence("the recovery text naming the Health app")
        assertToggle(toggle, isOn: false, "The Apple Health toggle after a refusal")
        assertTrackingStillWorks(app, after: "refusing Apple Health")
    }

    func testGrantingHealthTurnsTheToggleOnWithNoError() {
        let app = launchApp(tab: .settings, health: .granted)
        let toggle = settingsControl(app, "settings.health.toggle", "the Apple Health toggle")

        flip(toggle, in: app)

        assertToggle(toggle, isOn: true, "The Apple Health toggle after being granted")
        app.descendants(matching: .any)["settings.health.denied"]
            .requireAbsence("the recovery text, since access was granted")
    }

    /// Not a refusal: a device with no Health support at all. Offering a toggle that cannot work,
    /// or an import that can never find anything, would be a dead end rather than an explanation.
    func testWhereHealthIsUnavailableTheToggleIsDisabledAndTheImportIsHidden() {
        let app = launchApp(tab: .settings, health: .unavailable)
        let toggle = settingsElement(app, "settings.health.toggle", "the Apple Health toggle")

        XCTAssertFalse(toggle.isEnabled, "The toggle should be disabled where Health is unavailable")

        let copy = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        XCTAssertTrue(
            copy.contains("Apple Health isn't available on this device"),
            "The subtitle should explain why the toggle is disabled"
        )

        app.descendants(matching: .any)["settings.health.import"]
            .requireAbsence("the import button, which cannot work without Apple Health")
        assertTrackingStillWorks(app, after: "finding Apple Health unavailable")
    }

    // MARK: - Importing history

    /// A refusal and an empty Apple Health are different situations with different fixes, and
    /// Astera used to conflate them: a refused import reported "Apple Health doesn't have any
    /// menstrual flow yet", sending the user off to add data they already had.
    func testRefusingTheImportSaysItWasRefusedRatherThanEmpty() {
        let app = launchApp(tab: .settings, health: .denied)

        settingsControl(app, "settings.health.import", "the import button").tap()

        app.descendants(matching: .any)["settings.health.importDenied"]
            .requireExistence("the text saying access was refused")

        let copy = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        XCTAssertFalse(
            copy.contains("doesn't have any menstrual flow yet"),
            "A refusal must not be reported as Apple Health being empty"
        )
        assertTrackingStillWorks(app, after: "refusing the Apple Health import")
    }

    /// The other half of that pair. With access granted and nothing in Apple Health on a fresh
    /// simulator, the empty message is the correct one and the refusal message is wrong.
    func testAnEmptyAppleHealthSaysItIsEmptyRatherThanRefused() {
        let app = launchApp(tab: .settings, health: .granted)

        settingsControl(app, "settings.health.import", "the import button").tap()

        app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS %@", "doesn't have any menstrual flow yet"))
            .firstMatch
            .requireExistence("the empty-Apple-Health message")
        app.descendants(matching: .any)["settings.health.importDenied"]
            .requireAbsence("the refusal text, since access was granted")
    }
}

// MARK: - Notifications

final class NotificationPermissionUITests: PermissionUITestCase {

    func testRefusingNotificationsLeavesTheToggleOffAndSaysHowToChangeIt() {
        let app = launchApp(tab: .settings, notifications: .denied)
        let toggle = settingsControl(app, "settings.notifications.threeDays", "the three-days-out reminder toggle")

        flip(toggle, in: app)

        app.descendants(matching: .any)["settings.notifications.denied"]
            .requireExistence("the recovery text naming Settings → Astera → Notifications")
        assertToggle(toggle, isOn: false, "The reminder toggle after a refusal")
        assertTrackingStillWorks(app, after: "refusing notifications")
    }

    func testGrantingNotificationsTurnsTheToggleOnWithNoError() {
        let app = launchApp(tab: .settings, notifications: .authorized)
        let toggle = settingsControl(app, "settings.notifications.today", "the around-today reminder toggle")

        flip(toggle, in: app)

        assertToggle(toggle, isOn: true, "The reminder toggle after being granted")
        app.descendants(matching: .any)["settings.notifications.denied"]
            .requireAbsence("the recovery text, since notifications were allowed")
    }

    /// Provisional authorisation delivers quietly to the notification centre without a prompt.
    /// It is a yes, and treating it as a refusal would turn off reminders that do get delivered.
    func testProvisionalAuthorisationCountsAsGranted() {
        let app = launchApp(tab: .settings, notifications: .provisional)
        let toggle = settingsControl(app, "settings.notifications.today", "the around-today reminder toggle")

        flip(toggle, in: app)

        assertToggle(toggle, isOn: true, "The reminder toggle with provisional authorisation")
        app.descendants(matching: .any)["settings.notifications.denied"]
            .requireAbsence("the recovery text, since provisional delivery works")
    }

    /// Documents current behaviour rather than endorsing it. Dismissing the system prompt without
    /// choosing leaves the status `notDetermined`, and Astera shows the same copy as an outright
    /// refusal: "System notifications are turned off for Astera." Nothing is broken, but the
    /// sentence is not true yet, and the fix it recommends (a trip to the Settings app) is not the
    /// one that would work (tapping the toggle again).
    func testDismissingThePromptLeavesTheToggleOffAndTheAppUsable() {
        let app = launchApp(tab: .settings, notifications: .notDetermined)
        let toggle = settingsControl(app, "settings.notifications.threeDays", "the three-days-out reminder toggle")

        flip(toggle, in: app)

        assertToggle(toggle, isOn: false, "The reminder toggle after the prompt was dismissed")
        assertTrackingStillWorks(app, after: "dismissing the notification prompt")
    }
}
