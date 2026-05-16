import Foundation
import LocalAuthentication

enum AppLockService {
    enum BiometryKind: String {
        case faceID
        case touchID
        case opticID
        case passcodeOnly
        case unavailable

        var humanName: String {
            switch self {
            case .faceID: return "Face ID"
            case .touchID: return "Touch ID"
            case .opticID: return "Optic ID"
            case .passcodeOnly: return "your passcode"
            case .unavailable: return "lock"
            }
        }

        var verbose: String {
            switch self {
            case .faceID: return "Lock with Face ID"
            case .touchID: return "Lock with Touch ID"
            case .opticID: return "Lock with Optic ID"
            case .passcodeOnly: return "Lock with your passcode"
            case .unavailable: return "Lock (no biometrics on this device)"
            }
        }
    }

    /// What's available on this device.
    static var availableBiometry: BiometryKind {
        let context = LAContext()
        var error: NSError?
        // Probe biometrics first.
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID: return .faceID
            case .touchID: return .touchID
            case .opticID: return .opticID
            case .none: return .passcodeOnly
            @unknown default: return .passcodeOnly
            }
        }
        // No biometrics. Is a passcode set?
        var passcodeError: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &passcodeError) {
            return .passcodeOnly
        }
        return .unavailable
    }

    /// Returns true if the user successfully authenticated.
    /// If the device has no biometric AND no passcode set, returns true (don't lock the user out of their own app).
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use passcode"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return true
        }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
