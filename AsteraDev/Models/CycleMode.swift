import Foundation

enum CycleMode: String, Codable, CaseIterable, Identifiable {
    case regular
    case irregular
    case pcos
    case endometriosis
    case iud
    case hormonalBC
    case perimenopause
    case surgicalMenopause
    case pregnant
    case postLoss
    case ttc
    case postpartum
    case trackingOnT
    case notSure

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .regular: return "Regular"
        case .irregular: return "Irregular"
        case .pcos: return "PCOS"
        case .endometriosis: return "Endometriosis"
        case .iud: return "IUD"
        case .hormonalBC: return "Hormonal birth control"
        case .perimenopause: return "Perimenopause"
        case .surgicalMenopause: return "Surgical menopause"
        case .pregnant: return "Pregnant"
        case .postLoss: return "After loss"
        case .ttc: return "Trying to conceive"
        case .postpartum: return "Postpartum"
        case .trackingOnT: return "Tracking on T"
        case .notSure: return "Not sure"
        }
    }

    /// True when this mode should produce period predictions, calendar events, and reminders.
    /// False for modes where forecasting a bleed makes no sense or could be harmful.
    var shouldPredictPeriods: Bool {
        switch self {
        case .pregnant, .postLoss, .postpartum, .surgicalMenopause, .trackingOnT:
            return false
        default:
            return true
        }
    }

    /// True when the home tab should switch to the quiet variant (no forecasts, gentle copy, log-when-ready).
    /// Pregnancy is its own home tab; the quiet home covers loss, postpartum, surgical menopause, and tracking on T.
    var usesQuietHome: Bool {
        switch self {
        case .postLoss, .postpartum, .surgicalMenopause, .trackingOnT:
            return true
        default:
            return false
        }
    }
}

enum Pronouns: String, Codable, CaseIterable, Identifiable {
    case sheHer
    case heHim
    case theyThem
    case custom

    var id: String { rawValue }
}

enum Salutation: String, Codable, CaseIterable, Identifiable {
    case none
    case girl
    case woman
    case person
    case custom

    var id: String { rawValue }
}

enum RelationshipStructure: String, Codable, CaseIterable, Identifiable {
    case single
    case partneredTracking
    case partneredNotTracking
    case polyamorous

    var id: String { rawValue }
}
