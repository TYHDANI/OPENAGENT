import Foundation

@Observable
final class PortfolioViewModel {

    // MARK: - State

    private(set) var positions: [PortfolioPosition] = []
    private(set) var summary: PortfolioSummary?
    private(set) var rebalanceSuggestions: [RebalanceSuggestion] = []

    var showingAddPosition = false

    // Form state for adding positions
    var newProductID = ""
    var newProductName = ""
    var newAmountText = ""
    var newNotes = ""

    // MARK: - Dependencies

    private let persistence = PersistenceService.shared

    // MARK: - Load

    func loadPositions(products: [YieldProduct]) {
        positions = persistence.loadPortfolio()
        computeSummary(products: products)
        computeRebalanceSuggestions(products: products)
    }

    // MARK: - Add Position

    func addPosition(productID: String, productName: String, amount: Double, notes: String) {
        let position = PortfolioPosition(
            productID: productID,
            productName: productName,
            amountUSD: amount,
            notes: notes
        )
        positions.append(position)
        persistence.savePortfolio(positions)
    }

    func addPositionFromForm() {
        guard let amount = Double(newAmountText), amount > 0 else { return }
        addPosition(
            productID: newProductID,
            productName: newProductName,
            amount: amount,
            notes: newNotes
        )
        resetForm()
    }

    func removePosition(_ id: UUID) {
        positions.removeAll { $0.id == id }
        persistence.savePortfolio(positions)
    }

    func updateAmount(positionID: UUID, newAmount: Double) {
        guard let index = positions.firstIndex(where: { $0.id == positionID }) else { return }
        positions[index].amountUSD = newAmount
        persistence.savePortfolio(positions)
    }

    // MARK: - Summary Computation

    func computeSummary(products: [YieldProduct]) {
        let totalValue = positions.reduce(0.0) { $0 + $1.amountUSD }
        guard totalValue > 0 else {
            summary = PortfolioSummary(
                totalValue: 0, weightedRiskScore: 0,
                positionCount: 0, concentrationWarnings: [],
                riskDistribution: [:]
            )
            return
        }

        var weightedScore = 0.0
        var riskDist: [RiskLevel: Double] = [:]
        var warnings: [ConcentrationWarning] = []

        for position in positions {
            let weight = position.amountUSD / totalValue
            let percentage = weight * 100

            if let product = products.first(where: { $0.id == position.productID }) {
                weightedScore += Double(product.sentinelScore) * weight
                riskDist[product.riskLevel, default: 0] += position.amountUSD

                // Concentration warning if > 40% in one product
                if percentage > 40 {
                    warnings.append(ConcentrationWarning(
                        productName: position.productName,
                        percentage: percentage,
                        message: "\(Int(percentage))% concentrated in \(position.productName). Consider diversifying."
                    ))
                }

                // Warning for high-risk products with significant allocation
                if product.riskLevel == .high || product.riskLevel == .critical {
                    if percentage > 15 {
                        warnings.append(ConcentrationWarning(
                            productName: position.productName,
                            percentage: percentage,
                            message: "\(Int(percentage))% in high-risk \(position.productName) (Score: \(product.sentinelScore))."
                        ))
                    }
                }
            }
        }

        summary = PortfolioSummary(
            totalValue: totalValue,
            weightedRiskScore: weightedScore,
            positionCount: positions.count,
            concentrationWarnings: warnings,
            riskDistribution: riskDist
        )
    }

    // MARK: - Rebalance Suggestions

    func computeRebalanceSuggestions(products: [YieldProduct]) {
        guard !positions.isEmpty else {
            rebalanceSuggestions = []
            return
        }

        let totalValue = positions.reduce(0.0) { $0 + $1.amountUSD }
        guard totalValue > 0 else { return }

        var suggestions: [RebalanceSuggestion] = []

        for position in positions {
            let allocation = position.amountUSD / totalValue

            if let product = products.first(where: { $0.id == position.productID }) {
                // Suggest reducing allocation in critical/high risk products
                if (product.riskLevel == .critical || product.riskLevel == .high) && allocation > 0.1 {
                    suggestions.append(RebalanceSuggestion(
                        productName: position.productName,
                        currentAllocation: allocation * 100,
                        suggestedAllocation: 5,
                        reason: "High risk (Score: \(product.sentinelScore)). Reduce exposure."
                    ))
                }

                // Suggest increasing allocation in low-risk products with good APY
                if product.riskLevel == .low && allocation < 0.2 && product.currentAPY > 3.0 {
                    suggestions.append(RebalanceSuggestion(
                        productName: position.productName,
                        currentAllocation: allocation * 100,
                        suggestedAllocation: 25,
                        reason: "Low risk with \(product.formattedAPY) APY. Consider increasing."
                    ))
                }
            }
        }

        rebalanceSuggestions = suggestions
    }

    // MARK: - Helpers

    private func resetForm() {
        newProductID = ""
        newProductName = ""
        newAmountText = ""
        newNotes = ""
        showingAddPosition = false
    }
}
