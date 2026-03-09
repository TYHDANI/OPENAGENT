import Foundation

@Observable
final class TaxCenterViewModel {
    var transactions: [CryptoTransaction] = []
    var taxLots: [TaxLot] = []
    var washSaleAlerts: [WashSaleAlert] = []
    var quarterlyEstimates: [QuarterlyEstimate] = []
    var selectedEntityID: UUID?
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    var costBasisStrategy: CostBasisStrategy = .fifo

    var filteredLots: [TaxLot] {
        var result = taxLots
        if let eid = selectedEntityID { result = result.filter { $0.entityID == eid } }
        return result.sorted { $0.acquisitionDate > $1.acquisitionDate }
    }

    var disposedLots: [TaxLot] { filteredLots.filter { $0.isDisposed } }

    var totalRealizedGains: Double { disposedLots.compactMap { $0.gainLoss }.reduce(0, +) }
    var shortTermGains: Double {
        disposedLots.filter { $0.holdingPeriod == .shortTerm }.compactMap { $0.gainLoss }.reduce(0, +)
    }
    var longTermGains: Double {
        disposedLots.filter { $0.holdingPeriod == .longTerm }.compactMap { $0.gainLoss }.reduce(0, +)
    }
    var unrealizedGains: Double { filteredLots.filter { !$0.isDisposed }.count > 0 ? 0 : 0 } // Needs market prices

    var activeWashSales: [WashSaleAlert] { washSaleAlerts.filter { !$0.isResolved } }
    var totalDisallowedLoss: Double { activeWashSales.reduce(0) { $0 + $1.disallowedLoss } }

    func load(from persistence: PersistenceService, entities: [LegalEntity]) {
        transactions = persistence.transactions
        taxLots = persistence.taxLots
        if selectedEntityID == nil { selectedEntityID = entities.first?.id }
        runWashSaleDetection(entities: entities)
    }

    func runWashSaleDetection(entities: [LegalEntity]) {
        washSaleAlerts = WashSaleDetector.detect(transactions: transactions, entities: entities)
    }

    func calculateQuarterly(entityID: UUID, quarter: Quarter) {
        let estimate = QuarterlyTaxCalculator.calculate(
            transactions: transactions, lots: taxLots,
            entityID: entityID, taxYear: selectedYear, quarter: quarter
        )
        quarterlyEstimates.append(estimate)
    }
}
