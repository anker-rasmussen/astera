import SwiftUI

struct PrivacyStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    @State private var attempting = false
    @State private var attemptFailed = false

    private var biometry: AppLockService.BiometryKind { AppLockService.availableBiometry }

    private var lockOptionLabel: String { biometry.lockToggleLabel }

    private var lockSubtitle: String {
        switch biometry {
        case .faceID, .touchID, .opticID:
            return "Astera will ask for \(biometry.humanName), or your phone's passcode, every time you open it. Even when someone else has your phone in their hand."
        case .passcodeOnly:
            return "Astera will ask for your phone's passcode every time you open it. Even when someone else has your phone in their hand."
        case .unavailable:
            return "Set a passcode on your phone first, then come back and turn this on from Settings."
        }
    }

    var body: some View {
        OnboardingScaffold(
            title: "A lock for the app?",
            subtitle: "Optional. Astera works fine without it. If you turn it on, only you can open the app, even when someone else has your unlocked phone in their hand.",
            currentStep: .privacy,
            onBack: onBack,
            onSkip: onSkip,
            onContinue: onContinue
        ) {
            HairlineList {
                HairlineRow(
                    title: lockOptionLabel,
                    subtitle: lockSubtitle,
                    isSelected: draft.useAppLock,
                    action: attemptEnableLock
                )
                Hairline()

                HairlineRow(
                    title: "No lock for now",
                    subtitle: "The default. You can turn it on from Settings any time.",
                    isSelected: !draft.useAppLock,
                    action: { draft.useAppLock = false; attemptFailed = false }
                )
                Hairline()

                if attemptFailed {
                    Text("That didn't go through. You can try again, skip this for now, or set a passcode on your phone first.")
                        .font(.asteraSerifItalic(13))
                        .foregroundStyle(AsteraColor.accent)
                        .padding(.top, AsteraSpacing.sm)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func attemptEnableLock() {
        guard biometry != .unavailable else {
            attemptFailed = true
            return
        }
        guard !attempting else { return }
        attempting = true
        attemptFailed = false
        Task { @MainActor in
            let ok = await AppLockService.authenticate(
                reason: "Confirm with \(biometry.humanName) to turn on the lock."
            )
            attempting = false
            if ok {
                draft.useAppLock = true
            } else {
                draft.useAppLock = false
                attemptFailed = true
            }
        }
    }
}
