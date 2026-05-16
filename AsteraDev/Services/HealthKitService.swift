import Foundation
import HealthKit

enum HealthKitService {
    private static let store = HKHealthStore()

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    static var menstrualFlowType: HKCategoryType {
        HKCategoryType(.menstrualFlow)
    }

    static var hasWriteAuthorization: Bool {
        guard isAvailable else { return false }
        return store.authorizationStatus(for: menstrualFlowType) == .sharingAuthorized
    }

    /// Asks for read + write access on menstrualFlow.
    /// Returns true if we have *any* permission (Apple won't tell us read-only status by design).
    @discardableResult
    static func requestAccess() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(
                toShare: [menstrualFlowType],
                read: [menstrualFlowType]
            )
        } catch {
            return false
        }
        return store.authorizationStatus(for: menstrualFlowType) != .notDetermined
    }

    /// Writes (or rewrites) a menstrualFlow sample for the given day.
    /// Deletes any prior Astera-sourced sample on the same day first, so re-logging stays idempotent.
    /// Passes `nil` or `.spotting` to mean "no menstrualFlow for that day"; existing Astera samples on that day are removed.
    static func writeFlow(intensity: FlowIntensity?, on day: Date, isCycleStart: Bool) async throws {
        guard isAvailable else { return }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return }

        try await deleteOurSamples(start: start, end: end)

        guard let intensity, let value = healthKitValue(for: intensity) else { return }

        let sample = HKCategorySample(
            type: menstrualFlowType,
            value: value,
            start: start,
            end: end,
            metadata: [HKMetadataKeyMenstrualCycleStart: isCycleStart]
        )
        try await store.save(sample)
    }

    /// Maps Astera flow intensity to a HealthKit value, abstracting the iOS 17 vs 18 API split.
    /// iOS 18 introduces `HKCategoryValueVaginalBleeding`; iOS 17 still uses `HKCategoryValueMenstrualFlow`.
    /// We can use the integer raw values directly, which are identical between the two enums for the values we care about.
    private static func healthKitValue(for intensity: FlowIntensity) -> Int? {
        switch intensity {
        case .spotting: return nil // HealthKit's separate intermenstrualBleeding type, out of v1 scope.
        case .light: return HKCategoryValueMenstrualFlow.light.rawValue
        case .medium: return HKCategoryValueMenstrualFlow.medium.rawValue
        case .heavy: return HKCategoryValueMenstrualFlow.heavy.rawValue
        }
    }

    /// A simplified menstrual flow sample for import: which day, how intense, whether the
    /// source app marked it as a cycle start, and the originating source name (e.g. "Flo", "Clue").
    struct MenstrualSample {
        let day: Date
        let intensity: FlowIntensity
        let isCycleStart: Bool
        let sourceName: String
    }

    /// Fetches every menstrual flow sample HealthKit has, mapped to Astera intensities.
    /// Excludes samples Astera itself wrote (to avoid round-trip duplication when re-importing).
    static func fetchMenstrualHistory() async throws -> [MenstrualSample] {
        guard isAvailable else { return [] }
        let ourBundleID = Bundle.main.bundleIdentifier ?? ""
        let samples: [HKSample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: menstrualFlowType,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }

        return samples.compactMap { sample in
            guard let category = sample as? HKCategorySample else { return nil }
            if category.sourceRevision.source.bundleIdentifier == ourBundleID { return nil }
            guard let intensity = flowIntensity(forHealthKitValue: category.value) else { return nil }
            let isStart = (category.metadata?[HKMetadataKeyMenstrualCycleStart] as? Bool) ?? false
            return MenstrualSample(
                day: Calendar.current.startOfDay(for: category.startDate),
                intensity: intensity,
                isCycleStart: isStart,
                sourceName: category.sourceRevision.source.name
            )
        }
    }

    /// Maps a HealthKit menstrualFlow raw value back to Astera's intensity.
    /// Returns nil for `.unspecified` and `.none` (we don't import those as bleeding days).
    private static func flowIntensity(forHealthKitValue value: Int) -> FlowIntensity? {
        switch value {
        case HKCategoryValueMenstrualFlow.light.rawValue: return .light
        case HKCategoryValueMenstrualFlow.medium.rawValue: return .medium
        case HKCategoryValueMenstrualFlow.heavy.rawValue: return .heavy
        default: return nil
        }
    }

    private static func deleteOurSamples(start: Date, end: Date) async throws {
        let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sourcePredicate = HKQuery.predicateForObjects(from: HKSource.default())
        let combined = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, sourcePredicate])

        let samples: [HKSample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: menstrualFlowType,
                predicate: combined,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }

        guard !samples.isEmpty else { return }
        try await store.delete(samples)
    }
}
