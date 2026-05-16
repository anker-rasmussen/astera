import SwiftUI

struct RelationshipStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    private let options: [(RelationshipStructure, String, String)] = [
        (.single, "just me", "The simplest setup."),
        (.partneredTracking, "a partner who tracks too", "Partner sync is coming later, if you'd like it."),
        (.partneredNotTracking, "a partner who doesn't", "Nobody is going to bug them about anything."),
        (.polyamorous, "polyamorous", "Same options. No assumptions about structure.")
    ]

    var body: some View {
        OnboardingScaffold(
            title: "Who's in this with you?",
            subtitle: "Affects only optional partner features.",
            currentStep: .relationship,
            onBack: onBack,
            onSkip: onSkip,
            onContinue: onContinue
        ) {
            HairlineList {
                ForEach(Array(options.enumerated()), id: \.element.0) { _, option in
                    HairlineRow(
                        title: option.1,
                        subtitle: option.2,
                        isSelected: draft.relationshipStructure == option.0,
                        action: { draft.relationshipStructure = option.0 }
                    )
                    Hairline()
                }
            }
        }
    }
}
