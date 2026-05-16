import Foundation

/// Bayesian period predictor using a Normal–Normal conjugate prior over cycle length.
///
/// Model:
///   prior:        μ ~ Normal(μ₀, τ₀²),  with observation variance σ² known
///   likelihood:   Lᵢ | μ, σ ~ Normal(μ, σ²)  for each observed cycle length
///   posterior:    μ | data ~ Normal(μₙ, τₙ²)
///   predictive:   L_new | data ~ Normal(μₙ, τₙ² + σ²)
///
/// We display the *predictive* distribution: centre = μₙ days after the last logged start, half-width = c · √(τₙ² + σ²).
///
/// Priors and confidence labelling adapt to cycle mode (see [[CycleLengthPrior]]).
enum BayesianPredictor {
    /// Band scaling factor. Sets how much of the predictive density falls inside the displayed window.
    /// 1.0 ≈ 68% (one-sigma); 1.5 ≈ 87%; 2.0 ≈ 95%.
    /// 1.5 hits the spec §4 MAE targets while still being a meaningful "expected window."
    static let bandFactor: Double = 1.5

    static let minBandHalfWidth: Int = 1
    static let maxBandHalfWidth: Int = 14

    static func predict(
        lastStart: Date?,
        observedLengths: [Int],
        cycleMode: CycleMode,
        from referenceDate: Date = Date()
    ) -> PeriodPrediction {
        let prior = CycleLengthPrior.forMode(cycleMode)
        let posterior = posteriorParameters(prior: prior, observations: observedLengths)

        let calendar = Calendar.current
        let bandHalf = clampedBandHalf(posterior.predictiveStdDev)

        let centerDate: Date
        if let lastStart {
            centerDate = calendar.date(byAdding: .day, value: Int(posterior.meanRounded), to: lastStart) ?? referenceDate
        } else {
            centerDate = calendar.date(byAdding: .day, value: Int(posterior.meanRounded / 2), to: referenceDate) ?? referenceDate
        }

        let lower = calendar.date(byAdding: .day, value: -bandHalf, to: centerDate) ?? centerDate
        let upper = calendar.date(byAdding: .day, value: bandHalf, to: centerDate) ?? centerDate

        return PeriodPrediction(
            center: centerDate,
            lowerBound: lower,
            upperBound: upper,
            confidence: confidence(forObservationCount: observedLengths.count),
            basis: basis(lastStart: lastStart, observedLengths: observedLengths, posterior: posterior, cycleMode: cycleMode)
        )
    }

    // MARK: - Posterior computation

    struct Posterior: Equatable {
        let mean: Double
        let meanStdDev: Double
        let observationStdDev: Double
        let predictiveStdDev: Double

        var meanRounded: Double { mean.rounded() }
    }

    static func posteriorParameters(prior: CycleLengthPrior, observations: [Int]) -> Posterior {
        let n = Double(observations.count)

        // Precision-weighted update for the posterior mean.
        // 1/τ_n² = 1/τ_0² + n/σ²
        // μ_n   = ( μ_0/τ_0² + Σ Lᵢ / σ² ) / (1/τ_0²+n/σ²)
        let priorPrecision = 1.0 / max(prior.meanStdDev * prior.meanStdDev, 0.0001)
        let dataPrecisionPer = 1.0 / max(prior.observationStdDev * prior.observationStdDev, 0.0001)

        let sumObservations = Double(observations.reduce(0, +))
        let posteriorPrecision = priorPrecision + n * dataPrecisionPer
        let posteriorMean = (prior.mean * priorPrecision + sumObservations * dataPrecisionPer) / posteriorPrecision
        let posteriorMeanStdDev = sqrt(1.0 / posteriorPrecision)

        // Mix prior observation variance with sample variance, weighted by effective sample size.
        let observationStdDev: Double
        if n >= 2 {
            let sampleMean = sumObservations / n
            let sampleVar = observations.map { pow(Double($0) - sampleMean, 2) }.reduce(0, +) / (n - 1)
            let weight = min(1.0, n / (prior.strength + n))
            observationStdDev = sqrt((1 - weight) * pow(prior.observationStdDev, 2) + weight * sampleVar)
        } else {
            observationStdDev = prior.observationStdDev
        }

        let predictiveStdDev = sqrt(pow(posteriorMeanStdDev, 2) + pow(observationStdDev, 2))

        return Posterior(
            mean: posteriorMean,
            meanStdDev: posteriorMeanStdDev,
            observationStdDev: observationStdDev,
            predictiveStdDev: predictiveStdDev
        )
    }

    // MARK: - Helpers

    private static func clampedBandHalf(_ stdDev: Double) -> Int {
        let raw = Int((bandFactor * stdDev).rounded())
        return max(minBandHalfWidth, min(maxBandHalfWidth, raw))
    }

    private static func confidence(forObservationCount n: Int) -> PeriodPrediction.Confidence {
        switch n {
        case 0: return .populationPrior
        case 1...2: return .low
        case 3...5: return .medium
        default: return .high
        }
    }

    private static func basis(
        lastStart: Date?,
        observedLengths: [Int],
        posterior: Posterior,
        cycleMode: CycleMode
    ) -> PeriodPrediction.Basis {
        guard let lastStart else { return .populationOnly }
        if observedLengths.isEmpty {
            return .singleObservation(lastStart: lastStart, assumedLength: Int(posterior.meanRounded))
        }
        return .bayesian(
            lastStart: lastStart,
            observationCount: observedLengths.count,
            meanLength: posterior.meanRounded,
            predictiveStdDev: posterior.predictiveStdDev,
            cycleMode: cycleMode
        )
    }
}

extension Array where Element == Cycle {
    /// Observed cycle lengths in days, derived from consecutive start dates.
    /// Filters out implausible lengths (< 14 days or > 80 days) so a misclicked entry doesn't poison the model.
    var observedLengths: [Int] {
        let sorted = self.sorted { $0.startDate < $1.startDate }
        guard sorted.count >= 2 else { return [] }
        var lengths: [Int] = []
        let calendar = Calendar.current
        for (earlier, later) in zip(sorted, sorted.dropFirst()) {
            let days = calendar.dateComponents([.day], from: earlier.startDate, to: later.startDate).day ?? 0
            if days >= 14 && days <= 80 {
                lengths.append(days)
            }
        }
        return lengths
    }
}
