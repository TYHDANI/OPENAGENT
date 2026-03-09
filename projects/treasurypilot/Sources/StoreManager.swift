import StoreKit
import Foundation

@Observable
final class StoreManager {

    // MARK: - Product Identifiers

    static let professionalMonthlyID = "com.treasurypilot.subscription.professional.monthly"
    static let familyOfficeMonthlyID = "com.treasurypilot.subscription.familyoffice.monthly"
    static let enterpriseMonthlyID   = "com.treasurypilot.subscription.enterprise.monthly"

    static let allProductIDs: Set<String> = [
        professionalMonthlyID, familyOfficeMonthlyID, enterpriseMonthlyID
    ]

    // MARK: - State

    private(set) var products: [Product] = []
    private(set) var isSubscribed: Bool = false
    private(set) var activeSubscription: Product? = nil
    private(set) var currentTier: SubscriptionTier = .free
    private(set) var isPurchasing: Bool = false
    private(set) var errorMessage: String? = nil

    private var transactionListenerTask: Task<Void, Never>? = nil

    deinit { transactionListenerTask?.cancel() }

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
        var detectedTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            if transaction.revocationDate == nil {
                foundActive = true
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscription = product
                }
                switch transaction.productID {
                case Self.enterpriseMonthlyID:
                    detectedTier = .enterprise
                case Self.familyOfficeMonthlyID:
                    if detectedTier != .enterprise { detectedTier = .familyOffice }
                case Self.professionalMonthlyID:
                    if detectedTier == .free { detectedTier = .professional }
                default: break
                }
            }
        }

        isSubscribed = foundActive
        currentTier = detectedTier
        if !foundActive { activeSubscription = nil }
    }

    // MARK: - Restore

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

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }
}
