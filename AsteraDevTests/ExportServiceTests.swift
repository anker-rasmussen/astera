import Foundation
import Testing
import SwiftData
@testable import Astera

@Suite("Export service")
struct ExportServiceTests {
    @Test("Export produces valid JSON with cycles, flow, symptoms")
    @MainActor
    func roundTripsThroughJSON() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext

        let profile = UserProfile(
            pronouns: .theyThem,
            salutation: .none,
            relationshipStructure: .single,
            cycleMode: .regular,
            birthYear: 1995
        )
        context.insert(profile)

        let cycle = Cycle(startDate: Date(timeIntervalSince1970: 1_700_000_000), modeAtStart: .regular)
        context.insert(cycle)

        let flow = FlowEntry(day: cycle.startDate, intensity: .medium, source: .manual)
        flow.cycle = cycle
        context.insert(flow)

        let symptom = SymptomEntry(day: cycle.startDate, category: .cramps, severity: .mild, notes: nil)
        symptom.cycle = cycle
        context.insert(symptom)
        try context.save()

        let export = try ExportService.buildExport(context: context)
        #expect(export.schemaVersion == 1)
        #expect(export.profile?.pronouns == "theyThem")
        #expect(export.cycles.count == 1)
        #expect(export.cycles.first?.flowEntries.count == 1)
        #expect(export.cycles.first?.symptomEntries.count == 1)

        // Verify it serializes and re-parses.
        let url = try ExportService.writeToTempFile(export)
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ExportService.Export.self, from: data)
        #expect(decoded.cycles.count == 1)
        #expect(decoded.cycles.first?.modeAtStart == "regular")
    }
}

@Suite("Erase service")
struct EraseServiceTests {
    @Test("Erase wipes everything")
    @MainActor
    func wipesAll() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext

        context.insert(UserProfile(pronouns: .theyThem, salutation: .none, relationshipStructure: .single, cycleMode: .regular, birthYear: 1995))
        let cycle = Cycle(startDate: Date(), modeAtStart: .regular)
        context.insert(cycle)
        context.insert({
            let f = FlowEntry(day: Date(), intensity: .medium); f.cycle = cycle; return f
        }())
        context.insert({
            let s = SymptomEntry(day: Date(), category: .cramps); s.cycle = cycle; return s
        }())
        try context.save()

        await EraseService.eraseEverything(context: context)

        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        let cycles = try context.fetch(FetchDescriptor<Cycle>())
        let flow = try context.fetch(FetchDescriptor<FlowEntry>())
        let symptoms = try context.fetch(FetchDescriptor<SymptomEntry>())
        #expect(profiles.isEmpty)
        #expect(cycles.isEmpty)
        #expect(flow.isEmpty)
        #expect(symptoms.isEmpty)
    }
}
