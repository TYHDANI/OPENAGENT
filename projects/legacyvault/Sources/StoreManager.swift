import StoreKit
import Foundation

@Observable
final class StoreManager {

    // MARK: - Product Identifiers (4-tier model)

    private static let bundleID = "com.openagent.legacyvault"

    static let guardianMonthlyID     = "\(bundleID).guardian.monthly"
    static let guardianYearlyID      = "\(bundleID).guardian.yearly"
    static let estateMonthlyID       = "\(bundleID).estate.monthly"
    static let estateYearlyID        = "\(bundleID).estate.yearly"
    static let familyOfficeMonthlyID = "\(bundleID).familyoffice.monthly"
    static let familyOfficeYearlyID  = "\(bundleID).familyoffice.yearly"

    // Legacy compat aliases
    static let monthlyID  = guardianMonthlyID
    static let yearlyID   = guardianYearlyID
    static let lifetimeID = "\(bundleID).lifetime"

    static let allProductIDs: Set<String> = [
        guardianMonthlyID, guardianYearlyID,
        estateMonthlyID, estateYearlyID,
        familyOfficeMonthlyID, familyOfficeYearlyID,
        lifetimeID
    ]

    // MARK: - Published State

    private(set) var products: [Product] = []
    private(set) var isSubscribed: Bool = false
    private(set) var activeSubscription: Product? = nil
    private(set) var activeTier: SubscriptionTier = .free
    private(set) var isPurchasing: Bool = false
    var errorMessage: String? = nil

    // MARK: - Private

    private var transactionListenerTask: Task<Void, Never>? = nil

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            products = storeProducts.sorted { $0.price < $1.price }
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkSubscriptionStatus()
                errorMessage = nil
                return true

            case .userCancelled:
                return false

            case .pending:
                errorMessage = "Purchase is pending approval."
                return false

            @unknown default:
                errorMessage = "Unknown purchase result."
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Subscription Status

    func checkSubscriptionStatus() async {
        var foundActive = false
        var highestTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            if transaction.revocationDate == nil {
                foundActive = true

                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscription = product
                }

                let tier = tierForProductID(transaction.productID)
                if tierRank(tier) > tierRank(highestTier) {
                    highestTier = tier
                }
            }
        }

        isSubscribed = foundActive
        activeTier = foundActive ? highestTier : .free

        if !foundActive {
            activeSubscription = nil
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Transaction Listener

    func listenForTransactions() {
        guard transactionListenerTask == nil else { return }

        transactionListenerTask = Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.checkSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }

    private func tierForProductID(_ productID: String) -> SubscriptionTier {
        if productID.contains("familyoffice") { return .familyOffice }
        if productID.contains("estate") { return .estate }
        if productID.contains("guardian") { return .guardian }
        if productID == Self.lifetimeID { return .estate }
        return .free
    }

    private func tierRank(_ tier: SubscriptionTier) -> Int {
        switch tier {
        case .free: return 0
        case .guardian: return 1
        case .estate: return 2
        case .familyOffice: return 3
        }
    }
}
