import Foundation
import Observation

enum OnboardingStep: Int, CaseIterable, Identifiable, Comparable {
    case welcome
    case pronouns
    case salutation
    case relationship
    case cycleMode
    case privacy
    case cycleBasics
    case firstPrediction

    var id: Int { rawValue }
    var stepNumber: Int { rawValue + 1 }
    static let totalCount = OnboardingStep.allCases.count

    static func < (lhs: OnboardingStep, rhs: OnboardingStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var next: OnboardingStep? {
        OnboardingStep(rawValue: rawValue + 1)
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: rawValue - 1)
    }
}

@Observable
final class OnboardingDraft {
    var pronouns: Pronouns = .theyThem
    var customPronouns: String = ""

    var salutation: Salutation = .none
    var customSalutation: String = ""
    var customGreeting: String = ""

    var relationshipStructure: RelationshipStructure = .single

    var cycleMode: CycleMode = .notSure

    var useAppLock: Bool = false

    var lastPeriodStart: Date? = nil
    var typicalCycleLength: Int = 28
    var cycleLengthKnown: Bool = false
    var birthYear: Int = Calendar.current.component(.year, from: Date()) - 28

    init() {}
}
