import SwiftUI

struct RelationshipStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingScaffold(
            title: RelationshipStructure.question,
            subtitle: RelationshipStructure.questionSubtitle,
            currentStep: .relationship,
            onBack: onBack,
            onSkip: onSkip,
            onContinue: onContinue
        ) {
            HairlineList {
                ForEach(RelationshipStructure.choices) { option in
                    HairlineRow(
                        title: option.title,
                        subtitle: option.subtitle,
                        isSelected: draft.relationshipStructure == option.value,
                        identifier: option.accessibilityID,
                        action: { draft.relationshipStructure = option.value }
                    )
                    Hairline()
                }
            }
        }
    }
}
