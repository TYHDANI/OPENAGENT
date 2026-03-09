import StoreKit
import Foundation

/// Manages all StoreKit 2 interactions: product loading, purchasing,
/// transaction verification, and subscription status tracking.
@Observable
final class StoreManager {

    // MARK: - Product Identifiers

    /// Product identifiers for YieldSentinel subscription tiers.
    static let analystMonthlyID     = "com.yieldsentinel.analyst.monthly"
    static let analystYearlyID      = "com.yieldsentinel.analyst.yearly"
    static let professionalMonthlyID = "com.yieldsentinel.professional.monthly"
    static let professionalYearlyID  = "com.yieldsentinel.professional.yearly"

    static let allProductIDs: Set<String> = [
        analystMonthlyID, analystYearlyID,
        professionalMonthlyID, professionalYearlyID
    ]

    // MARK: - Published State

    /// All fetched StoreKit products.
    private(set) var products: [Product] = []

    /// Whether the user currently has an active subscription or lifetime purchase.
    private(set) var isSubscribed: Bool = false

    /// The currently active subscription product, if any.
    private(set) var activeSubscription: Product? = nil

    /// The user's current subscription tier.
    private(set) var currentTier: SubscriptionTier = .free

    /// Set while a purchase is in progress.
    private(set) var isPurchasing: Bool = false

    /// User-facing error message from the last failed operation.
    private(set) var errorMessage: String? = nil

    // MARK: - Private

    /// Handle for the background transaction listener task.
    private var transactionListenerTask: Task<Void, Never>? = nil

    // MARK: - Lifecycle

    deinit {
        transactionListenerTask?.cancel()
    }

    // MARK: - Load Products

    /// Fetches the configured products from the App Store.
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            // Sort so monthly < yearly < lifetime for display order.
            products = storeProducts.sorted { $0.price < $1.price }
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    /// Initiates a purchase for the given product.
    /// - Returns: `true` if the purchase succeeded and entitlement was granted.
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

    /// Checks all current entitlements and updates `isSubscribed`.
    func checkSubscriptionStatus() async {
        var foundActive = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            if transaction.revocationDate == nil {
                foundActive = true

                // Track which product is the active subscription.
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscription = product
                }
            }
        }

        isSubscribed = foundActive
        if !foundActive {
            activeSubscription = nil
            currentTier = .free
        } else if let active = activeSubscription {
            if active.id.contains("professional") {
                currentTier = .professional
            } else if active.id.contains("analyst") {
                currentTier = .analyst
            } else {
                currentTier = .analyst
            }
        }
    }

    // MARK: - Restore Purchases

    /// Syncs transactions with the App Store to restore previous purchases.
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Transaction Listener

    /// Listens for transactions that complete outside the app
    /// (e.g., Ask to Buy, subscription renewals, refunds).
    func listenForTransactions() {
        // Avoid duplicate listeners.
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

    /// Unwraps a verified transaction or throws on verification failure.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
