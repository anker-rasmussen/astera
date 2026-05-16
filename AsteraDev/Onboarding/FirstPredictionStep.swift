import SwiftUI

struct FirstPredictionStep: View {
    @Bindable var draft: OnboardingDraft
    let onBack: () -> Void
    let onFinish: () -> Void

    private var prediction: PeriodPrediction {
        // At first-prediction time we have at most one Cycle (just-logged start) and no observed lengths yet.
        // If the user gave us a typical length, fold it in as a single virtual observation.
        let observed = draft.cycleLengthKnown ? [draft.typicalCycleLength] : []
        return BayesianPredictor.predict(
            lastStart: draft.lastPeriodStart,
            observedLengths: observed,
            cycleMode: draft.cycleMode
        )
    }

    var body: some View {
        if !draft.cycleMode.shouldPredictPeriods {
            quietFirstReading
        } else {
            predictedFirstReading
        }
    }

    private var quietFirstReading: some View {
        OnboardingScaffold(
            title: quietTitle,
            subtitle: quietSubtitle,
            currentStep: .firstPrediction,
            continueLabel: "Continue to home",
            showSkip: false,
            onBack: onBack,
            onContinue: onFinish
        ) {
            VStack(alignment: .leading, spacing: AsteraSpacing.lg) {
                Hairline()
                VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                    CapsLabel(text: "What home looks like")
                    Text(quietHomeExplainer)
                        .font(.asteraSerifItalic(15))
                        .foregroundStyle(AsteraColor.ink.opacity(0.85))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, AsteraSpacing.lg)
                Hairline()
                VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                    CapsLabel(text: "Your history is safe")
                    Text("Whatever you've logged stays. Switching modes never deletes anything. When you're ready, you can switch back from Settings.")
                        .font(.asteraSerifItalic(15))
                        .foregroundStyle(AsteraColor.ink.opacity(0.85))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, AsteraSpacing.lg)
            }
        }
    }

    private var quietTitle: String {
        switch draft.cycleMode {
        case .pregnant: return "Pregnancy mode."
        case .postLoss: return "We'll be quiet for a while."
        case .postpartum: return "Postpartum mode."
        case .surgicalMenopause: return "No forecasts. Just you."
        case .trackingOnT: return "No bleed forecasts here."
        default: return "Your first reading."
        }
    }

    private var quietSubtitle: String {
        switch draft.cycleMode {
        case .pregnant: return "Period predictions are off. The home tab will count pregnancy weeks instead."
        case .postLoss: return "Period reminders and predictions are quiet. The home tab will be gentle until you tell us you're ready."
        case .postpartum: return "Period predictions are paused. Bodies take their time after birth. We'll quietly resume when you log a real cycle."
        case .surgicalMenopause: return "Cycle predictions are off. The rest of the app stays available for symptoms, notes, and history."
        case .trackingOnT: return "We won't forecast bleeds. Logging and history stay yours, as always."
        default: return ""
        }
    }

    private var quietHomeExplainer: String {
        switch draft.cycleMode {
        case .pregnant: return "Pregnancy mode shows weeks since your last period, your trimester, and an estimated due date. Period prediction is paused. You can still log symptoms and notes from the home tab any time."
        case .postLoss: return "The home tab will say \"We're here\" instead of counting cycle days. No period reminders. No predictions. A log button waits quietly below, for symptoms, notes, anything you need to write down."
        case .postpartum: return "The home tab won't tell you you're \"late.\" Periods can return weeks or months after birth, and that's normal. When you log a real flow day, we'll quietly start tracking again."
        case .surgicalMenopause: return "The home tab shows a gentle log entry point and your history. No forecasts, no reminders, no \"late\" alerts. Symptom and note logging stay available for clinician visits and your own records."
        case .trackingOnT: return "The home tab keeps logging and history available without forecasting bleeds. Cycle changes on T are varied, and Astera won't pretend otherwise."
        default: return ""
        }
    }

    private var predictedFirstReading: some View {
        OnboardingScaffold(
            title: "Your first reading.",
            subtitle: prediction.basis == .populationOnly
                ? "We don't know your pattern yet. This is a friendly placeholder so the app is useful from day one. It'll sharpen as you log a few cycles."
                : "An honest first guess. It tightens up as you log a few cycles.",
            currentStep: .firstPrediction,
            continueLabel: "Continue to home",
            showSkip: false,
            onBack: onBack,
            onContinue: onFinish
        ) {
            VStack(alignment: .leading, spacing: AsteraSpacing.lg) {
                Hairline()

                VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                    CapsLabel(text: "Period expected")
                    Text(prediction.rangeText)
                        .font(.asteraNumeric(44, weight: .medium))
                        .foregroundStyle(AsteraColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    HStack(spacing: 6) {
                        Circle().fill(AsteraColor.accent.opacity(0.7)).frame(width: 6, height: 6)
                        Text(prediction.confidenceLabel)
                            .font(.asteraSerifItalic(14))
                            .foregroundStyle(AsteraColor.iron)
                    }
                }
                .padding(.vertical, AsteraSpacing.lg)

                Hairline()

                VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                    CapsLabel(text: "Why this range")
                    Text(reasoning)
                        .font(.asteraSerifItalic(15))
                        .foregroundStyle(AsteraColor.ink.opacity(0.8))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, AsteraSpacing.lg)

                Hairline()

                VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                    CapsLabel(text: "What you can do now")
                    bulletRow(title: "Log today's flow or symptoms. It takes seconds and tightens the prediction.")
                    bulletRow(title: "Edit anything you told us, any time, from Settings.")
                    bulletRow(title: "Leave whenever you like. One tap exports everything.")
                }
                .padding(.vertical, AsteraSpacing.lg)
            }
        }
    }

    private var reasoning: String {
        switch prediction.basis {
        case .populationOnly:
            return "We're using a 28-day average because you haven't told us when your last period started. Once you log a cycle, this will use your own pattern instead."
        case .singleObservation(let lastStart, let length):
            let lastStartText = lastStart.formatted(.dateTime.day(.defaultDigits).month(.wide))
            return "Your last period started \(lastStartText). We're guessing \(length) days from then, with a few-day window until we see more of your pattern."
        case .bayesian(let lastStart, _, let mean, _, _):
            let lastStartText = lastStart.formatted(.dateTime.day(.defaultDigits).month(.wide))
            let rounded = Int(mean.rounded())
            if draft.cycleLengthKnown {
                return "Your last period started \(lastStartText). You told us your cycles run about \(rounded) days. We're guessing \(rounded) days from then, with a small window that'll narrow as you log more cycles."
            } else {
                return "Your last period started \(lastStartText). Based on typical cycles for your mode, we're guessing \(rounded) days from then."
            }
        }
    }

    private func bulletRow(title: String) -> some View {
        HStack(alignment: .top, spacing: AsteraSpacing.sm) {
            Text("·")
                .font(.asteraSerif(18, weight: .medium))
                .foregroundStyle(AsteraColor.accent)
            Text(title)
                .font(.asteraSerifItalic(15))
                .foregroundStyle(AsteraColor.ink.opacity(0.8))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
