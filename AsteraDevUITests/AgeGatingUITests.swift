import XCTest

/// End-to-end cover for the age gates in `AgeMode` (App Store Guideline 5.1.4, and the claims the
/// privacy policy makes about minors).
///
/// Three thresholds: a gentle note under 9, sexual-activity logging hidden under 16, fertility
/// content hidden under 18. `review-notes.md` states these to App Review, so they are promises.
final class AgeGatingUITests: AsteraUITestCase {

    private let sexualToggle = "settings.log.sexualActivity"

    // MARK: - The under-16 gate on sexual activity

    func testUnderSixteensCannotSeeTheSexualActivityToggle() {
        launchApp(tab: .settings, birthYear: Age.underSexualThreshold)
        app.staticTexts["WHAT YOU LOG"].requireExistence("the logging preferences section")
        app.switches[sexualToggle].requireAbsence("the sexual activity toggle, for an under-16")
    }

    func testSixteenAndOverCanSeeTheSexualActivityToggle() {
        launchApp(tab: .settings, birthYear: Age.teenAboveSexualThreshold)
        app.switches[sexualToggle].requireExistence("the sexual activity toggle, for a 17 year old")
    }

    func testAdultsCanSeeTheSexualActivityToggle() {
        launchApp(tab: .settings, birthYear: Age.adult)
        app.switches[sexualToggle].requireExistence("the sexual activity toggle, for an adult")
    }

    /// The gate is on the chips themselves, not only on the settings toggle.
    ///
    /// Two subtleties, both of which made earlier versions of this test pass vacuously. Chips only
    /// enter the accessibility tree once scrolled into view, so absence has to be checked by
    /// scrolling the whole sheet. And "sex" and "protected sex" live in the lifestyle section,
    /// which is off by default, so that has to be turned on or their absence proves nothing about
    /// age. Only "painful sex" sits in the always-visible symptoms list.
    func testSexualActivityChipsAreHiddenFromUnderSixteensInTheLogSheet() {
        launchApp(tab: .settings, birthYear: Age.underSexualThreshold)
        enable(app, "settings.log.lifestyle")
        openLogSheetFromSettings(app)

        let reachable = allReachableChips(app)
        for chip in ["painful sex", "sex", "protected sex"] {
            XCTAssertFalse(
                reachable.contains(chip),
                "The \"\(chip)\" chip must not be reachable for an under-16"
            )
        }
    }

    /// The same three chips, for an adult who opted in. Without this, the test above would pass
    /// even if the chips had been deleted from the app entirely.
    func testAdultsWhoOptInDoSeeTheSexualActivityChips() {
        launchApp(tab: .settings, birthYear: Age.adult)
        enable(app, "settings.log.lifestyle")
        enable(app, sexualToggle)
        openLogSheetFromSettings(app)

        let reachable = allReachableChips(app)
        for chip in ["painful sex", "sex", "protected sex"] {
            XCTAssertTrue(
                reachable.contains(chip),
                "An adult who opted in should be able to reach the \"\(chip)\" chip"
            )
        }
    }

    // MARK: - Consent does not survive an age change

    /// `AgeMode.reconcileAgeGatedSettings` says consent doesn't carry across an age change: an
    /// adult who enables sexual-activity logging and then sets a birth year making them 15 should
    /// lose it, and it must not come back when they set the year forward again.
    func testTurningBackTheBirthYearRevokesSexualActivityConsent() {
        launchApp(tab: .settings, birthYear: Age.adult)

        let toggle = app.switches[sexualToggle].requireExistence("the sexual activity toggle")
        flip(toggle, "the sexual activity toggle")
        XCTAssertTrue(toggle.isOn, "The sexual activity toggle should be on after flipping it")

        setBirthYear(to: Age.underSexualThreshold)
        app.switches[sexualToggle].requireAbsence("the toggle, now that the user reads as 15")

        // Back to an adult year. The control returns; the consent must not.
        setBirthYear(to: Age.adult)
        let restored = app.switches[sexualToggle].requireExistence("the toggle, for an adult again")
        XCTAssertFalse(restored.isOn, "Consent must not survive the trip below the age gate")
    }

    // MARK: - Helpers

    private func setBirthYear(to year: Int) {
        tap(app.buttons["settings.profile.birthYear"], "the Born row")

        // `adjust(toPickerWheelValue:)` is the whole interaction now. The field this replaced
        // needed a long press, a Select All from the edit menu and a retype, because typing into
        // a pre-filled field appends rather than replaces.
        app.pickerWheels.firstMatch
            .requireExistence("the birth year wheel")
            .adjust(toPickerWheelValue: String(year))

        tap(app.buttons["profileEdit.save"], "the Save button")
    }

    /// Every chip label reachable by scrolling the sheet to the bottom.
    ///
    /// One pass, collecting as it goes, rather than one full scroll per chip being looked for:
    /// three sequential searches cost about three times as long and told us the same thing. Stops
    /// as soon as two consecutive swipes reveal nothing new, so a short sheet is cheap.
    private func allReachableChips(_ app: XCUIApplication, maxSwipes: Int = 12) -> Set<String> {
        var seen = Set(app.buttons.allElementsBoundByIndex.map(\.label))
        var barrenSwipes = 0

        for _ in 0..<maxSwipes where barrenSwipes < 2 {
            app.swipeUp()
            let now = Set(app.buttons.allElementsBoundByIndex.map(\.label))
            barrenSwipes = now.subtracting(seen).isEmpty ? barrenSwipes + 1 : 0
            seen.formUnion(now)
        }
        return seen
    }

    private func enable(_ app: XCUIApplication, _ identifier: String) {
        let toggle = app.switches[identifier].requireExistence("the \(identifier) toggle")
        if !toggle.isOn { flip(toggle, "the \(identifier) toggle") }
        XCTAssertTrue(toggle.isOn, "\(identifier) should be on")
    }

    private func openLogSheetFromSettings(_ app: XCUIApplication) {
        app.tabBars.buttons["Today"].requireExistence("the Today tab").tap()
        let logButton = app.buttons["Log today"]
        if logButton.waitForExistence(timeout: 5) {
            logButton.tap()
        } else {
            app.buttons["Log your first day"].requireExistence("a way into the log sheet").tap()
        }
        app.staticTexts["FLOW"].requireExistence("the log sheet")
    }
}
