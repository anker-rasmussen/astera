import SwiftUI

struct SalutationStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    /// (Tag, what we'll say at the top of Home, helper text shown in row)
    private let options: [(Salutation, String, String)] = [
        (.none, "Hello.", "Quiet, neutral, the default."),
        (.person, "Hey there.", "Warm, no assumptions."),
        (.woman, "Hey, lady.", "If that feels right."),
        (.girl, "Hey, girlie 🌸", "A little more familiar."),
        (.custom, "use my own words", "Type your own greeting.")
    ]

    private var canContinue: Bool {
        draft.salutation != .custom || !draft.customGreeting.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        OnboardingScaffold(
            title: "How should we greet you?",
            subtitle: "Shows at the top of Home every time you open the app. If you skip, it's just \"Hello.\"",
            currentStep: .salutation,
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
                        isSelected: draft.salutation == option.0,
                        action: { draft.salutation = option.0 }
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
