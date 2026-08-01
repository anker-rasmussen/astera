import XCTest

/// End-to-end cover for the four profile pickers in Settings.
///
/// These screens ask the same questions onboarding asks, and until now nothing checked them. That
/// mattered when the option lists moved onto the model: both screens changed how `ForEach` derives
/// identity, and a picker that silently stops responding to taps looks exactly like a picker that
/// works until you try to change something.
///
/// So these tests do the round trip rather than reading the screen: open the picker, choose a
/// different option, save, and check the Settings row underneath now says the new thing. Anything
/// less would pass on a picker whose Save button does nothing.
///
/// Options are selected by identifier (`choice.<rawValue>`), never by their copy, so rewording a
/// subtitle does not break a test and nobody learns to avoid rewording.
final class ProfileEditUITests: AsteraUITestCase {

    // All three go through `tapReliably` on the base class rather than `.tap()`. The cycle mode
    // picker is fourteen options deep inside a sheet, and on a short screen the later ones need
    // real scrolling to reach. A tap that misses does not fail, it just does nothing, so the
    // difference between these helpers and a bare tap is whether a failure is legible.

    private func openPicker(_ app: XCUIApplication, _ field: String) {
        tapReliably(app.buttons["settings.profile.\(field)"], "the \(field) row in Settings", in: app)
    }

    private func choose(_ app: XCUIApplication, _ rawValue: String) {
        tapReliably(app.buttons["choice.\(rawValue)"], "the \(rawValue) option", in: app)
    }

    private func save(_ app: XCUIApplication) {
        tapReliably(app.buttons["profileEdit.save"], "the Save button", in: app)
    }

    /// Reads the value shown on a Settings row. The row's label is "label, value", so the value is
    /// what comes after the label.
    private func rowValue(_ app: XCUIApplication, _ field: String) -> String {
        app.buttons["settings.profile.\(field)"]
            .requireExistence("the \(field) row")
            .label
    }

    // MARK: - The round trip

    func testChangingCycleModeSticks() {
        let app = launchApp(tab: .settings, mode: .regular)

        XCTAssertTrue(
            rowValue(app, "cycleMode").localizedCaseInsensitiveContains("regular"),
            "Expected the seeded mode first. Row said: \(rowValue(app, "cycleMode"))"
        )

        openPicker(app, "cycleMode")
        choose(app, "perimenopause")
        save(app)

        XCTAssertTrue(
            rowValue(app, "cycleMode").localizedCaseInsensitiveContains("perimenopause"),
            "The mode did not save. Row said: \(rowValue(app, "cycleMode"))"
        )
    }

    func testChangingPronounsSticks() {
        let app = launchApp(tab: .settings)

        openPicker(app, "pronouns")
        choose(app, "heHim")
        save(app)

        XCTAssertTrue(
            rowValue(app, "pronouns").localizedCaseInsensitiveContains("he"),
            "Pronouns did not save. Row said: \(rowValue(app, "pronouns"))"
        )
    }

    func testChangingTheGreetingSticks() {
        let app = launchApp(tab: .settings)

        openPicker(app, "salutation")
        choose(app, "person")
        save(app)

        XCTAssertTrue(
            rowValue(app, "salutation").contains("Hey there."),
            "The greeting did not save. Row said: \(rowValue(app, "salutation"))"
        )
    }

    func testChangingWhoYouTrackWithSticks() {
        let app = launchApp(tab: .settings)

        openPicker(app, "relationship")
        choose(app, "polyamorous")
        save(app)

        XCTAssertTrue(
            rowValue(app, "relationship").localizedCaseInsensitiveContains("polyamorous"),
            "The relationship structure did not save. Row said: \(rowValue(app, "relationship"))"
        )
    }

    // MARK: - Cancel

    /// Save and Cancel both close the sheet, so a Cancel that quietly saved would look identical
    /// from the Settings screen unless the value is checked.
    func testCancellingKeepsTheOldValue() {
        let app = launchApp(tab: .settings, mode: .regular)
        let before = rowValue(app, "cycleMode")

        openPicker(app, "cycleMode")
        choose(app, "endometriosis")
        tapReliably(app.buttons["profileEdit.cancel"], "the Cancel button", in: app)

        XCTAssertEqual(rowValue(app, "cycleMode"), before, "Cancel saved the change anyway")
    }

    // MARK: - The age gate reaches the picker

    /// `AgeMode` hides fertility content from under-18s. The picker is where that has to hold: the
    /// negative case alone would pass on a picker that showed nothing at all, so the same launch
    /// checks a neighbouring option is still there.
    func testUnderEighteensAreNotOfferedTryingToConceive() {
        let app = launchApp(tab: .settings, birthYear: Age.underSexualThreshold)

        openPicker(app, "cycleMode")

        app.buttons["choice.regular"].requireExistence("an ordinary option, so absence means something")
        app.buttons["choice.ttc"].requireAbsence("the trying-to-conceive option, for an under-18")
    }

    func testAdultsAreOfferedTryingToConceive() {
        let app = launchApp(tab: .settings, birthYear: Age.adult)

        openPicker(app, "cycleMode")

        let ttc = app.buttons["choice.ttc"].requireExistence("trying to conceive, for an adult")
        bringFullyOnScreen(ttc, in: app)
        XCTAssertTrue(ttc.isHittable, "An adult should be able to select it, not just see it")
    }
}
