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
            Text("Here's where the numbers come from. No guesses dressed up as certainty.")
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
            CapsLabel(text: "How we worked it out")
            Text(reasoningText)
                .font(.asteraSerifItalic(15))
                .foregroundStyle(AsteraColor.ink.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var observationsBlock: some View {
        VStack(alignment: .leading, spacing: AsteraSpacing.sm) {
            CapsLabel(text: "Your cycles so far")
            if observedLengths.isEmpty {
                Text("You haven't completed a full cycle here yet, so we're leaning on the average pattern for the mode you picked.")
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
            CapsLabel(text: "Why the window is this wide")
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
            return "You haven't logged a last period start yet, so this is a guess based on average cycles for your mode (\(cycleMode.displayName.lowercased())). Log a period and this will switch to your own pattern."

        case .singleObservation(let lastStart, let length):
            let dateText = lastStart.formatted(.dateTime.day(.defaultDigits).month(.wide))
            return "Your last period started \(dateText). We're projecting \(length) days from then, using typical lengths for your mode (\(cycleMode.displayName.lowercased())). Once we've seen a few of your cycles, this prediction will use your own pattern instead."

        case .bayesian(let lastStart, let count, let mean, _, let mode):
            let dateText = lastStart.formatted(.dateTime.day(.defaultDigits).month(.wide))
            let rounded = Int(mean.rounded())
            return "Your last period started \(dateText). Across \(count) cycle\(count == 1 ? "" : "s") of yours, blended with typical \(mode.displayName.lowercased()) cycles, the average comes out to \(rounded) days. We're projecting that forward from your last start."
        }
    }

    private var windowExplainer: String {
        switch prediction.basis {
        case .populationOnly, .singleObservation:
            return "The window's wide right now because we haven't seen many of your cycles yet. It reflects how variable your mode tends to be in general, and it'll tighten as you log more."
        case .bayesian(_, let count, _, let stdDev, _):
            let half = Int((1.5 * stdDev).rounded())
            return "The window is about ±\(max(1, half)) days, drawn to cover most of how your cycles have varied so far (\(count) logged). The more you log, the tighter it gets. If your cycles are naturally variable, the window stays wider on purpose. That's honest, not a flaw."
        }
    }
}
