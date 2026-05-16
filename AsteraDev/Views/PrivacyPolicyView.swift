import SwiftUI

struct PrivacyPolicyView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Done", action: onDismiss)
                    .buttonStyle(AsteraGhostButtonStyle())
                Spacer()
                EmptyView()
            }
            .asteraEditorialMargins()
            .padding(.top, AsteraSpacing.md)

            Hairline().asteraEditorialMargins().padding(.top, AsteraSpacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: AsteraSpacing.lg) {
                    VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
                        CapsLabel(text: "Astera · privacy")
                        Text("The whole promise.")
                            .font(.asteraSerif(34, weight: .medium))
                            .foregroundStyle(AsteraColor.ink)
                        Text("Plain English. Under 600 words. Last updated \(PrivacyPolicy.lastUpdated).")
                            .font(.asteraSerifItalic(14))
                            .foregroundStyle(AsteraColor.iron)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Hairline()

                    VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                        ForEach(paragraphs, id: \.self) { paragraph in
                            paragraphView(paragraph)
                        }
                    }
                }
                .asteraEditorialMargins()
                .padding(.top, AsteraSpacing.lg)
                .padding(.bottom, AsteraSpacing.xxl)
            }
        }
        .asteraScreen()
    }

    private var paragraphs: [String] {
        PrivacyPolicy.body.components(separatedBy: "\n\n").filter { !$0.isEmpty }
    }

    @ViewBuilder
    private func paragraphView(_ paragraph: String) -> some View {
        let lines = paragraph.components(separatedBy: "\n")
        if let first = lines.first, lines.count == 1, looksLikeHeading(first) {
            Text(first)
                .font(.asteraSerif(20, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
                .padding(.top, AsteraSpacing.sm)
        } else {
            Text(paragraph)
                .font(.asteraSerif(15, weight: .regular))
                .foregroundStyle(AsteraColor.ink.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func looksLikeHeading(_ line: String) -> Bool {
        // Short, no trailing punctuation: treat as a section heading.
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.count < 50 && !trimmed.hasSuffix(".") && !trimmed.hasSuffix(",")
    }
}
