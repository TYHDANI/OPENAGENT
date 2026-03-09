import Foundation

struct PortfolioPosition: Identifiable, Codable, Hashable {
    let id: UUID
    let productID: String
    var productName: String
    var amountUSD: Double
    var entryDate: Date
    var notes: String

    init(productID: String, productName: String, amountUSD: Double, notes: String = "") {
        self.id = UUID()
        self.productID = productID
        self.productName = productName
        self.amountUSD = amountUSD
        self.entryDate = Date()
        self.notes = notes
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amountUSD)) ?? "$\(amountUSD)"
    }
}

struct PortfolioSummary {
    let totalValue: Double
    let weightedRiskScore: Double
    let positionCount: Int
    let concentrationWarnings: [ConcentrationWarning]
    let riskDistribution: [RiskLevel: Double]

    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalValue)) ?? "$\(totalValue)"
    }
}

struct ConcentrationWarning: Identifiable, Hashable {
    let id = UUID()
    let productName: String
    let percentage: Double
    let message: String
}

struct RebalanceSuggestion: Identifiable {
    let id = UUID()
    let productName: String
    let currentAllocation: Double
    let suggestedAllocation: Double
    let reason: String
}
