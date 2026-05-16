import Foundation
import Testing
import SwiftData
@testable import Astera

@Suite("LogService cycle inference")
struct LogServiceTests {
    private func freshContext() throws -> ModelContext {
        let container = try PersistenceController.makeContainer(inMemory: true)
        return ModelContext(container)
    }

    private func day(daysFromNow: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: daysFromNow, to: Calendar.current.startOfDay(for: Date()))!
    }

    @Test("Light flow with no prior cycles creates first cycle")
    func firstEverBleedStartsCycle() throws {
        let context = try freshContext()
        let today = day(daysFromNow: 0)
        try LogService.apply(
            LogInput(date: today, flow: .light, symptoms: [:], notes: ""),
            defaultMode: .regular,
            context: context
        )
        let cycles = try context.fetch(FetchDescriptor<Cycle>())
        #expect(cycles.count == 1)
        #expect(Calendar.current.isDate(cycles[0].startDate, inSameDayAs: today))
    }

    @Test("Light flow within 14 days of prior bleed attaches to existing cycle")
    func continuingBleedAttachesToCycle() throws {
        let context = try freshContext()
        let cycleStart = day(daysFromNow: -3)
        let existing = Cycle(startDate: cycleStart, modeAtStart: .regular)
        context.insert(existing)
        let firstDay = FlowEntry(day: cycleStart, intensity: .light)
        firstDay.cycle = existing
        context.insert(firstDay)
        try context.save()

        try LogService.apply(
            LogInput(date: day(daysFromNow: -1), flow: .medium, symptoms: [:], notes: ""),
            defaultMode: .regular,
            context: context
        )

        let cycles = try context.fetch(FetchDescriptor<Cycle>())
        #expect(cycles.count == 1)
        let allFlow = try context.fetch(FetchDescriptor<FlowEntry>())
        #expect(allFlow.count == 2)
    }

    @Test("Light flow ≥14 days after prior bleed starts new cycle")
    func gapStartsNewCycle() throws {
        let context = try freshContext()
        let oldStart = day(daysFromNow: -28)
        let oldCycle = Cycle(startDate: oldStart, modeAtStart: .regular)
        context.insert(oldCycle)
        let oldFlow = FlowEntry(day: oldStart, intensity: .medium)
        oldFlow.cycle = oldCycle
        context.insert(oldFlow)
        try context.save()

        try LogService.apply(
            LogInput(date: day(daysFromNow: 0), flow: .light, symptoms: [:], notes: ""),
            defaultMode: .regular,
            context: context
        )

        let cycles = try context.fetch(FetchDescriptor<Cycle>()).sorted { $0.startDate < $1.startDate }
        #expect(cycles.count == 2)
        #expect(Calendar.current.isDate(cycles.last!.startDate, inSameDayAs: day(daysFromNow: 0)))
    }

    @Test("Re-applying same input doesn't duplicate flow entries")
    func idempotentApply() throws {
        let context = try freshContext()
        let input = LogInput(
            date: day(daysFromNow: 0),
            flow: .medium,
            symptoms: [.cramps: .moderate, .fatigue: .mild],
            notes: "tired"
        )
        try LogService.apply(input, defaultMode: .regular, context: context)
        try LogService.apply(input, defaultMode: .regular, context: context)

        let flows = try context.fetch(FetchDescriptor<FlowEntry>())
        let symptoms = try context.fetch(FetchDescriptor<SymptomEntry>())
        #expect(flows.count == 1)
        #expect(symptoms.count == 3) // cramps + fatigue + 1 note (.other)
    }

    @Test("Spotting alone does not start a new cycle")
    func spottingDoesNotStartCycle() throws {
        let context = try freshContext()
        let oldStart = day(daysFromNow: -28)
        let oldCycle = Cycle(startDate: oldStart, modeAtStart: .regular)
        context.insert(oldCycle)
        let oldFlow = FlowEntry(day: oldStart, intensity: .medium)
        oldFlow.cycle = oldCycle
        context.insert(oldFlow)
        try context.save()

        try LogService.apply(
            LogInput(date: day(daysFromNow: 0), flow: .spotting, symptoms: [:], notes: ""),
            defaultMode: .regular,
            context: context
        )

        let cycles = try context.fetch(FetchDescriptor<Cycle>())
        #expect(cycles.count == 1)
    }

    @Test("Reading currentLog returns the saved state with severities")
    func currentLogRoundTrips() throws {
        let context = try freshContext()
        let today = day(daysFromNow: 0)
        try LogService.apply(
            LogInput(
                date: today,
                flow: .medium,
                symptoms: [.cramps: .severe, .headache: .mild, .cravingChocolate: .mild],
                notes: "long day"
            ),
            defaultMode: .regular,
            context: context
        )

        let read = LogService.currentLog(forDay: today, context: context)
        #expect(read.flow == .medium)
        #expect(read.symptoms[.cramps] == .severe)
        #expect(read.symptoms[.headache] == .mild)
        #expect(read.symptoms[.cravingChocolate] == .mild)
        #expect(read.notes == "long day")
    }

    @Test("Cycling severity off removes the entry")
    func severityCycleOff() throws {
        let context = try freshContext()
        let today = day(daysFromNow: 0)
        try LogService.apply(
            LogInput(date: today, flow: nil, symptoms: [.cramps: .moderate], notes: ""),
            defaultMode: .regular,
            context: context
        )
        try LogService.apply(
            LogInput(date: today, flow: nil, symptoms: [:], notes: ""),
            defaultMode: .regular,
            context: context
        )
        let symptoms = try context.fetch(FetchDescriptor<SymptomEntry>())
        #expect(symptoms.isEmpty)
    }
}
