import XCTest

/// End-to-end cover for the two controls the privacy policy leans on.
///
/// The policy does not merely offer export and delete, it cites them as the mechanism by which
/// Astera satisfies GDPR: "your right to access is the Export button. Your right to erasure is
/// the Delete button." `PrivacyPolicyTests` asserts the policy says that. This asserts it is true.
final class DataRightsUITests: AsteraUITestCase {

    // MARK: - Right to data portability

    func testExportProducesAShareableFile() {
        launchApp(tab: .settings, cycles: 3)

        tap(app.buttons["settings.data.export"], "the export row")

        // The export sheet only presents once the PDF has been built and written to disk, so
        // its appearance is the proof the file exists.
        app.staticTexts["YOUR EXPORT · READY"]
            .requireExistence("the export sheet, meaning the PDF was written")
        app.buttons["Share or save the file"]
            .requireExistence("a way to get the file off the device")
    }

    /// The export screen must not contradict the privacy policy about what the file is. The
    /// policy calls the PDF the user's right to data portability; this screen used to call the
    /// same file "a plain-text JSON".
    func testExportScreenDescribesThePdfTheUserActuallyGets() {
        launchApp(tab: .settings, cycles: 3)
        tap(app.buttons["settings.data.export"], "the export row")
        app.staticTexts["YOUR EXPORT · READY"].requireExistence("the export sheet")

        let copy = app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
        XCTAssertTrue(copy.contains("PDF"), "The export screen should say the file is a PDF")
        XCTAssertFalse(copy.contains("JSON"), "The export is a PDF, not JSON")
    }

    /// Export must not require any data. A user who deletes everything and then exports should
    /// get an empty document, not a hang or a crash.
    func testExportWorksWithNothingLogged() {
        launchApp(tab: .settings, cycles: 0)

        tap(app.buttons["settings.data.export"], "the export row")

        app.staticTexts["YOUR EXPORT · READY"]
            .requireExistence("the export sheet, even with nothing logged")
        XCTAssertEqual(app.state, .runningForeground, "Export crashed with an empty database")
    }

    // MARK: - Right to erasure

    /// Destructive and irreversible, so it must be confirmed rather than fired by one tap.
    func testDeleteAsksBeforeItErases() {
        launchApp(tab: .settings, cycles: 3)

        tap(app.buttons["settings.data.delete"], "the delete row")

        app.buttons["Yes, delete everything"]
            .requireExistence("the destructive confirmation")

        // Nothing may have happened yet: opening the dialog is not consent.
        app.staticTexts["Astera."]
            .requireAbsence("the welcome screen, which would mean one tap had already erased")

        // Dismiss without confirming. The dialog's cancel button is drawn by the system and is
        // not in the accessibility tree, so back out by tapping away from it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()

        app.staticTexts["ASTERA · SETTINGS"]
            .requireExistence("Settings, because the delete was dismissed")
        app.staticTexts["Astera."]
            .requireAbsence("the welcome screen, which would mean it erased anyway")
    }

    /// `EraseService` clears `hasCompletedOnboarding` along with the store, so a successful
    /// erasure returns the app to its first-run state. That is the observable proof the settings
    /// went too, not just the cycles.
    func testDeleteEverythingReturnsTheAppToFirstRun() {
        launchApp(tab: .settings, cycles: 3)

        // Confirm there is something to lose first, or the assertion afterwards proves nothing.
        app.tabBars.buttons["Today"].tap()
        app.staticTexts["No cycle logged yet."]
            .requireAbsence("the empty state before deleting")

        app.tabBars.buttons["Settings"].tap()
        tap(app.buttons["settings.data.delete"], "the delete row")
        app.buttons["Yes, delete everything"]
            .requireExistence("the destructive confirmation")
            .tap()

        app.staticTexts["Astera."]
            .requireExistence("the welcome screen, because everything including settings was erased")
    }

    /// Erasure has to outlive the process: clearing a view is not clearing a store. Relaunching
    /// without the seed hook means anything on screen came from disk.
    func testDeletedDataDoesNotComeBackOnRelaunch() {
        launchApp(tab: .settings, cycles: 3)

        tap(app.buttons["settings.data.delete"], "the delete row")
        app.buttons["Yes, delete everything"]
            .requireExistence("the destructive confirmation")
            .tap()
        app.staticTexts["Astera."].requireExistence("the welcome screen after erasing")

        let relaunched = XCUIApplication()
        relaunched.launch()

        relaunched.staticTexts["Astera."]
            .requireExistence("the welcome screen again, meaning nothing survived on disk")
    }
}
