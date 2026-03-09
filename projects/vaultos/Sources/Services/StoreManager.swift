import Foundation
import StoreKit

@Observable
final class StoreManager {
    var currentTier: SubscriptionTier = .free
    var availableProducts: [Product] = []
    var purchasedProductIDs: Set<String> = []

    private let productIDs = ["com.vaultos.pro.monthly", "com.vaultos.family.monthly"]

    init() {
        Task { await loadProducts(); await updatePurchaseStatus() }
    }

    func loadProducts() async {
        do {
            availableProducts = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updatePurchaseStatus()
            return transaction
        case .userCancelled, .pending: return nil
        @unknown default: return nil
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await updatePurchaseStatus()
    }

    private func updatePurchaseStatus() async {
        var purchased: Set<String> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }
        purchasedProductIDs = purchased
        if purchased.contains("com.vaultos.family.monthly") { currentTier = .family }
        else if purchased.contains("com.vaultos.pro.monthly") { currentTier = .pro }
        else { currentTier = .free }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.unverified
        case .verified(let value): return value
        }
    }

    enum StoreError: Error { case unverified }
}
