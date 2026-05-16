import Foundation
import Testing
@testable import Astera

@Suite("Bayesian predictor")
struct BayesianPredictorTests {
    private let calendar = Calendar.current

    private func date(daysAgo: Int) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))!
    }

    private func daysBetween(_ from: Date, _ to: Date) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: from), to: calendar.startOfDay(for: to)).day ?? 0
    }

    // MARK: - Population prior behaviour

    @Test("Zero observations + regular mode falls back to ~28 days from lastStart")
    func populationPriorRegular() throws {
        let lastStart = date(daysAgo: 5)
        let prediction = BayesianPredictor.predict(
            lastStart: lastStart,
            observedLengths: [],
            cycleMode: .regular
        )
        let offset = daysBetween(lastStart, prediction.center)
        #expect(offset == 28)
        #expect(prediction.confidence == .populationPrior)
    }

    @Test("PCOS prior shifts the mean toward longer cycles")
    func populationPriorPCOS() throws {
        let lastStart = date(daysAgo: 5)
        let prediction = BayesianPredictor.predict(
            lastStart: lastStart,
            observedLengths: [],
            cycleMode: .pcos
        )
        let offset = daysBetween(lastStart, prediction.center)
        #expect(offset >= 32) // PCOS prior mean is 35
        #expect(prediction.confidence == .populationPrior)
    }

    @Test("Regular mode gives a tighter band than irregular for zero observations")
    func bandWidthByMode() throws {
        let regular = BayesianPredictor.predict(
            lastStart: date(daysAgo: 0),
            observedLengths: [],
            cycleMode: .regular
        )
        let irregular = BayesianPredictor.predict(
            lastStart: date(daysAgo: 0),
            observedLengths: [],
            cycleMode: .irregular
        )
        let regularHalf = daysBetween(regular.lowerBound, regular.upperBound) / 2
        let irregularHalf = daysBetween(irregular.lowerBound, irregular.upperBound) / 2
        #expect(regularHalf < irregularHalf)
    }

    // MARK: - Bayesian update

    @Test("Three consistent 28-day cycles tighten the band toward the data")
    func consistentObservationsTighten() throws {
        let lastStart = date(daysAgo: 0)
        let prediction = BayesianPredictor.predict(
            lastStart: lastStart,
            observedLengths: [28, 28, 28],
            cycleMode: .regular
        )
        let offset = daysBetween(lastStart, prediction.center)
        #expect(offset == 28)
        let half = daysBetween(prediction.lowerBound, prediction.upperBound) / 2
        #expect(half <= 4) // Spec target: <2 MAE on regular ≥3 logged. Half-width should be tight.
        #expect(prediction.confidence == .medium)
    }

    @Test("Highly variable observations widen the band")
    func variableObservationsWiden() throws {
        let lastStart = date(daysAgo: 0)
        let stable = BayesianPredictor.predict(
            lastStart: lastStart,
            observedLengths: [28, 28, 28, 29, 28],
            cycleMode: .regular
        )
        let variable = BayesianPredictor.predict(
            lastStart: lastStart,
            observedLengths: [22, 30, 25, 35, 32],
            cycleMode: .irregular
        )
        let stableHalf = daysBetween(stable.lowerBound, stable.upperBound) / 2
        let variableHalf = daysBetween(variable.lowerBound, variable.upperBound) / 2
        #expect(variableHalf > stableHalf)
    }

    @Test("Posterior mean is pulled toward observations as data accumulates")
    func posteriorShifts() throws {
        let lastStart = date(daysAgo: 0)
        // User's true cycle length is 30 days, but population prior is 28.
        let prediction = BayesianPredictor.predict(
            lastStart: lastStart,
            observedLengths: [30, 30, 30, 30, 30, 30],
            cycleMode: .regular
        )
        let offset = daysBetween(lastStart, prediction.center)
        // With enough evidence, posterior should shift toward 30.
        #expect(offset >= 29)
        #expect(offset <= 30)
        #expect(prediction.confidence == .high)
    }

    @Test("Single observation only nudges the prior")
    func singleObservationNudges() throws {
        let lastStart = date(daysAgo: 0)
        // Regular prior: μ₀=28, τ₀=2, σ=2 (precision-weighted)
        // 1 observation of 32 with weight 1/(2²)=0.25; prior weight 1/(2²)=0.25 → posterior mean ≈ 30
        let prediction = BayesianPredictor.predict(
            lastStart: lastStart,
            observedLengths: [32],
            cycleMode: .regular
        )
        let offset = daysBetween(lastStart, prediction.center)
        #expect(offset >= 29 && offset <= 31)
        #expect(prediction.confidence == .low)
    }

    // MARK: - Length extraction from cycles

    @Test("Observed lengths derive correctly from consecutive cycle dates")
    func observedLengthsFromCycles() throws {
        let cycles = [
            Cycle(startDate: date(daysAgo: 84), modeAtStart: .regular),
            Cycle(startDate: date(daysAgo: 56), modeAtStart: .regular),
            Cycle(startDate: date(daysAgo: 28), modeAtStart: .regular)
        ]
        #expect(cycles.observedLengths == [28, 28])
    }

    @Test("Implausible cycle gaps are filtered out")
    func filtersImplausibleGaps() throws {
        let cycles = [
            Cycle(startDate: date(daysAgo: 200), modeAtStart: .regular),
            Cycle(startDate: date(daysAgo: 56), modeAtStart: .regular),
            Cycle(startDate: date(daysAgo: 28), modeAtStart: .regular)
        ]
        // First gap is 144 days (filtered). Second gap is 28 (kept).
        #expect(cycles.observedLengths == [28])
    }
}
