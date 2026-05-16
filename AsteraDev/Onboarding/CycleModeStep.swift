import SwiftUI

struct CycleModeStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onSkip: () -> Void
    let onContinue: () -> Void

    private let allOptions: [(CycleMode, String, String)] = [
        (.regular, "regular cycles", "Usually within a few days of the same length."),
        (.irregular, "irregular cycles", "Length varies a lot, with no clear pattern."),
        (.pcos, "PCOS", "Ovulation prompts stay off unless you ask for them."),
        (.endometriosis, "endometriosis", "Pain logging up front, wider confidence bands, and no pretending to know more than we do."),
        (.iud, "have an IUD", "Lighter or absent bleeds are normal here, not a missed period."),
        (.hormonalBC, "on hormonal birth control", "Pill, patch, ring, implant, or injection. Withdrawal bleeds and absent bleeds are both normal."),
        (.perimenopause, "perimenopause", "Variable cycles are expected, not a tracking failure."),
        (.surgicalMenopause, "after surgical menopause or hysterectomy", "No cycle predictions. The rest of the app is still here for you."),
        (.pregnant, "pregnant", "We'll switch to a week-by-week view. Your cycle history stays right where it is."),
        (.postLoss, "after pregnancy loss", "Your history stays exactly as it was. Cycle reminders go quiet until you tell us you're ready."),
        (.ttc, "trying to conceive", "A fertility window with confidence bands. No countdown, no comparison."),
        (.postpartum, "postpartum", "Periods come back when they come back. No \"late\" alerts here."),
        (.trackingOnT, "tracking on T", "Cycle changes on T are real and varied. No bleed forecasts."),
        (.notSure, "not sure yet", "That's completely fine. You can change this any time, and nothing you log gets lost.")
    ]

    private var options: [(CycleMode, String, String)] {
        AgeMode.hideFertilityContent(birthYear: draft.birthYear)
            ? allOptions.filter { $0.0 != .ttc }
            : allOptions
    }

    var body: some View {
        OnboardingScaffold(
            title: "Where are you right now?",
            subtitle: "Changeable any time. Your history stays.",
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
