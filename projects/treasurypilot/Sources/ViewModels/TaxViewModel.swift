import Foundation
import SwiftUI

@Observable
@MainActor
final class TaxViewModel {
    var quarterlyEstimates: [QuarterlyEstimate] = []
    var washSaleAlerts: [WashSaleAlert] = []
    var errorMessage: String?
    var isLoading = false
    var selectedTaxYear: Int = Calendar.current.component(.year, from: Date())

    private let persistence = PersistenceService.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            quarterlyEstimates = try await persistence.loadQuarterlyEstimates()
            washSaleAlerts = try await persistence.loadWashSaleAlerts()
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
    }

    func calculateEstimates(entities: [LegalEntity], lots: [TaxLot]) async {
        isLoading = true
        defer { isLoading = false }

        var allEstimates: [QuarterlyEstimate] = []
        for entity in entities {
            let estimates = QuarterlyTaxCalculator.calculateAllQuarters(
                entityID: entity.id,
                taxYear: selectedTaxYear,
                lots: lots
            )
            allEstimates.append(contentsOf: estimates)
        }

        // Replace estimates for the selected year
        quarterlyEstimates.removeAll { $0.taxYear == selectedTaxYear }
        quarterlyEstimates.append(contentsOf: allEstimates)

        do {
            try await persistence.saveQuarterlyEstimates(quarterlyEstimates)
        } catch {
            errorMessage = "Failed to save estimates: \(error.localizedDescription)"
        }
    }

    func detectWashSales(
        transactions: [CryptoTransaction],
        lots: [TaxLot],
        entities: [LegalEntity]
    ) async {
        isLoading = true
        defer { isLoading = false }

        var allAlerts: [WashSaleAlert] = []
        for entity in entities {
            let relatedIDs = WashSaleDetector.relatedEntityIDs(for: entity.id, entities: entities)
            let alerts = WashSaleDetector.detect(
                transactions: transactions,
                lots: lots,
                relatedEntityIDs: relatedIDs
            )
            allAlerts.append(contentsOf: alerts)
        }

        // Deduplicate by sale+buy transaction pair
        var seen = Set<String>()
        washSaleAlerts = allAlerts.filter { alert in
            let key = "\(alert.saleTransactionID)-\(alert.buyTransactionID)"
            return seen.insert(key).inserted
        }

        do {
            try await persistence.saveWashSaleAlerts(washSaleAlerts)
        } catch {
            errorMessage = "Failed to save alerts: \(error.localizedDescription)"
        }
    }

    func estimates(for entityID: UUID) -> [QuarterlyEstimate] {
        quarterlyEstimates
            .filter { $0.entityID == entityID && $0.taxYear == selectedTaxYear }
            .sorted { $0.quarter.rawValue < $1.quarter.rawValue }
    }

    func alerts(for entityID: UUID) -> [WashSaleAlert] {
        washSaleAlerts.filter { $0.saleEntityID == entityID || $0.buyEntityID == entityID }
    }

    func totalEstimatedTax(for entityID: UUID?) -> Double {
        let filtered = entityID == nil
            ? quarterlyEstimates.filter { $0.taxYear == selectedTaxYear }
            : quarterlyEstimates.filter { $0.entityID == entityID && $0.taxYear == selectedTaxYear }
        return filtered.reduce(0) { $0 + $1.estimatedTaxOwed }
    }
}
