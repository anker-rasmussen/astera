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
        static let fallback = Document(
            version: "1.1",
            updated: "May 2026",
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
        var result = ""
        var rest = Substring(self)

        while let openBracket = rest.firstIndex(of: "[") {
            guard let closeBracket = rest[openBracket...].firstIndex(of: "]"),
                  rest.index(after: closeBracket) < rest.endIndex,
                  rest[rest.index(after: closeBracket)] == "(",
                  let closeParen = rest[closeBracket...].firstIndex(of: ")")
            else {
                // Not a link: keep the bracket and carry on past it.
                result += rest[..<rest.index(after: openBracket)]
                rest = rest[rest.index(after: openBracket)...]
                continue
            }

            result += rest[..<openBracket]
            result += rest[rest.index(after: openBracket)..<closeBracket]
            rest = rest[rest.index(after: closeParen)...]
        }

        return result + rest
    }
}
