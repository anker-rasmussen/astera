import SwiftUI

struct SalutationStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    private var canContinue: Bool {
        draft.salutation != .custom || !draft.customGreeting.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        OnboardingScaffold(
            title: Salutation.question,
            subtitle: "Shows at the top of Home every time you open the app. If you skip, it's just \"Hello.\"",
            currentStep: .salutation,
            canContinue: canContinue,
            onBack: onBack,
            onSkip: onSkip,
            onContinue: onContinue
        ) {
            HairlineList {
                ForEach(Salutation.choices) { option in
                    HairlineRow(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: draft.salutation == option.value,
                        identifier: option.accessibilityID,
                        action: { draft.salutation = option.value }
                    )
                    Hairline()
                }

                if draft.salutation == .custom {
                    HStack {
                        TextField("e.g. \"Hey lovely.\"", text: $draft.customGreeting)
                            .textInputAutocapitalization(.sentences)
                            .autocorrectionDisabled(false)
                            .font(.asteraSerif(20, weight: .regular))
                            .foregroundStyle(AsteraColor.ink)
                            .tint(AsteraColor.accent)
                    }
                    .padding(.vertical, AsteraSpacing.md)
                    Hairline()
                }
            }
        }
    }
}
