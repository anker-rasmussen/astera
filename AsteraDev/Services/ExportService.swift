import Foundation
import SwiftData

enum ExportService {
    static let schemaVersion = 1

    struct Export: Codable {
        let schemaVersion: Int
        let exportedAt: Date
        let profile: ProfileSnapshot?
        let cycles: [CycleSnapshot]
    }

    struct ProfileSnapshot: Codable {
        let pronouns: String
        let customPronouns: String?
        let salutation: String
        let customSalutation: String?
        let relationshipStructure: String
        let cycleMode: String
        let birthYear: Int
    }

    struct CycleSnapshot: Codable {
        let id: UUID
        let startDate: Date
        let endDate: Date?
        let notes: String?
        let modeAtStart: String
        let flowEntries: [FlowSnapshot]
        let symptomEntries: [SymptomSnapshot]
    }

    struct FlowSnapshot: Codable {
        let day: Date
        let intensity: String
        let source: String
    }

    struct SymptomSnapshot: Codable {
        let day: Date
        let category: String
        let severity: Int
        let notes: String?
    }

    /// Builds an Export snapshot on the main actor.
    @MainActor
    static func buildExport(context: ModelContext) throws -> Export {
        let profile = try context.fetch(FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])).first
        let cycles = try context.fetch(FetchDescriptor<Cycle>(sortBy: [SortDescriptor(\.startDate)]))

        let profileSnapshot = profile.map { p in
            ProfileSnapshot(
                pronouns: p.pronouns.rawValue,
                customPronouns: p.customPronouns,
                salutation: p.salutation.rawValue,
                customSalutation: p.customSalutation,
                relationshipStructure: p.relationshipStructure.rawValue,
                cycleMode: p.cycleMode.rawValue,
                birthYear: p.birthYear
            )
        }

        let cycleSnapshots = cycles.map { cycle in
            CycleSnapshot(
                id: cycle.id,
                startDate: cycle.startDate,
                endDate: cycle.endDate,
                notes: cycle.notes,
                modeAtStart: cycle.modeAtStart.rawValue,
                flowEntries: (cycle.flowEntries ?? []).map { f in
                    FlowSnapshot(day: f.day, intensity: f.intensity.lowercaseName, source: f.source.rawValue)
                }.sorted { $0.day < $1.day },
                symptomEntries: (cycle.symptomEntries ?? []).map { s in
                    SymptomSnapshot(day: s.day, category: s.category.rawValue, severity: s.severity.rawValue, notes: s.notes)
                }.sorted { $0.day < $1.day }
            )
        }

        return Export(
            schemaVersion: schemaVersion,
            exportedAt: Date(),
            profile: profileSnapshot,
            cycles: cycleSnapshots
        )
    }

    /// Encodes an Export to a JSON file on disk and returns its URL for sharing.
    static func writeToTempFile(_ export: Export) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(export)

        let fileName = "astera-export-\(ISO8601DateFormatter().string(from: export.exportedAt).prefix(10)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(String(fileName))
        try data.write(to: url, options: [.atomic])
        return url
    }
}

extension FlowSource {
    var name: String { rawValue }
}
