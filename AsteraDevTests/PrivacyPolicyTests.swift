import Foundation
import Testing
@testable import Astera

/// The app, the published web page, and PRIVACY.md all come from one Markdown file. These tests
/// guard the app's half of that: that the file actually ships in the bundle and parses. The web
/// half is guarded by `python3 scripts/build_privacy.py --check` in CI.
@Suite("Privacy policy")
struct PrivacyPolicyTests {

    @Test("The canonical Markdown ships in the app bundle")
    func documentLoadsFromBundle() {
        // The fallback exists for safety, but shipping it would mean the reviewer and the user
        // see a stub instead of the policy. This asserts we are reading the real file.
        #expect(PrivacyPolicy.body != PrivacyPolicy.Document.fallback.body)
        #expect(PrivacyPolicy.body.count > 3000)
    }

    @Test("Version and date come from the source frontmatter")
    func metadataIsParsed() {
        #expect(PrivacyPolicy.version == "1.1")
        #expect(PrivacyPolicy.lastUpdated == "May 2026")
    }

    @Test("Headings keep their Markdown markers so the view need not guess")
    func headingsAreMarked() {
        #expect(PrivacyPolicy.body.hasPrefix("# Astera collects nothing."))
        #expect(PrivacyPolicy.body.contains("\n## Children and teens\n"))
    }

    @Test("Link syntax is flattened, never shown raw to the user")
    func linksAreFlattened() {
        #expect(!PrivacyPolicy.body.contains("]("))
        #expect(PrivacyPolicy.body.contains("apple.com/legal/privacy"))
        #expect(PrivacyPolicy.body.contains("privacy@rasmussen.engineering"))
    }

    @Test("Substantive claims the App Store listing depends on are present")
    func keyClaimsArePresent() {
        for claim in [
            "Sexual activity logging is hidden for users under 16.",
            "Data Not Collected",
            "We comply with Apple's HealthKit terms",
        ] {
            #expect(PrivacyPolicy.body.contains(claim), "Policy is missing: \(claim)")
        }
    }

    @Test("Link flattening handles brackets that are not links")
    func flatteningLeavesPlainBracketsAlone() {
        #expect("a [b] c".flatteningMarkdownLinks() == "a [b] c")
        #expect("see [here](https://x.test) now".flatteningMarkdownLinks() == "see here now")
        #expect("[a](1) and [b](2)".flatteningMarkdownLinks() == "a and b")
    }
}
