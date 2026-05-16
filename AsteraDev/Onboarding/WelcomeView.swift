import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: AsteraSpacing.xl) {
                AsteraMark(size: 56)
                    .padding(.bottom, AsteraSpacing.sm)

                VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                    Text("Astera.")
                        .font(.asteraSerif(56, weight: .medium))
                        .foregroundStyle(AsteraColor.ink)

                    Text("A quieter way to know\nyour body.")
                        .font(.asteraSerif(28, weight: .regular))
                        .foregroundStyle(AsteraColor.ink.opacity(0.78))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Hairline()
                        .frame(width: 48)
                    Text("Honest predictions.\nYour data stays yours.\nNothing to sell.")
                        .font(.asteraSerifItalic(16))
                        .foregroundStyle(AsteraColor.iron)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, AsteraSpacing.sm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .asteraEditorialMargins()

            Spacer(minLength: 0)

            VStack(spacing: AsteraSpacing.md) {
                Button("Begin", action: onContinue)
                    .buttonStyle(AsteraPrimaryButtonStyle())
                CapsLabel(text: "Takes a minute · Skip anything")
            }
            .asteraEditorialMargins()
            .padding(.bottom, AsteraSpacing.xl)
        }
        .asteraScreen()
    }
}
