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
                        Text("Plain English. Version \(PrivacyPolicy.version), last updated \(PrivacyPolicy.lastUpdated).")
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
        // Headings are marked in the source Markdown, so there is nothing to infer.
        if let heading = headingText(paragraph) {
            Text(heading)
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

    private func headingText(_ paragraph: String) -> String? {
        for marker in ["## ", "# "] where paragraph.hasPrefix(marker) {
            return String(paragraph.dropFirst(marker.count))
        }
        return nil
    }
}
