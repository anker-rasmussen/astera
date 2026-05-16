import Foundation
import SwiftData

@Model
final class PredictionSnapshot {
    var id: UUID = UUID()
    var generatedAt: Date = Date()
    var phaseLengthPosteriors: Data?
    var nextPeriodCenter: Date = Date()
    var nextPeriodLowerBound: Date = Date()
    var nextPeriodUpperBound: Date = Date()
    var confidence: Double = 0.0

    init(
        id: UUID = UUID(),
        generatedAt: Date = Date(),
        phaseLengthPosteriors: Data? = nil,
        nextPeriodCenter: Date = Date(),
        nextPeriodLowerBound: Date = Date(),
        nextPeriodUpperBound: Date = Date(),
        confidence: Double = 0.0
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.phaseLengthPosteriors = phaseLengthPosteriors
        self.nextPeriodCenter = nextPeriodCenter
        self.nextPeriodLowerBound = nextPeriodLowerBound
        self.nextPeriodUpperBound = nextPeriodUpperBound
        self.confidence = confidence
    }
}
