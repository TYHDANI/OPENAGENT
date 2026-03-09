import Foundation
import SwiftUI

@Observable
@MainActor
final class TransactionViewModel {
    var transactions: [CryptoTransaction] = []
    var taxLots: [TaxLot] = []
    var errorMessage: String?
    var isLoading = false

    // Filters
    var filterEntityID: UUID?
    var filterAsset: String?
    var filterType: TransactionType?
    var filterStartDate: Date?
    var filterEndDate: Date?

    private let persistence = PersistenceService.shared

    var filteredTransactions: [CryptoTransaction] {
        transactions.filter { tx in
            if let entityID = filterEntityID, tx.entityID != entityID { return false }
            if let asset = filterAsset, tx.asset != asset { return false }
            if let type = filterType, tx.transactionType != type { return false }
            if let start = filterStartDate, tx.date < start { return false }
            if let end = filterEndDate, tx.date > end { return false }
            return true
        }
        .sorted { $0.date > $1.date }
    }

    var uniqueAssets: [String] {
        Array(Set(transactions.map(\.asset))).sorted()
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            transactions = try await persistence.loadTransactions()
            taxLots = try await persistence.loadTaxLots()
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
    }

    func addTransaction(_ transaction: CryptoTransaction, entities: [LegalEntity]) async {
        transactions.append(transaction)

        // Create tax lot for buys/income
        if let lot = TaxLotEngine.createTaxLot(from: transaction) {
            taxLots.append(lot)
        }

        // Process sales: dispose lots per entity's cost-basis method
        if transaction.transactionType == .sell {
            if let entity = entities.first(where: { $0.id == transaction.entityID }) {
                let newDisposed = TaxLotEngine.processSale(
                    transaction: transaction,
                    lots: &taxLots,
                    method: entity.costBasisMethod
                )
                taxLots.append(contentsOf: newDisposed)
            }
        }

        await saveAll()
    }

    func deleteTransaction(_ transaction: CryptoTransaction) async {
        transactions.removeAll { $0.id == transaction.id }
        taxLots.removeAll { $0.acquisitionTransactionID == transaction.id }
        await saveAll()
    }

    func totalValue(for entityID: UUID?) -> Double {
        let filtered = entityID == nil ? taxLots : taxLots.filter { $0.entityID == entityID }
        return filtered.filter { !$0.isDisposed }.reduce(0) { $0 + $1.totalCostBasis }
    }

    private func saveAll() async {
        do {
            try await persistence.saveTransactions(transactions)
            try await persistence.saveTaxLots(taxLots)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
