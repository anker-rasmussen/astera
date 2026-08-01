import Foundation

/// Outbound legal links. Apple requires functional links to both of these on any screen that
/// offers an auto-renewing subscription (Guideline 3.1.2(c)), and the same two URLs appear in
/// App Store Connect metadata. Keep these in sync with `appstore/listing.md`.
enum AsteraLinks {
    /// Served from `docs/` in the repo via GitHub Pages. Same URL as the Privacy Policy field in
    /// App Store Connect.
    static let privacyPolicy = URL(string: "https://anker-rasmussen.github.io/astera/privacy/")!

    /// Apple's standard Terms of Use (EULA). We use the standard terms rather than a custom EULA,
    /// so the App Store Connect EULA field stays at its default and this link goes in the App
    /// Description instead.
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}
