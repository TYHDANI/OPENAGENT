import Foundation
import StoreKit
import SwiftUI

// MARK: - Store Manager

@Observable
final class StoreManager {
    // MARK: Product IDs
    static let proYearlyID = "com.terrasurvive.pro.yearly"
    static let lifetimeID = "com.terrasurvive.expedition.lifetime"

    // MARK: State
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading: Bool = false
    var errorMessage: String? = nil

    var currentTier: SubscriptionTier {
        if purchasedProductIDs.contains(Self.lifetimeID) {
            return .lifetime
        } else if purchasedProductIDs.contains(Self.proYearlyID) {
            return .pro
        } else {
            return .free
        }
    }

    var isPro: Bool {
        currentTier == .pro || currentTier == .lifetime
    }

    var proYearlyProduct: Product? {
        products.first { $0.id == Self.proYearlyID }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == Self.lifetimeID }
    }

    // MARK: Init

    init() {
        Task { await listenForTransactions() }
        Task { await loadProducts() }
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs: Set<String> = [Self.proYearlyID, Self.lifetimeID]
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                return true

            case .userCancelled:
                return false

            case .pending:
                errorMessage = "Purchase is pending approval."
                return false

            @unknown default:
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
