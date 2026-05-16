import SwiftUI

struct PronounsStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    private let options: [(Pronouns, String, String)] = [
        (.sheHer, "she / her", "She is on day 14 of her cycle."),
        (.heHim, "he / him", "He is on day 14 of his cycle."),
        (.theyThem, "they / them", "They are on day 14 of their cycle."),
        (.custom, "something else", "Tell us what fits.")
    ]

    private var canContinue: Bool {
        draft.pronouns != .custom || !draft.customPronouns.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        OnboardingScaffold(
            title: "What words should we use?",
            subtitle: "We'll only use these. Never assumed.",
            currentStep: .pronouns,
            canContinue: canContinue,
            onBack: onBack,
            onSkip: onSkip,
            onContinue: onContinue
        ) {
            HairlineList {
                ForEach(Array(options.enumerated()), id: \.element.0) { _, option in
                    HairlineRow(
                        title: option.1,
                        subtitle: option.2,
                        isSelected: draft.pronouns == option.0,
                        action: { draft.pronouns = option.0 }
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
