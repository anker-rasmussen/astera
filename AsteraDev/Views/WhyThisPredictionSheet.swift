import SwiftUI

struct WhyThisPredictionSheet: View {
    let prediction: PeriodPrediction
    let lastStart: Date?
    let observedLengths: [Int]
    let cycleMode: CycleMode
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Done", action: onDismiss)
                    .buttonStyle(AsteraGhostButtonStyle())
                Spacer()
                EmptyView()
            }
            .asteraEditorialMargins()
            .padding(.top, AsteraSpacing.md)

            Hairline().asteraEditorialMargins().padding(.top, AsteraSpacing.sm)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AsteraSpacing.xl) {
                    headline
                    Hairline()
                    rangeBlock
                    Hairline()
                    reasoningBlock
                    Hairline()
                    observationsBlock
                    Hairline()
                    confidenceBlock
                }
                .asteraEditorialMargins()
                .padding(.top, AsteraSpacing.lg)
                .padding(.bottom, AsteraSpacing.xxl)
            }
        }
        .asteraScreen()
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "Why this prediction")
            Text("How we got here.")
                .font(.asteraSerif(30, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            Text("Where the numbers came from. We won't show you a date without showing you the working underneath it.")
                .font(.asteraSerifItalic(15))
                .foregroundStyle(AsteraColor.iron)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var rangeBlock: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "Expected window")
            Text(prediction.rangeText)
                .font(.asteraNumeric(40, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
            HStack(spacing: 6) {
                Circle().fill(AsteraColor.accent.opacity(0.7)).frame(width: 6, height: 6)
                Text(prediction.confidenceLabel)
                    .font(.asteraSerifItalic(14))
                    .foregroundStyle(AsteraColor.iron)
            }
        }
    }

    private var reasoningBlock: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "What we did")
            Text(reasoningText)
                .font(.asteraSerifItalic(15))
                .foregroundStyle(AsteraColor.ink.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var observationsBlock: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "What we've learned from you")
            if observedLengths.isEmpty {
                Text("No completed cycles yet. We're leaning on the average pattern for the mode you picked.")
                    .font(.asteraSerifItalic(15))
                    .foregroundStyle(AsteraColor.ink.opacity(0.85))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(observedLengths.enumerated()), id: \.offset) { idx, length in
                        HStack {
                            Text("Cycle \(idx + 1)")
                                .font(.asteraSerifItalic(14))
                                .foregroundStyle(AsteraColor.iron)
                            Spacer()
                            Text("\(length) days")
                                .font(.asteraNumeric(17, weight: .medium))
                                .foregroundStyle(AsteraColor.ink)
                        }
                    }
                    if observedLengths.count >= 2 {
                        Hairline().padding(.vertical, 6)
                        let mean = Double(observedLengths.reduce(0, +)) / Double(observedLengths.count)
                        HStack {
                            Text("Average")
                                .font(.asteraSerifItalic(14))
                                .foregroundStyle(AsteraColor.iron)
                            Spacer()
                            Text(String(format: "%.1f days", mean))
                                .font(.asteraNumeric(17, weight: .medium))
                                .foregroundStyle(AsteraColor.ink)
                        }
                    }
                }
            }
        }
    }

    private var confidenceBlock: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "On the window")
            Text(windowExplainer)
                .font(.asteraSerifItalic(15))
                .foregroundStyle(AsteraColor.ink.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Copy

    private var reasoningText: String {
        switch prediction.basis {
        case .populationOnly:
            return "We don't have your last period start logged, so this is a guess based on average cycles for your mode (\(cycleMode.displayName.lowercased())). Log a period and we'll move to your own pattern."

        case .singleObservation(let lastStart, let length):
            let dateText = lastStart.formatted(.dateTime.day(.defaultDigits).month(.wide))
            return "Your last period started \(dateText). We're predicting \(length) days from then, using typical lengths for your mode (\(cycleMode.displayName.lowercased())). Once we see a few of your cycles, this prediction will use your own pattern instead."

        case .bayesian(let lastStart, let count, let mean, _, let mode):
            let dateText = lastStart.formatted(.dateTime.day(.defaultDigits).month(.wide))
            let rounded = Int(mean.rounded())
            return "Your last period started \(dateText). Across \(count) cycle\(count == 1 ? "" : "s") of yours, blended with typical \(mode.displayName.lowercased()) cycles, the average works out to \(rounded) days. We project \(rounded) days forward from your last start."
        }
    }

    private var windowExplainer: String {
        switch prediction.basis {
        case .populationOnly, .singleObservation:
            return "The window is wide because we haven't seen enough of you yet. It reflects how variable your mode tends to be in general. It will tighten."
        case .bayesian(_, let count, _, let stdDev, _):
            let half = Int((1.5 * stdDev).rounded())
            return "We show a window of about ±\(max(1, half)) days, drawn to cover most of how your cycles have varied so far (\(count) logged). More cycles, tighter window. More variable cycles, wider window. That's the honest picture, not a flaw."
        }
    }
}
