import Foundation
import StoreKit

/// Astera+, the optional support tier described in spec §10.
/// The tracker is free forever; this exists for people who want to chip in. The service must never
/// induce its own UI; only Settings → Astera+ may surface it.
@MainActor
@Observable
final class AsteraPlusService {
    static let shared = AsteraPlusService()

    enum Tier: String, CaseIterable, Identifiable {
        case monthly = "com.anker.astera.plus.monthly"
        case yearly = "com.anker.astera.plus.yearly"
        case lifetime = "com.anker.astera.plus.lifetime"

        var id: String { rawValue }
    }

    enum RestoreOutcome: Equatable {
        case idle
        case restoring
        case restoredWithPurchases
        case nothingToRestore
        case failed(String)
    }

    var products: [Product] = []
    private(set) var hasAsteraPlus: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var lastError: String?
    private(set) var restoreOutcome: RestoreOutcome = .idle

    private var updateListener: Task<Void, Never>?

    init() {
        updateListener = Task { [weak self] in
            await self?.listenForUpdates()
        }
        Task { await refresh() }
    }

    /// Fetches product metadata + the user's current entitlements.
    func refresh() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let fetched = try await Product.products(for: Tier.allCases.map(\.rawValue))
            products = fetched.sorted { lhs, rhs in
                // monthly < yearly < lifetime
                func order(_ id: String) -> Int {
                    Tier.allCases.firstIndex(where: { $0.rawValue == id }) ?? Int.max
                }
                return order(lhs.id) < order(rhs.id)
            }
        } catch {
            lastError = "Couldn't load support options. Try again later."
        }

        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        let allowedIDs = Set(Tier.allCases.map(\.rawValue))
        var owns = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               allowedIDs.contains(transaction.productID) {
                owns = true
                break
            }
        }
        hasAsteraPlus = owns
    }

    /// Returns true on a successful purchase, false otherwise. Cancellation and pending are treated as benign.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    return true
                }
                return false
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = "The purchase didn't go through. \(error.localizedDescription)"
            return false
        }
    }

    /// Triggers Apple's restore flow. On a real device or in TestFlight Sandbox this prompts
    /// the user for their Apple ID password (or Face ID) to verify the request.
    /// In the simulator with a local .storekit config the prompt is suppressed by Apple by design.
    func restore() async {
        restoreOutcome = .restoring
        do {
            try await AppStore.sync()
        } catch {
            let message = "Couldn't reach Apple's servers. Check your connection and try again."
            lastError = message
            restoreOutcome = .failed(message)
            return
        }
        await refreshEntitlements()
        restoreOutcome = hasAsteraPlus ? .restoredWithPurchases : .nothingToRestore
    }

    /// Clears the outcome message after the user has seen it (e.g. when they tap away).
    func acknowledgeRestoreOutcome() {
        restoreOutcome = .idle
    }

    private func listenForUpdates() async {
        for await update in Transaction.updates {
            if case .verified(let transaction) = update {
                await transaction.finish()
                await refreshEntitlements()
            }
        }
    }
}

extension Product {
    /// Human-friendly title for a tier ("Monthly · £3", "Yearly · £20", "Lifetime · £60").
    var asteraTierTitle: String {
        switch id {
        case AsteraPlusService.Tier.monthly.rawValue: return "Monthly"
        case AsteraPlusService.Tier.yearly.rawValue: return "Yearly"
        case AsteraPlusService.Tier.lifetime.rawValue: return "Lifetime"
        default: return displayName
        }
    }

    var asteraTierDescription: String {
        switch id {
        case AsteraPlusService.Tier.monthly.rawValue:
            return "\(displayPrice) a month. Cancel any time, from the App Store."
        case AsteraPlusService.Tier.yearly.rawValue:
            return "\(displayPrice) a year. About 17% cheaper than paying monthly."
        case AsteraPlusService.Tier.lifetime.rawValue:
            return "\(displayPrice) once. Astera+ for as long as the app exists. No renewals."
        default: return displayPrice
        }
    }
}
