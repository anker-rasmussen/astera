import Foundation

struct PeriodPrediction: Equatable {
    let center: Date
    let lowerBound: Date
    let upperBound: Date
    let confidence: Confidence
    let basis: Basis

    enum Confidence: Equatable {
        case populationPrior
        case low
        case medium
        case high
    }

    enum Basis: Equatable {
        case populationOnly
        case singleObservation(lastStart: Date, assumedLength: Int)
        case bayesian(
            lastStart: Date,
            observationCount: Int,
            meanLength: Double,
            predictiveStdDev: Double,
            cycleMode: CycleMode
        )
    }

    var rangeText: String {
        let lower = lowerBound.formatted(.dateTime.day(.defaultDigits).month(.abbreviated))
        let upper = upperBound.formatted(.dateTime.day(.defaultDigits).month(.abbreviated))
        return "\(lower) – \(upper)"
    }

    var confidenceLabel: String {
        switch confidence {
        case .populationPrior: return "Just a first guess · based on typical cycles"
        case .low: return "Rough estimate · we've only seen one cycle of yours"
        case .medium: return "Tightening up · a few cycles in"
        case .high: return "Pretty sure · your pattern is steady"
        }
    }

    var daysUntilCentre: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: center)
        return cal.dateComponents([.day], from: today, to: target).day ?? 0
    }
}

/// Convenience helpers. Back-compat for the simple case (no cycle history).
/// Real prediction work happens in `BayesianPredictor`.
enum SimplePredictor {
    static func predict(
        lastStart: Date?,
        typicalCycleLength: Int?,
        from referenceDate: Date = Date()
    ) -> PeriodPrediction {
        BayesianPredictor.predict(
            lastStart: lastStart,
            observedLengths: [],
            cycleMode: .notSure,
            from: referenceDate
        )
    }

    static func cycleDay(for lastStart: Date?, on date: Date = Date()) -> Int? {
        guard let lastStart else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: lastStart)
        let today = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(1, days + 1)
    }
}
