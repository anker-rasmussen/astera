import SwiftUI

struct CycleModeStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    /// Onboarding has no `UserProfile` yet, only the birth year the user just gave us.
    private var options: [ProfileChoice<CycleMode>] {
        CycleMode.choices(hidingFertilityContent: AgeMode.hideFertilityContent(birthYear: draft.birthYear))
    }

    var body: some View {
        OnboardingScaffold(
            title: CycleMode.question,
            subtitle: "Changeable any time. Your history stays.",
            currentStep: .cycleMode,
            onBack: onBack,
            onSkip: onSkip,
            onContinue: onContinue
        ) {
            HairlineList {
                ForEach(options) { option in
                    HairlineRow(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: draft.cycleMode == option.value,
                        identifier: option.accessibilityID,
                        action: { draft.cycleMode = option.value }
                    )
                    Hairline()
                }
            }
        }
    }
}
