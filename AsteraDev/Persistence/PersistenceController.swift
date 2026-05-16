import Foundation
import SwiftData

enum PersistenceController {
    static let schema = Schema([
        Cycle.self,
        FlowEntry.self,
        SymptomEntry.self,
        PredictionSnapshot.self,
        UserProfile.self,
    ])

    static let cloudKitContainerIdentifier = "iCloud.com.anker.astera"

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        } else {
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Used as a fallback if the CloudKit-backed container fails to initialise.
    /// SwiftData is then local-only; existing cloud data is left untouched and will pick up next launch.
    static func makeLocalOnlyContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
