import Foundation
import SwiftData

enum EraseService {
    /// Wipes every Astera entity from the local store and resets every AppStorage flag.
    /// Calendar events and scheduled notifications are cleared separately so a failure in one doesn't block the rest.
    @MainActor
    static func eraseEverything(context: ModelContext) async {
        // SwiftData: delete all entities of each type, then save.
        deleteAll(of: SymptomEntry.self, in: context)
        deleteAll(of: FlowEntry.self, in: context)
        deleteAll(of: PredictionSnapshot.self, in: context)
        deleteAll(of: Cycle.self, in: context)
        deleteAll(of: UserProfile.self, in: context)
        try? context.save()

        // AppStorage flags: clear every key we know about.
        let defaults = UserDefaults.standard
        for key in AppStorageKey.allKnown {
            defaults.removeObject(forKey: key.rawValue)
        }

        // External side-effects.
        try? CalendarSyncService.clearEvents()
        NotificationsService.clearAll()
    }

    private static func deleteAll<T: PersistentModel>(of type: T.Type, in context: ModelContext) {
        guard let all = try? context.fetch(FetchDescriptor<T>()) else { return }
        for item in all { context.delete(item) }
    }
}

extension AppStorageKey {
    static var allKnown: [AppStorageKey] {
        [
            .hasCompletedOnboarding,
            .requiresAppLock,
            .showInCalendar,
            .syncToHealth,
            .notifyPeriodInThreeDays,
            .notifyPeriodToday
        ]
    }
}
