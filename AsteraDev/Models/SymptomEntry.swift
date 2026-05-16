import Foundation
import SwiftData

enum SymptomCategory: String, Codable, CaseIterable {
    // Physical & emotional symptoms (carry severity)
    case cramps
    case mood
    case headache
    case bloating
    case backache
    case breastTenderness
    case acne
    case fatigue
    case nausea
    case discharge
    case libido
    case sleep
    case dizziness
    case hotFlashes
    case brainFog
    case anxiety
    case irritability
    case oilySkin
    case drySkin
    case hairGreasy

    // Positive states (carry severity = how much)
    case happy
    case energetic
    case calm
    case glowingSkin

    // Sexual activity (age-gated; also user-toggleable)
    case painfulSex
    case sex
    case sexProtected

    // Cravings (binary, no severity)
    case cravingSweet
    case cravingSalty
    case cravingChocolate
    case cravingCarbs
    case cravingSavory
    case appetiteLow

    // Misc / lifestyle (binary, no severity)
    case exercise
    case alcohol
    case caffeine
    case travel
    case illness
    case medication
    case stress

    // Reserved for free-form notes attached to a day.
    case other
}

enum SymptomKind {
    case symptom
    case craving
    case misc
}

enum SymptomSeverity: Int, Codable {
    case mild = 1
    case moderate = 2
    case severe = 3
}

@Model
final class SymptomEntry {
    var id: UUID = UUID()
    var day: Date = Date()
    var categoryRaw: String = SymptomCategory.other.rawValue
    var severityRaw: Int = SymptomSeverity.mild.rawValue
    var notes: String?
    var createdAt: Date = Date()

    var cycle: Cycle?

    var category: SymptomCategory {
        get { SymptomCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var severity: SymptomSeverity {
        get { SymptomSeverity(rawValue: severityRaw) ?? .mild }
        set { severityRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        day: Date = Date(),
        category: SymptomCategory = .other,
        severity: SymptomSeverity = .mild,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.day = day
        self.categoryRaw = category.rawValue
        self.severityRaw = severity.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }
}
