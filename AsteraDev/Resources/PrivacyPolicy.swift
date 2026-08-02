import Foundation

/// The privacy policy, read from the one canonical source.
///
/// `PrivacyPolicy.md` ships in the app bundle, and `scripts/build_privacy.py` renders that same
/// file into the published web page and the repo's `PRIVACY.md`. Editing the Markdown is the only
/// way to change the policy: nothing here holds a second copy of the text, so the app and the URL
/// in App Store Connect cannot drift apart.
enum PrivacyPolicy {
    private static let document = Document.load()

    static var version: String { document.version }
    static var lastUpdated: String { document.updated }

    /// Paragraphs separated by blank lines. Headings keep their `#` / `##` prefix so the view can
    /// style them without guessing from length and punctuation.
    static var body: String { document.body }

    struct Document {
        let version: String
        let updated: String
        let body: String

        /// If the resource is ever missing, show a short pointer to the live policy rather than
        /// placeholder prose. `PrivacyPolicyTests` asserts the real document loads, so this is a
        /// belt-and-braces path rather than an expected one.
        ///
        /// It states no version on purpose. It used to carry a real-looking one, which went stale
        /// the moment the policy was bumped and would have had the app claim a version the live
        /// page had moved past. That is the exact drift this file exists to prevent, and a
        /// reviewer comparing the screen against the URL is who would find it. "unknown" is also
        /// what lets the tests tell a parsed document apart from this one.
        static let unknownVersion = "unknown"
        static let fallback = Document(
            version: unknownVersion,
            updated: unknownVersion,
            body: """
            # Astera collects nothing.

            The full policy is published at anker-rasmussen.github.io/astera/privacy and committed \
            to the public repository at github.com/anker-rasmussen/astera.
            """
        )

        static func load() -> Document {
            guard let url = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "md"),
                  let raw = try? String(contentsOf: url, encoding: .utf8) else {
                return fallback
            }
            return parse(raw)
        }

        static func parse(_ raw: String) -> Document {
            let parts = raw.components(separatedBy: "---\n")
            // ["", frontmatter, body...] for a well-formed document.
            guard parts.count >= 3 else { return fallback }

            var version = fallback.version
            var updated = fallback.updated
            for line in parts[1].split(separator: "\n") {
                let pair = line.split(separator: ":", maxSplits: 1).map {
                    $0.trimmingCharacters(in: .whitespaces)
                }
                guard pair.count == 2 else { continue }
                switch pair[0] {
                case "version": version = pair[1]
                case "updated": updated = pair[1]
                default: break
                }
            }

            let body = parts.dropFirst(2).joined(separator: "---\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .flatteningMarkdownLinks()

            return Document(version: version, updated: updated, body: body)
        }
    }
}

extension String {
    /// Turns `[label](url)` into `label`. The web build keeps the anchors; on the phone the link
    /// text already reads as the destination ("apple.com/legal/privacy"), so flattening loses
    /// nothing and keeps the in-app wording identical to the published page.
    func flatteningMarkdownLinks() -> String {
        // A regex literal, not a hand-walked index loop. The loop this replaced was twenty-odd
        // lines of `index(after:)` arithmetic to say what the pattern says outright, and it had
        // to special-case a bracket that turns out not to start a link. The pattern simply does
        // not match those, so they survive untouched with no branch to get wrong.
        //
        // `AttributedString(markdown:)` would be the other obvious answer, and it is the wrong
        // one here: it flattens the `#` and `##` prefixes too, and `PrivacyPolicyView` styles
        // headings from exactly those.
        replacing(/\[([^\]]*)\]\([^)]*\)/) { match in match.1 }
    }
}
