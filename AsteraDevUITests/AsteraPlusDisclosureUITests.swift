import XCTest

/// End-to-end cover for the disclosures App Review rejected v1.0 over (Guideline 3.1.2(c)).
///
/// Everything asserted here is something Apple asks for by name: the title, length, and price
/// of each product, honest renewal wording, and functional links to the privacy policy and the
/// Terms of Use. If one of these tests fails, the build is not submittable.
final class AsteraPlusDisclosureUITests: AsteraUITestCase {

    private func openAsteraPlus() -> XCUIApplication {
        let app = launchApp(tab: .settings)
        app.buttons["settings.asteraPlus"]
            .requireExistence("the Astera+ row in Settings")
            .tap()
        // The small print is the one block that renders regardless of whether StoreKit
        // products loaded, so it is the reliable "screen is up" signal.
        app.staticTexts["asteraPlus.smallPrint"].requireExistence("the Astera+ screen")
        return app
    }

    private func tierLabel(_ app: XCUIApplication, productID: String) -> String {
        let row = app.buttons["asteraPlus.tier.\(productID)"]
            .requireExistence("the tier row for product \(productID)")
        return row.label
    }

    // MARK: - Title, length, price

    func testMonthlyRowStatesTitleLengthPriceAndRenewal() {
        let app = openAsteraPlus()
        let label = tierLabel(app, productID: "000")

        XCTAssertTrue(label.localizedCaseInsensitiveContains("astera+ monthly"), "Missing title. Label was: \(label)")
        XCTAssertTrue(label.localizedCaseInsensitiveContains("a month"), "Missing subscription length. Label was: \(label)")
        XCTAssertTrue(label.contains("0.49"), "Missing price. Label was: \(label)")
        XCTAssertTrue(
            label.localizedCaseInsensitiveContains("renews automatically"),
            "Monthly must disclose auto-renewal. Label was: \(label)"
        )
    }

    func testYearlyRowStatesTitleLengthPriceAndRenewal() {
        let app = openAsteraPlus()
        let label = tierLabel(app, productID: "001")

        XCTAssertTrue(label.localizedCaseInsensitiveContains("astera+ yearly"), "Missing title. Label was: \(label)")
        XCTAssertTrue(label.localizedCaseInsensitiveContains("a year"), "Missing subscription length. Label was: \(label)")
        XCTAssertTrue(label.contains("4.99"), "Missing price. Label was: \(label)")
        XCTAssertTrue(
            label.localizedCaseInsensitiveContains("renews automatically"),
            "Yearly must disclose auto-renewal. Label was: \(label)"
        )
    }

    /// The highest-risk line in the whole screen. Product 002 is a non-consumable: claiming it
    /// renews would be its own rejection, so this asserts the negative explicitly.
    func testLifetimeRowNeverClaimsToRenew() {
        let app = openAsteraPlus()
        let label = tierLabel(app, productID: "002")

        XCTAssertTrue(label.localizedCaseInsensitiveContains("astera+ lifetime"), "Missing title. Label was: \(label)")
        XCTAssertFalse(
            label.localizedCaseInsensitiveContains("renews automatically"),
            "Lifetime is a non-consumable and must never claim to renew. Label was: \(label)"
        )
        XCTAssertTrue(
            label.localizedCaseInsensitiveContains("never renews"),
            "Lifetime should say plainly that it never renews. Label was: \(label)"
        )
    }

    // MARK: - The small print

    func testSmallPrintStatesTheRenewalTerms() {
        let app = openAsteraPlus()
        let smallPrint = app.staticTexts["asteraPlus.smallPrint"]
            .requireExistence("the small print block")
        let label = smallPrint.label

        for phrase in ["auto-renewing", "24 hours", "Apple ID", "one-time purchase"] {
            XCTAssertTrue(
                label.localizedCaseInsensitiveContains(phrase),
                "Small print is missing \"\(phrase)\". Label was: \(label)"
            )
        }
    }

    // MARK: - Functional links

    func testBothLegalLinksArePresentAndHittable() {
        let app = openAsteraPlus()

        for (identifier, what) in [
            ("asteraPlus.privacyLink", "the privacy policy link"),
            ("asteraPlus.termsLink", "the Terms of Use link"),
        ] {
            let link = app.descendants(matching: .any)[identifier]
            link.requireExistence(what)
            app.scrollViews.firstMatch.scrollTo(link)
            XCTAssertTrue(link.isHittable, "\(what) exists but can't be tapped")
        }
    }

    /// "Functional" is the word in the guideline, so this actually taps through to Safari.
    func testTermsLinkOpensInSafari() {
        let app = openAsteraPlus()
        let link = app.descendants(matching: .any)["asteraPlus.termsLink"]
        link.requireExistence("the Terms of Use link")
        app.scrollViews.firstMatch.scrollTo(link)
        link.tap()

        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(
            safari.wait(for: .runningForeground, timeout: AsteraUITestCase.timeout),
            "Tapping Terms of Use should open Safari"
        )
    }
}
