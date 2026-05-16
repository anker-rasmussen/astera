import Foundation
import UserNotifications

enum NotificationCategory: String, CaseIterable, Identifiable {
    case periodInThreeDays = "astera.period.in.three.days"
    case periodToday = "astera.period.today"

    var id: String { rawValue }

    var humanTitle: String {
        switch self {
        case .periodInThreeDays: return "A few days out"
        case .periodToday: return "Around today"
        }
    }

    var previewBody: String {
        switch self {
        case .periodInThreeDays: return "Your period is likely in about three days."
        case .periodToday: return "Today is around when your period is expected."
        }
    }

    var explainer: String {
        switch self {
        case .periodInThreeDays: return "Sent once, three days before our best guess of your next period."
        case .periodToday: return "Sent on the morning of our best guess of your next period."
        }
    }
}

enum NotificationsService {
    static var notificationCenter: UNUserNotificationCenter { .current() }

    /// Asks for notification permission. Returns the resulting authorization state.
    @discardableResult
    static func requestAuthorization() async -> UNAuthorizationStatus {
        do {
            try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Settings will detect denial via the status check below.
        }
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    static func currentAuthorization() async -> UNAuthorizationStatus {
        await notificationCenter.notificationSettings().authorizationStatus
    }

    /// Reschedules notifications for the active categories.
    /// Cancels every Astera-owned pending notification first, so we always have at most one of each in flight.
    static func reschedule(prediction: PeriodPrediction, enabledCategories: Set<NotificationCategory>) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: NotificationCategory.allCases.map(\.rawValue))

        let status = await currentAuthorization()
        guard status == .authorized || status == .provisional else { return }

        let calendar = Calendar.current
        let now = Date()

        for category in enabledCategories {
            let fireDate: Date?
            let title: String
            let body: String

            switch category {
            case .periodInThreeDays:
                fireDate = calendar.date(byAdding: .day, value: -3, to: prediction.center)
                title = "A few days out"
                body = "Your period is likely in about three days. Slip a few things into your bag if that helps."
            case .periodToday:
                fireDate = prediction.center
                title = "Around today"
                body = "Today is around when your period is expected. We'll keep watching as you log."
            }

            guard let fireDate, fireDate > now else { continue }

            var dateComponents = calendar.dateComponents([.year, .month, .day], from: fireDate)
            dateComponents.hour = 9
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let request = UNNotificationRequest(identifier: category.rawValue, content: content, trigger: trigger)
            try? await notificationCenter.add(request)
        }
    }

    /// Removes all Astera-owned notifications, regardless of enabled state.
    static func clearAll() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: NotificationCategory.allCases.map(\.rawValue))
    }
}
