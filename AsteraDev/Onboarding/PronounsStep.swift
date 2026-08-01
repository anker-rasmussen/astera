import SwiftUI

struct PronounsStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    private var canContinue: Bool {
        draft.pronouns != .custom || !draft.customPronouns.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        OnboardingScaffold(
            title: Pronouns.question,
            subtitle: "We'll only use what you pick. Nothing assumed.",
            currentStep: .pronouns,
            canContinue: canContinue,
            onBack: onBack,
            onSkip: onSkip,
            onContinue: onContinue
        ) {
            HairlineList {
                ForEach(Pronouns.choices) { option in
                    HairlineRow(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: draft.pronouns == option.value,
                        identifier: option.accessibilityID,
                        action: { draft.pronouns = option.value }
                    )
                    Hairline()
                }

                if draft.pronouns == .custom {
                    HStack {
                        TextField("Your words", text: $draft.customPronouns)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
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
