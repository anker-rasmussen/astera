import SwiftUI

struct LockedView: View {
    let onUnlock: () -> Void

    @State private var isAuthenticating = false
    @State private var lastAttemptFailed = false

    private var biometry: AppLockService.BiometryKind { AppLockService.availableBiometry }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            AsteraMark(size: 56)
                .padding(.bottom, AsteraSpacing.lg)

            Text("Astera.")
                .font(.asteraSerif(40, weight: .medium))
                .foregroundStyle(AsteraColor.ink)

            Text(lastAttemptFailed ? "Try again." : "Locked.")
                .font(.asteraSerifItalic(18))
                .foregroundStyle(AsteraColor.iron)
                .padding(.top, AsteraSpacing.xs)

            Spacer()

            VStack(spacing: AsteraSpacing.md) {
                Button(action: attempt) {
                    Text(unlockLabel)
                }
                .buttonStyle(AsteraPrimaryButtonStyle(isEnabled: !isAuthenticating))
                .disabled(isAuthenticating)

                Text("Your data stays where it should.")
                    .font(.asteraCaps(11))
                    .tracking(1.4)
                    .foregroundStyle(AsteraColor.iron)
            }
            .asteraEditorialMargins()
            .padding(.bottom, AsteraSpacing.xl)
        }
        .asteraScreen()
        .onAppear(perform: attempt)
    }

    private var unlockLabel: String {
        isAuthenticating ? "Unlocking…" : biometry.unlockLabel
    }

    private func attempt() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        Task { @MainActor in
            let ok = await AppLockService.authenticate(
                reason: "Astera uses \(biometry.humanName) so only you can see what you've logged."
            )
            isAuthenticating = false
            if ok {
                lastAttemptFailed = false
                onUnlock()
            } else {
                lastAttemptFailed = true
            }
        }
    }
}
