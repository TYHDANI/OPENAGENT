import Foundation

enum RiskFactorType: String, Codable, CaseIterable {
    case tvlTrend, collateralRatio, reserveProof, auditRecency, contractAge
    case teamTransparency, insuranceCoverage, withdrawalTime, regulatoryStatus
    case apyVolatility, bridgeDependency, socialSentiment, peerComparison
    case liquidityDepth, whaleConcentration

    var label: String {
        switch self {
        case .tvlTrend: "TVL Trend"
        case .collateralRatio: "Collateral Ratio"
        case .reserveProof: "Reserve Proof"
        case .auditRecency: "Audit Recency"
        case .contractAge: "Contract Age"
        case .teamTransparency: "Team Transparency"
        case .insuranceCoverage: "Insurance Coverage"
        case .withdrawalTime: "Withdrawal Time"
        case .regulatoryStatus: "Regulatory Status"
        case .apyVolatility: "APY Volatility"
        case .bridgeDependency: "Bridge Dependency"
        case .socialSentiment: "Social Sentiment"
        case .peerComparison: "Peer Comparison"
        case .liquidityDepth: "Liquidity Depth"
        case .whaleConcentration: "Whale Concentration"
        }
    }

    var weight: Double {
        switch self {
        case .tvlTrend: 0.12; case .collateralRatio: 0.12; case .reserveProof: 0.08
        case .auditRecency: 0.08; case .contractAge: 0.06; case .teamTransparency: 0.07
        case .insuranceCoverage: 0.05; case .withdrawalTime: 0.08; case .regulatoryStatus: 0.06
        case .apyVolatility: 0.07; case .bridgeDependency: 0.04; case .socialSentiment: 0.04
        case .peerComparison: 0.03; case .liquidityDepth: 0.06; case .whaleConcentration: 0.04
        }
    }
}

struct RiskFactor: Identifiable, Codable {
    let id: UUID
    var type: RiskFactorType
    var score: Int
    var detail: String
    init(id: UUID = UUID(), type: RiskFactorType, score: Int, detail: String = "") {
        self.id = id; self.type = type; self.score = score; self.detail = detail
    }
}
