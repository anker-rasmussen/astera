import Foundation
import SwiftData

@Model
final class Cycle {
    var id: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date?
    var notes: String?
    var modeAtStartRaw: String = CycleMode.regular.rawValue
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \FlowEntry.cycle)
    var flowEntries: [FlowEntry]? = []

    @Relationship(deleteRule: .cascade, inverse: \SymptomEntry.cycle)
    var symptomEntries: [SymptomEntry]? = []

    var modeAtStart: CycleMode {
        get { CycleMode(rawValue: modeAtStartRaw) ?? .regular }
        set { modeAtStartRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        notes: String? = nil,
        modeAtStart: CycleMode = .regular,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.modeAtStartRaw = modeAtStart.rawValue
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
