import Foundation
import SwiftData

/// Pulls menstrual history out of Apple Health and replays it into Astera's store.
///
/// Why: HealthKit is the lingua franca for menstrual flow on iOS. Flo, Clue, Stardust,
/// Apple's built-in Cycle Tracking, and Natural Cycles all write here. Importing means
/// users don't lose years of data when they switch to Astera.
enum HealthKitImportService {
    struct Result: Equatable {
        var samplesFound: Int
        var daysImported: Int
        var cyclesAdded: Int
        var sourceNames: [String]

        var didFindAnything: Bool { samplesFound > 0 }
    }

    /// Asks for HealthKit read access (if not already granted) and replays every menstrual
    /// flow sample we don't already have on file. Idempotent: re-running won't duplicate days.
    @MainActor
    static func runImport(defaultMode: CycleMode, context: ModelContext) async throws -> Result {
        let granted = await HealthKitService.requestAccess()
        guard granted else {
            return Result(samplesFound: 0, daysImported: 0, cyclesAdded: 0, sourceNames: [])
        }
        let samples = try await HealthKitService.fetchMenstrualHistory()
        return try applySamples(samples, defaultMode: defaultMode, context: context)
    }

    /// Pure-data variant for testing and reuse. Walks samples chronologically, skipping any
    /// day we've already logged. Cycle inference is delegated to LogService.
    static func applySamples(
        _ samples: [HealthKitService.MenstrualSample],
        defaultMode: CycleMode,
        context: ModelContext
    ) throws -> Result {
        let sources = Array(Set(samples.map(\.sourceName))).sorted()
        guard !samples.isEmpty else {
            return Result(samplesFound: 0, daysImported: 0, cyclesAdded: 0, sourceNames: sources)
        }

        let cyclesBefore = try context.fetch(FetchDescriptor<Cycle>()).count

        let existingFlowEntries = (try? context.fetch(FetchDescriptor<FlowEntry>())) ?? []
        let existingFlowDays = Set(existingFlowEntries.map { Calendar.current.startOfDay(for: $0.day) })

        var daysImported = 0
        for sample in samples.sorted(by: { $0.day < $1.day }) {
            if existingFlowDays.contains(sample.day) { continue }
            try LogService.apply(
                LogInput(date: sample.day, flow: sample.intensity, symptoms: [:], notes: ""),
                defaultMode: defaultMode,
                context: context
            )
            daysImported += 1
        }

        let cyclesAfter = try context.fetch(FetchDescriptor<Cycle>()).count
        return Result(
            samplesFound: samples.count,
            daysImported: daysImported,
            cyclesAdded: max(0, cyclesAfter - cyclesBefore),
            sourceNames: sources
        )
    }
}
