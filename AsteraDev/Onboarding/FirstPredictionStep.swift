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
                    Text("Whatever you've already logged stays exactly where it is. Switching modes never deletes anything. When you're ready, you can switch back from Settings.")
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
        case .pregnant: return "We're switching to pregnancy mode."
        case .postLoss: return "We'll be quiet for a while."
        case .postpartum: return "Postpartum mode."
        case .surgicalMenopause: return "No forecasts, just you."
        case .trackingOnT: return "No bleed forecasts here."
        default: return "Your first reading."
        }
    }

    private var quietSubtitle: String {
        switch draft.cycleMode {
        case .pregnant: return "Period predictions are off. The home tab counts pregnancy weeks instead."
        case .postLoss: return "We've quieted period reminders and predictions. The home tab will stay gentle for as long as you need."
        case .postpartum: return "Period predictions are paused. Bodies take their time after birth. Whenever yours is ready, log a cycle and tracking will pick up again."
        case .surgicalMenopause: return "Cycle predictions are off. Symptoms, notes, and history are still here for you."
        case .trackingOnT: return "We won't forecast bleeds. Logging, history, and notes are still yours, like always."
        default: return ""
        }
    }

    private var quietHomeExplainer: String {
        switch draft.cycleMode {
        case .pregnant: return "Pregnancy mode shows weeks since your last period, your trimester, and an estimated due date. Period prediction is paused. You can still log symptoms and notes from the home tab any time."
        case .postLoss: return "The home tab will say \"We're here\" instead of counting cycle days. No period reminders. No predictions. A log button waits quietly below, for symptoms, notes, anything you might want to write down."
        case .postpartum: return "The home tab won't tell you you're \"late.\" Periods can take weeks or even months to come back, especially if you're nursing. All of that is normal. When you log a flow day, tracking will quietly start up again."
        case .surgicalMenopause: return "The home tab keeps logging and history available. No forecasts, no reminders, no \"late\" alerts. Symptom and note logging is still useful, especially for clinician visits."
        case .trackingOnT: return "The home tab keeps logging and history available without forecasting bleeds. Cycle changes on T are real and varied, and Astera isn't going to pretend otherwise."
        default: return ""
        }
    }

    private var predictedFirstReading: some View {
        OnboardingScaffold(
            title: "Your first reading.",
            subtitle: prediction.basis == .populationOnly
                ? "We don't have your pattern yet, so this is a friendly placeholder. It'll sharpen as you log a few cycles."
                : "An honest first guess. It'll tighten up as you log a few cycles.",
            currentStep: .firstPrediction,
            continueLabel: "Continue to home",
            showSkip: false,
            onBack: onBack,
            onContinue: onFinish
        ) {
            VStack(alignment: .leading, spacing: AsteraSpacing.lg) {
                Hairline()

                VStack(alignment: .leading, spacing: AsteraSpacing.md) {
                    CapsLabel(text: PeriodPrediction.expectedLabel)
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
            return "We're using a 28-day average because you haven't logged a period start yet. Once you log one, this switches over to your own pattern."
        case .singleObservation(let lastStart, let length):
            let lastStartText = lastStart.formatted(.dateTime.day(.defaultDigits).month(.wide))
            return "Your last period started \(lastStartText). Our best guess is \(length) days from then, with a few-day window. It'll tighten up as you log more cycles."
        case .bayesian(let lastStart, _, let mean, _, _):
            let lastStartText = lastStart.formatted(.dateTime.day(.defaultDigits).month(.wide))
            let rounded = Int(mean.rounded())
            if draft.cycleLengthKnown {
                return "Your last period started \(lastStartText). You told us your cycles run about \(rounded) days. Our best guess is \(rounded) days from then, with a small window that narrows as you log more."
            } else {
                return "Your last period started \(lastStartText). Based on typical cycles for your mode, our best guess is \(rounded) days from then."
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
