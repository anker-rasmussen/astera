import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var pronounsRaw: String = Pronouns.theyThem.rawValue
    var customPronouns: String?
    var salutationRaw: String = Salutation.none.rawValue
    var customSalutation: String?
    /// User's full custom greeting line, if they want to override the defaults. Takes precedence over `salutation`.
    var customGreeting: String?
    var relationshipStructureRaw: String = RelationshipStructure.single.rawValue
    var cycleModeRaw: String = CycleMode.notSure.rawValue
    var birthYear: Int = 1990
    var notificationPeriodInThreeDaysEnabled: Bool = true
    var notificationPeriodTodayEnabled: Bool = true
    var notificationOvulationWindowEnabled: Bool = false
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    var pronouns: Pronouns {
        get { Pronouns(rawValue: pronounsRaw) ?? .theyThem }
        set { pronounsRaw = newValue.rawValue }
    }

    var salutation: Salutation {
        get { Salutation(rawValue: salutationRaw) ?? .none }
        set { salutationRaw = newValue.rawValue }
    }

    var relationshipStructure: RelationshipStructure {
        get { RelationshipStructure(rawValue: relationshipStructureRaw) ?? .single }
        set { relationshipStructureRaw = newValue.rawValue }
    }

    var cycleMode: CycleMode {
        get { CycleMode(rawValue: cycleModeRaw) ?? .notSure }
        set { cycleModeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        pronouns: Pronouns = .theyThem,
        salutation: Salutation = .none,
        relationshipStructure: RelationshipStructure = .single,
        cycleMode: CycleMode = .notSure,
        birthYear: Int = 1990
    ) {
        self.id = id
        self.pronounsRaw = pronouns.rawValue
        self.salutationRaw = salutation.rawValue
        self.relationshipStructureRaw = relationshipStructure.rawValue
        self.cycleModeRaw = cycleMode.rawValue
        self.birthYear = birthYear
    }

    /// The warm greeting shown at the top of Home. Honors a user-typed `customGreeting` first,
    /// then falls back to a friendly default per salutation. Never assumes more than the user told us.
    var homeGreeting: String {
        if let custom = customGreeting?.trimmingCharacters(in: .whitespacesAndNewlines),
           !custom.isEmpty {
            return custom
        }
        switch salutation {
        case .none: return "Hello."
        case .person: return "Hey there."
        case .woman: return "Hey, lady."
        case .girl: return "Hey, girlie 🌸"
        case .custom:
            if let nick = customSalutation?.trimmingCharacters(in: .whitespacesAndNewlines),
               !nick.isEmpty {
                return "Hey, \(nick)."
            }
            return "Hello."
        }
    }
}
