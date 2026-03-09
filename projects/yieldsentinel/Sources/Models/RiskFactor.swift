import Foundation

struct RiskFactor: Identifiable, Codable, Hashable {
    let id: String
    let type: RiskFactorType
    let name: String
    let description: String
    let weight: Double
    let rawValue: Double // 0-100 (higher = safer)
    let weightedScore: Double // weight * rawValue
    let status: FactorStatus

    init(type: RiskFactorType, rawValue: Double, weight: Double) {
        self.id = type.rawValue
        self.type = type
        self.name = type.displayName
        self.description = type.description
        self.weight = weight
        self.rawValue = rawValue
        self.weightedScore = weight * rawValue
        self.status = FactorStatus.from(score: rawValue)
    }
}

enum RiskFactorType: String, Codable, CaseIterable, Hashable {
    case tvlTrend
    case collateralRatio
    case reserveProof
    case auditRecency
    case contractAge
    case teamDoxxing
    case insuranceCoverage
    case withdrawalTime
    case regulatoryStatus
    case apyVolatility
    case bridgeDependency
    case socialSentiment
    case peerComparison
    case liquidityDepth
    case whaleConcentration

    var displayName: String {
        switch self {
        case .tvlTrend: return "TVL Trend"
        case .collateralRatio: return "Collateral Ratio"
        case .reserveProof: return "Reserve Proof"
        case .auditRecency: return "Audit Status"
        case .contractAge: return "Contract Maturity"
        case .teamDoxxing: return "Team Transparency"
        case .insuranceCoverage: return "Insurance"
        case .withdrawalTime: return "Withdrawal Speed"
        case .regulatoryStatus: return "Regulatory Status"
        case .apyVolatility: return "APY Stability"
        case .bridgeDependency: return "Bridge Risk"
        case .socialSentiment: return "Social Sentiment"
        case .peerComparison: return "Peer Ranking"
        case .liquidityDepth: return "Liquidity Depth"
        case .whaleConcentration: return "Whale Risk"
        }
    }

    var description: String {
        switch self {
        case .tvlTrend: return "7-day and 30-day TVL velocity. Declining TVL often precedes instability."
        case .collateralRatio: return "On-chain collateral backing ratio. Below 100% indicates undercollateralization risk."
        case .reserveProof: return "Cross-referenced proof of reserves from independent audit reports."
        case .auditRecency: return "Recency and status of smart contract security audits."
        case .contractAge: return "Age and update frequency of deployed smart contracts. Older, stable contracts score higher."
        case .teamDoxxing: return "Public identity verification of the protocol team. Doxxed teams are more accountable."
        case .insuranceCoverage: return "Insurance coverage amount relative to TVL. Higher coverage reduces risk."
        case .withdrawalTime: return "Time to process withdrawals. Instant is safest; delays may signal liquidity issues."
        case .regulatoryStatus: return "Regulatory standing across key jurisdictions (US, EU, Asia)."
        case .apyVolatility: return "Historical volatility of advertised APY. Stable yields indicate sustainable economics."
        case .bridgeDependency: return "Dependency on cross-chain bridges. Single-bridge dependency is a concentration risk."
        case .socialSentiment: return "Aggregate sentiment from Reddit, Twitter, and community channels."
        case .peerComparison: return "Score relative to similar products in the same category."
        case .liquidityDepth: return "How easily funds can exit the protocol without significant slippage."
        case .whaleConcentration: return "Percentage of TVL held by top 10 addresses. High concentration increases exit risk."
        }
    }

    var systemImage: String {
        switch self {
        case .tvlTrend: return "chart.line.uptrend.xyaxis"
        case .collateralRatio: return "shield.checkered"
        case .reserveProof: return "doc.text.magnifyingglass"
        case .auditRecency: return "checkmark.seal"
        case .contractAge: return "clock.badge.checkmark"
        case .teamDoxxing: return "person.badge.shield.checkmark"
        case .insuranceCoverage: return "umbrella"
        case .withdrawalTime: return "arrow.down.to.line"
        case .regulatoryStatus: return "building.columns"
        case .apyVolatility: return "waveform.path.ecg"
        case .bridgeDependency: return "link.badge.plus"
        case .socialSentiment: return "bubble.left.and.bubble.right"
        case .peerComparison: return "list.number"
        case .liquidityDepth: return "water.waves"
        case .whaleConcentration: return "chart.pie"
        }
    }
}

enum FactorStatus: String, Codable, Hashable {
    case good = "Good"
    case fair = "Fair"
    case warning = "Warning"
    case danger = "Danger"

    static func from(score: Double) -> FactorStatus {
        switch score {
        case 75...100: return .good
        case 50..<75: return .fair
        case 25..<50: return .warning
        default: return .danger
        }
    }
}
