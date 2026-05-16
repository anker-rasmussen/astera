import Foundation
import Testing
import SwiftData
@testable import Astera

@Suite("HealthKitImportService.applySamples")
struct HealthKitImportServiceTests {
    private func freshContext() throws -> ModelContext {
        let container = try PersistenceController.makeContainer(inMemory: true)
        return ModelContext(container)
    }

    private func day(daysFromNow: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: daysFromNow, to: Calendar.current.startOfDay(for: Date()))!
    }

    private func sample(_ daysFromNow: Int, _ intensity: FlowIntensity, source: String = "Flo", cycleStart: Bool = false) -> HealthKitService.MenstrualSample {
        HealthKitService.MenstrualSample(
            day: day(daysFromNow: daysFromNow),
            intensity: intensity,
            isCycleStart: cycleStart,
            sourceName: source
        )
    }

    @Test("Empty samples returns zero-found result")
    func emptySamples() throws {
        let context = try freshContext()
        let result = try HealthKitImportService.applySamples([], defaultMode: .regular, context: context)
        #expect(result.samplesFound == 0)
        #expect(result.daysImported == 0)
        #expect(result.cyclesAdded == 0)
        #expect(result.didFindAnything == false)
    }

    @Test("Three bleed days from one source create one cycle")
    func threeDaysOneCycle() throws {
        let context = try freshContext()
        let samples = [
            sample(-30, .medium, cycleStart: true),
            sample(-29, .medium),
            sample(-28, .light)
        ]
        let result = try HealthKitImportService.applySamples(samples, defaultMode: .regular, context: context)
        #expect(result.daysImported == 3)
        #expect(result.cyclesAdded == 1)
        #expect(result.sourceNames == ["Flo"])
    }

    @Test("Bleed days 30 days apart create two cycles")
    func twoCyclesFromGap() throws {
        let context = try freshContext()
        let samples = [
            sample(-60, .medium, cycleStart: true),
            sample(-59, .light),
            sample(-30, .medium, cycleStart: true),
            sample(-29, .light)
        ]
        let result = try HealthKitImportService.applySamples(samples, defaultMode: .regular, context: context)
        #expect(result.daysImported == 4)
        #expect(result.cyclesAdded == 2)
    }

    @Test("Re-running import is idempotent")
    func idempotent() throws {
        let context = try freshContext()
        let samples = [
            sample(-30, .medium, cycleStart: true),
            sample(-29, .light)
        ]
        let first = try HealthKitImportService.applySamples(samples, defaultMode: .regular, context: context)
        let second = try HealthKitImportService.applySamples(samples, defaultMode: .regular, context: context)
        #expect(first.daysImported == 2)
        #expect(second.daysImported == 0)
        let allFlow = try context.fetch(FetchDescriptor<FlowEntry>())
        #expect(allFlow.count == 2)
    }

    @Test("Existing local FlowEntries are never overwritten")
    func neverOverwritesLocal() throws {
        let context = try freshContext()

        // Pre-seed a manual entry on day -29.
        let manualCycle = Cycle(startDate: day(daysFromNow: -30), modeAtStart: .regular)
        context.insert(manualCycle)
        let manualFlow = FlowEntry(day: day(daysFromNow: -29), intensity: .heavy, source: .manual)
        manualFlow.cycle = manualCycle
        context.insert(manualFlow)
        try context.save()

        // Try to import a different intensity for the same day.
        let samples = [sample(-29, .light)]
        let result = try HealthKitImportService.applySamples(samples, defaultMode: .regular, context: context)
        #expect(result.daysImported == 0)

        let entry = (try context.fetch(FetchDescriptor<FlowEntry>()))
            .first { Calendar.current.isDate($0.day, inSameDayAs: day(daysFromNow: -29)) }
        #expect(entry?.intensity == .heavy) // original preserved
    }

    @Test("Source names are de-duped and sorted")
    func sourceNames() throws {
        let context = try freshContext()
        let samples = [
            sample(-60, .medium, source: "Stardust"),
            sample(-30, .medium, source: "Clue"),
            sample(-29, .light, source: "Clue"),
            sample(-1, .light, source: "Apple Health")
        ]
        let result = try HealthKitImportService.applySamples(samples, defaultMode: .regular, context: context)
        #expect(result.sourceNames == ["Apple Health", "Clue", "Stardust"])
    }
}
