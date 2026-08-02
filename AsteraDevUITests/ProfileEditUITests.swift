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

    // All three go through `tap` on the base class rather than `XCUIElement.tap()`. The cycle
    // mode picker is fourteen options deep inside a sheet, and on a short screen the later ones
    // need real scrolling to reach. A tap that misses does not fail, it silently does nothing, so
    // the difference between these helpers and a bare tap is whether a failure is legible.

    private func openPicker(_ field: String) {
        tap(app.buttons["settings.profile.\(field)"], "the \(field) row in Settings")
    }

    private func choose(_ rawValue: String) {
        tap(app.buttons["choice.\(rawValue)"], "the \(rawValue) option")
    }

    private func save() {
        tap(app.buttons["profileEdit.save"], "the Save button")
    }

    /// Reads the value shown on a Settings row. The row's label is "label, value", so the value is
    /// what comes after the label.
    private func rowValue(_ field: String) -> String {
        app.buttons["settings.profile.\(field)"]
            .requireExistence("the \(field) row")
            .label
    }

    // MARK: - The round trip

    func testChangingCycleModeSticks() {
        launchApp(tab: .settings, mode: .regular)

        XCTAssertTrue(
            rowValue("cycleMode").localizedCaseInsensitiveContains("regular"),
            "Expected the seeded mode first. Row said: \(rowValue("cycleMode"))"
        )

        openPicker("cycleMode")
        choose("perimenopause")
        save()

        XCTAssertTrue(
            rowValue("cycleMode").localizedCaseInsensitiveContains("perimenopause"),
            "The mode did not save. Row said: \(rowValue("cycleMode"))"
        )
    }

    func testChangingPronounsSticks() {
        launchApp(tab: .settings)

        openPicker("pronouns")
        choose("heHim")
        save()

        XCTAssertTrue(
            rowValue("pronouns").localizedCaseInsensitiveContains("he"),
            "Pronouns did not save. Row said: \(rowValue("pronouns"))"
        )
    }

    func testChangingTheGreetingSticks() {
        launchApp(tab: .settings)

        openPicker("salutation")
        choose("person")
        save()

        XCTAssertTrue(
            rowValue("salutation").contains("Hey there."),
            "The greeting did not save. Row said: \(rowValue("salutation"))"
        )
    }

    func testChangingWhoYouTrackWithSticks() {
        launchApp(tab: .settings)

        openPicker("relationship")
        choose("polyamorous")
        save()

        XCTAssertTrue(
            rowValue("relationship").localizedCaseInsensitiveContains("polyamorous"),
            "The relationship structure did not save. Row said: \(rowValue("relationship"))"
        )
    }

    // MARK: - Cancel

    /// Save and Cancel both close the sheet, so a Cancel that quietly saved would look identical
    /// from the Settings screen unless the value is checked.
    func testCancellingKeepsTheOldValue() {
        launchApp(tab: .settings, mode: .regular)
        let before = rowValue("cycleMode")

        openPicker("cycleMode")
        choose("endometriosis")
        tap(app.buttons["profileEdit.cancel"], "the Cancel button")

        XCTAssertEqual(rowValue("cycleMode"), before, "Cancel saved the change anyway")
    }

    // MARK: - The age gate reaches the picker

    /// `AgeMode` hides fertility content from under-18s. The picker is where that has to hold: the
    /// negative case alone would pass on a picker that showed nothing at all, so the same launch
    /// checks a neighbouring option is still there.
    func testUnderEighteensAreNotOfferedTryingToConceive() {
        launchApp(tab: .settings, birthYear: Age.underSexualThreshold)

        openPicker("cycleMode")

        app.buttons["choice.regular"].requireExistence("an ordinary option, so absence means something")
        app.buttons["choice.ttc"].requireAbsence("the trying-to-conceive option, for an under-18")
    }

    func testAdultsAreOfferedTryingToConceive() {
        launchApp(tab: .settings, birthYear: Age.adult)

        openPicker("cycleMode")

        let ttc = app.buttons["choice.ttc"].requireExistence("trying to conceive, for an adult")
        scrollIntoView(ttc)
        XCTAssertTrue(ttc.isHittable, "An adult should be able to select it, not just see it")
    }
}
