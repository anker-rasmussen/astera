import SwiftUI

struct CycleModeStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    private let allOptions: [(CycleMode, String, String)] = [
        (.regular, "regular cycles", "Usually within a few days of the same length."),
        (.irregular, "irregular cycles", "Length varies a lot, with no clear pattern."),
        (.pcos, "PCOS", "We'll skip ovulation prompts unless you ask."),
        (.endometriosis, "endometriosis", "Wider bands, pain logging up front, no false certainty."),
        (.iud, "have an IUD", "We'll quietly accept lighter or absent bleeds."),
        (.hormonalBC, "on hormonal birth control", "Pill, patch, ring, implant, injection. Withdrawal or absent bleeds are both normal."),
        (.perimenopause, "perimenopause", "Variable cycles are expected, not a tracking failure."),
        (.surgicalMenopause, "after surgical menopause or hysterectomy", "Cycle predictions are off. The rest of the app stays useful."),
        (.pregnant, "pregnant", "We'll switch to a week-by-week view. Your cycle history stays."),
        (.postLoss, "after pregnancy loss", "We'll keep your history, exactly. Reminders stay quiet until you're ready."),
        (.ttc, "trying to conceive", "Fertility window with confidence bands. No countdown, no comparison."),
        (.postpartum, "postpartum", "Bodies take their time. We'll wait quietly until you're ready."),
        (.trackingOnT, "tracking on T", "Cycle changes on T are real. We'll log without forecasting bleeds."),
        (.notSure, "not sure yet", "That's completely fine. You can change this any time without losing anything.")
    ]

    private var options: [(CycleMode, String, String)] {
        AgeMode.hideFertilityContent(birthYear: draft.birthYear)
            ? allOptions.filter { $0.0 != .ttc }
            : allOptions
    }

    var body: some View {
        OnboardingScaffold(
            title: "Where are you right now?",
            subtitle: "You can change states any time. Your history stays.",
            currentStep: .cycleMode,
            onBack: onBack,
            onSkip: onSkip,
            onContinue: onContinue
        ) {
            HairlineList {
                ForEach(Array(options.enumerated()), id: \.element.0) { _, option in
                    HairlineRow(
                        title: option.1,
                        subtitle: option.2,
                        isSelected: draft.cycleMode == option.0,
                        action: { draft.cycleMode = option.0 }
                    )
                    Hairline()
                }
            }
        }
    }
}
