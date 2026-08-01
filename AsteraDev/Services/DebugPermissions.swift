#if DEBUG
import Foundation
import UserNotifications

/// Launch-environment stubs for the three system permissions, so the end-to-end suite can drive
/// the denied paths. Compiled out of release builds entirely.
///
/// Guideline 5.1.1 is not about whether the permission dialog appears. It is about what the app
/// does when the answer is no: it has to stay usable, and it has to say how to change your mind.
/// Those are the parts a test can reach, and this is the seam that lets it.
///
/// What is stubbed, and what is not:
///
///   stubbed       the value the service's request call returns
///   still real    the branch `SettingsView` takes on that value, the `@AppStorage` write-back,
///                 the recovery copy, and whether the rest of the app keeps working
///   out of reach  the system permission dialog itself
///
/// The third line is why this exists rather than `simctl privacy`: that command has no service
/// for HealthKit or for notifications, so it can cover only one of the three, and covering one
/// permission differently from the other two costs more in confusion than it buys in fidelity.
///
/// Nothing here persists. These are process environment values, so unlike the `@AppStorage` keys
/// `DebugSeed.reset()` has to clear, a stub cannot leak into the next launch.
///
///     ASTERA_PERMISSION_CALENDAR=denied         granted | writeOnly | denied | restricted | notRequested
///     ASTERA_PERMISSION_HEALTH=denied           granted | denied | unavailable
///     ASTERA_PERMISSION_NOTIFICATIONS=denied    authorized | provisional | denied | notDetermined
enum DebugPermissions {

    /// Health has a third state that is neither granted nor denied: a device with no Health
    /// support at all, which hides the import section and disables the write toggle.
    enum Health: String {
        case granted, denied, unavailable
    }

    static var calendar: CalendarSyncService.AuthorizationState? {
        stub("ASTERA_PERMISSION_CALENDAR") {
            switch $0 {
            case "granted": return .granted
            case "writeOnly": return .writeOnly
            case "denied": return .denied
            case "restricted": return .restricted
            case "notRequested": return .notRequested
            default: return nil
            }
        }
    }

    static var health: Health? {
        stub("ASTERA_PERMISSION_HEALTH") { Health(rawValue: $0) }
    }

    static var notifications: UNAuthorizationStatus? {
        stub("ASTERA_PERMISSION_NOTIFICATIONS") {
            switch $0 {
            case "authorized": return .authorized
            case "provisional": return .provisional
            case "denied": return .denied
            case "notDetermined": return .notDetermined
            default: return nil
            }
        }
    }

    /// Unset means "use the real system". A value that does not parse is a typo in a test, and
    /// silently falling back to the real system would make that test pass for the wrong reason,
    /// so it trips an assertion instead.
    private static func stub<T>(_ key: String, _ parse: (String) -> T?) -> T? {
        guard let raw = ProcessInfo.processInfo.environment[key] else { return nil }
        guard let parsed = parse(raw) else {
            assertionFailure("\(key)=\(raw) is not a value this stub understands")
            return nil
        }
        return parsed
    }
}
#endif
