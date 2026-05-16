import SwiftUI
import SwiftData

@main
struct AsteraDevApp: App {
    let modelContainer: ModelContainer = {
        do {
            return try PersistenceController.makeContainer()
        } catch {
            // CloudKit init failed (account missing, container unreachable, schema mismatch, etc.).
            // Fall back to local-only so the app never crashes on launch; sync resumes when CloudKit recovers.
            if let local = try? PersistenceController.makeLocalOnlyContainer() {
                NSLog("AsteraDev: CloudKit container failed, falling back to local-only. Error: \(error)")
                return local
            }
            fatalError("Failed to create ModelContainer (both cloud and local failed): \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
