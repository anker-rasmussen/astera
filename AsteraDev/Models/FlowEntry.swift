import Foundation
import SwiftData

enum FlowIntensity: Int, Codable, CaseIterable {
    case spotting = 0
    case light = 1
    case medium = 2
    case heavy = 3
}

enum FlowSource: String, Codable {
    case manual
    case healthKit
}

@Model
final class FlowEntry {
    var id: UUID = UUID()
    var day: Date = Date()
    var intensityRaw: Int = FlowIntensity.medium.rawValue
    var sourceRaw: String = FlowSource.manual.rawValue
    var createdAt: Date = Date()

    var cycle: Cycle?

    var intensity: FlowIntensity {
        get { FlowIntensity(rawValue: intensityRaw) ?? .medium }
        set { intensityRaw = newValue.rawValue }
    }

    var source: FlowSource {
        get { FlowSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        day: Date = Date(),
        intensity: FlowIntensity = .medium,
        source: FlowSource = .manual,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.day = day
        self.intensityRaw = intensity.rawValue
        self.sourceRaw = source.rawValue
        self.createdAt = createdAt
    }
}
