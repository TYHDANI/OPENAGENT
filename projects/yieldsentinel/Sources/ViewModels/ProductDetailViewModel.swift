import Foundation

@Observable
final class ProductDetailViewModel {

    // MARK: - State

    private(set) var product: YieldProduct
    private(set) var riskFactors: [RiskFactor] = []
    private(set) var isLoading = false

    // MARK: - Init

    init(product: YieldProduct) {
        self.product = product
        computeRiskFactors()
    }

    // MARK: - Risk Factor Computation

    func computeRiskFactors() {
        let (_, factors) = ScoringEngine.computeScore(for: product)
        riskFactors = factors.sorted { $0.weightedScore < $1.weightedScore }
    }

    // MARK: - Computed Properties

    var topRisks: [RiskFactor] {
        riskFactors.filter { $0.status == .danger || $0.status == .warning }
    }

    var strengths: [RiskFactor] {
        riskFactors.filter { $0.status == .good }
    }

    var scoreBreakdown: [(label: String, value: String)] {
        [
            ("Sentinel Score", "\(product.sentinelScore)/100"),
            ("Risk Level", product.riskLevel.rawValue),
            ("Category", product.category.rawValue),
            ("Chain", product.chain),
            ("Current APY", product.formattedAPY),
            ("TVL", product.formattedTVL),
            ("TVL 7d Change", String(format: "%+.1f%%", product.tvl7dChange)),
            ("TVL 30d Change", String(format: "%+.1f%%", product.tvl30dChange)),
            ("Audit Status", product.auditStatus.rawValue),
            ("Team", product.teamTransparency.rawValue),
            ("Regulatory", product.regulatoryStatus.rawValue),
            ("Withdrawal", product.withdrawalTime.rawValue),
            ("Bridge Risk", product.bridgeDependency.rawValue),
            ("Liquidity", product.liquidityDepth.rawValue),
            ("Whale Concentration", String(format: "%.0f%%", product.whaleConcentration * 100))
        ]
    }

    var collateralInfo: String? {
        guard let ratio = product.collateralRatio else { return nil }
        return String(format: "%.0f%%", ratio * 100)
    }

    var insuranceInfo: String? {
        guard let coverage = product.insuranceCoverage else { return nil }
        if coverage >= 1_000_000_000 {
            return String(format: "$%.1fB", coverage / 1_000_000_000)
        } else if coverage >= 1_000_000 {
            return String(format: "$%.1fM", coverage / 1_000_000)
        }
        return String(format: "$%.0fK", coverage / 1_000)
    }

    // MARK: - Refresh

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        let dataService = DeFiDataService()
        if let updated = try? await dataService.fetchProductDetail(id: product.id) {
            product = updated
            computeRiskFactors()
        }
    }
}
