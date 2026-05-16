import SwiftUI

enum CyclePhase: String, CaseIterable {
    case menstrual
    case follicular
    case ovulation
    case luteal

    var name: String {
        switch self {
        case .menstrual: return "menstrual"
        case .follicular: return "follicular"
        case .ovulation: return "ovulation"
        case .luteal: return "luteal"
        }
    }

    var color: Color {
        switch self {
        case .menstrual: return AsteraColor.accent     // mulberry
        case .follicular: return AsteraColor.sage      // soft green-grey
        case .ovulation: return AsteraColor.gold       // warm honey
        case .luteal: return AsteraColor.dustyRose     // soft warm rose
        }
    }

    /// Phase for a given cycle day (1-indexed) in a cycle of `length` days.
    /// Luteal phase is fixed at ~14 days (well-established physiology) so ovulation moves with cycle length.
    static func phase(forDay day: Int, in length: Int = 28) -> CyclePhase {
        if day <= 5 { return .menstrual }
        let ovulationDay = max(10, length - 14)
        if day < ovulationDay - 1 { return .follicular }
        if day <= ovulationDay + 1 { return .ovulation }
        return .luteal
    }
}
