import Foundation
import Testing
import SwiftData
@testable import Astera

@Suite("SwiftData schema sanity")
struct AsteraDevTests {
    @Test("ModelContainer initializes with all @Model types")
    func containerInitsInMemory() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        #expect(container.schema.entities.count == 5)
    }

    @Test("Cycle round-trips through ModelContext")
    @MainActor
    func cyclePersists() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let cycle = Cycle(startDate: Date(timeIntervalSince1970: 1_700_000_000), modeAtStart: .regular)
        context.insert(cycle)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Cycle>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.modeAtStart == .regular)
    }
}
