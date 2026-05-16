import Foundation
import SwiftData

struct LogInput: Equatable {
    var date: Date
    var flow: FlowIntensity?
    /// Maps each logged category to its severity. For cravings and misc categories
    /// severity is stored as `.mild` and ignored by the UI.
    var symptoms: [SymptomCategory: SymptomSeverity]
    var notes: String

    static func empty(on date: Date = Date()) -> LogInput {
        LogInput(date: date, flow: nil, symptoms: [:], notes: "")
    }

    var hasAnyContent: Bool {
        flow != nil || !symptoms.isEmpty || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum LogService {
    static let newCycleGapDays = 14

    /// Apply the log input to the store. Returns the cycle today's data was attached to.
    @discardableResult
    static func apply(_ input: LogInput, defaultMode: CycleMode, context: ModelContext) throws -> Cycle? {
        let day = Calendar.current.startOfDay(for: input.date)

        let cycle = try targetCycle(forDay: day, flow: input.flow, defaultMode: defaultMode, context: context)
        try upsertFlowEntry(day: day, intensity: input.flow, cycle: cycle, context: context)
        try replaceSymptomsAndNotes(day: day, symptoms: input.symptoms, notes: input.notes, cycle: cycle, context: context)

        try context.save()
        return cycle
    }

    /// Read the current log for a given day back out of the store.
    static func currentLog(forDay date: Date, context: ModelContext) -> LogInput {
        let day = Calendar.current.startOfDay(for: date)

        var flow: FlowIntensity?
        if let entries = try? context.fetch(FetchDescriptor<FlowEntry>()) {
            let match = entries.first { Calendar.current.isDate($0.day, inSameDayAs: day) }
            flow = match?.intensity
        }

        var symptoms: [SymptomCategory: SymptomSeverity] = [:]
        var notes = ""
        if let entries = try? context.fetch(FetchDescriptor<SymptomEntry>()) {
            for entry in entries where Calendar.current.isDate(entry.day, inSameDayAs: day) {
                if entry.category == .other, let text = entry.notes, !text.isEmpty {
                    notes = text
                } else {
                    symptoms[entry.category] = entry.severity
                }
            }
        }

        return LogInput(date: day, flow: flow, symptoms: symptoms, notes: notes)
    }

    // MARK: - Internals

    static func targetCycle(
        forDay day: Date,
        flow: FlowIntensity?,
        defaultMode: CycleMode,
        context: ModelContext
    ) throws -> Cycle? {
        let cycles = try context.fetch(FetchDescriptor<Cycle>(sortBy: [SortDescriptor(\.startDate, order: .reverse)]))

        if isNewPeriodStart(on: day, flow: flow, in: context) {
            if let existing = cycles.first(where: { Calendar.current.isDate($0.startDate, inSameDayAs: day) }) {
                return existing
            }
            let new = Cycle(startDate: day, modeAtStart: defaultMode)
            context.insert(new)
            return new
        }

        if let containing = cycles.first(where: { $0.startDate <= day }) {
            return containing
        }

        if let flow, flow.rawValue >= FlowIntensity.light.rawValue {
            let new = Cycle(startDate: day, modeAtStart: defaultMode)
            context.insert(new)
            return new
        }

        return nil
    }

    static func isNewPeriodStart(on day: Date, flow: FlowIntensity?, in context: ModelContext) -> Bool {
        guard let flow, flow.rawValue >= FlowIntensity.light.rawValue else { return false }
        let cycles = (try? context.fetch(FetchDescriptor<Cycle>(sortBy: [SortDescriptor(\.startDate, order: .reverse)]))) ?? []

        guard let mostRecent = cycles.first(where: { $0.startDate < day }) else {
            return true
        }
        let recentBleedDays = (mostRecent.flowEntries ?? [])
            .filter { $0.day < day && $0.intensity.rawValue >= FlowIntensity.light.rawValue }
            .map { Calendar.current.startOfDay(for: $0.day) }
        let referenceDay = recentBleedDays.max() ?? Calendar.current.startOfDay(for: mostRecent.startDate)
        let gap = Calendar.current.dateComponents([.day], from: referenceDay, to: day).day ?? 0
        return gap >= newCycleGapDays
    }

    private static func upsertFlowEntry(day: Date, intensity: FlowIntensity?, cycle: Cycle?, context: ModelContext) throws {
        let entries = try context.fetch(FetchDescriptor<FlowEntry>())
        let existing = entries.first { Calendar.current.isDate($0.day, inSameDayAs: day) }

        if let intensity {
            if let existing {
                existing.intensity = intensity
                existing.cycle = cycle
            } else {
                let entry = FlowEntry(day: day, intensity: intensity, source: .manual)
                entry.cycle = cycle
                context.insert(entry)
            }
        } else if let existing {
            context.delete(existing)
        }
    }

    private static func replaceSymptomsAndNotes(
        day: Date,
        symptoms: [SymptomCategory: SymptomSeverity],
        notes: String,
        cycle: Cycle?,
        context: ModelContext
    ) throws {
        let existing = try context.fetch(FetchDescriptor<SymptomEntry>())
            .filter { Calendar.current.isDate($0.day, inSameDayAs: day) }

        for entry in existing {
            context.delete(entry)
        }

        for (category, severity) in symptoms {
            let entry = SymptomEntry(day: day, category: category, severity: severity)
            entry.cycle = cycle
            context.insert(entry)
        }

        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let noteEntry = SymptomEntry(day: day, category: .other, severity: .mild, notes: trimmed)
            noteEntry.cycle = cycle
            context.insert(noteEntry)
        }
    }
}

extension FlowIntensity {
    var lowercaseName: String {
        switch self {
        case .spotting: return "spotting"
        case .light: return "light"
        case .medium: return "medium"
        case .heavy: return "heavy"
        }
    }
}

extension SymptomCategory {
    var lowercaseName: String {
        switch self {
        case .cramps: return "cramps"
        case .mood: return "mood"
        case .headache: return "headache"
        case .bloating: return "bloating"
        case .backache: return "backache"
        case .breastTenderness: return "breast tenderness"
        case .acne: return "acne"
        case .fatigue: return "fatigue"
        case .nausea: return "nausea"
        case .discharge: return "discharge"
        case .libido: return "libido"
        case .sleep: return "sleep changes"
        case .dizziness: return "dizziness"
        case .hotFlashes: return "hot flashes"
        case .brainFog: return "brain fog"
        case .anxiety: return "anxiety"
        case .irritability: return "irritability"
        case .oilySkin: return "oily skin"
        case .drySkin: return "dry skin"
        case .hairGreasy: return "greasy hair"

        case .happy: return "happy"
        case .energetic: return "energetic"
        case .calm: return "calm"
        case .glowingSkin: return "glowing skin"

        case .painfulSex: return "painful sex"
        case .sex: return "sex"
        case .sexProtected: return "protected sex"

        case .cravingSweet: return "sweet"
        case .cravingSalty: return "salty"
        case .cravingChocolate: return "chocolate"
        case .cravingCarbs: return "carbs"
        case .cravingSavory: return "savory"
        case .appetiteLow: return "low appetite"

        case .exercise: return "exercise"
        case .alcohol: return "alcohol"
        case .caffeine: return "caffeine"
        case .travel: return "travel"
        case .illness: return "illness"
        case .medication: return "medication"
        case .stress: return "stress"

        case .other: return "other"
        }
    }

    var kind: SymptomKind {
        switch self {
        case .cramps, .mood, .headache, .bloating, .backache, .breastTenderness, .acne,
             .fatigue, .nausea, .discharge, .libido, .sleep, .dizziness, .hotFlashes,
             .brainFog, .anxiety, .irritability, .oilySkin, .drySkin, .hairGreasy,
             .happy, .energetic, .calm, .glowingSkin, .painfulSex:
            return .symptom
        case .cravingSweet, .cravingSalty, .cravingChocolate, .cravingCarbs, .cravingSavory, .appetiteLow:
            return .craving
        case .sex, .sexProtected, .exercise, .alcohol, .caffeine, .travel, .illness, .medication, .stress:
            return .misc
        case .other:
            return .misc
        }
    }

    /// Categories the UI must hide for teens, and that adults can toggle off in settings.
    var isSexualActivity: Bool {
        switch self {
        case .painfulSex, .sex, .sexProtected: return true
        default: return false
        }
    }

    /// Symptom chips, ordered: hardware-style symptoms, then mind, then skin/hair, then positive states.
    static var symptoms: [SymptomCategory] {
        [.cramps, .headache, .bloating, .backache, .breastTenderness, .acne,
         .fatigue, .nausea, .discharge, .libido, .sleep, .dizziness, .hotFlashes,
         .oilySkin, .drySkin, .hairGreasy,
         .mood, .brainFog, .anxiety, .irritability,
         .happy, .energetic, .calm, .glowingSkin,
         .painfulSex]
    }

    static var cravings: [SymptomCategory] {
        [.cravingSweet, .cravingSalty, .cravingChocolate, .cravingCarbs, .cravingSavory, .appetiteLow]
    }

    static var miscellaneous: [SymptomCategory] {
        [.sex, .sexProtected, .exercise, .alcohol, .caffeine, .travel, .illness, .medication, .stress]
    }

    /// All user-loggable categories (excludes `.other`, which is the free-form notes carrier).
    static var loggable: [SymptomCategory] {
        symptoms + cravings + miscellaneous
    }
}
