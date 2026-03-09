import Foundation

// MARK: - Core Product Model

struct YieldProduct: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var protocol_: String
    var category: ProductCategory
    var chain: String
    var currentAPY: Double
    var tvl: Double
    var tvl7dChange: Double
    var tvl30dChange: Double
    var sentinelScore: Int
    var previousScore: Int?
    var riskLevel: RiskLevel
    var collateralRatio: Double?
    var auditStatus: AuditStatus
    var teamTransparency: TeamTransparency
    var regulatoryStatus: RegulatoryStatus
    var insuranceCoverage: Double?
    var withdrawalTime: WithdrawalTime
    var bridgeDependency: BridgeDependency
    var whaleConcentration: Double
    var liquidityDepth: LiquidityDepth
    var apyVolatility: Double
    var contractAge: Int // days
    var contractUpdateFrequency: Int // updates per year
    var socialSentiment: SocialSentiment
    var lastUpdated: Date
    var historicalScores: [HistoricalScore]
    var logoSystemImage: String

    enum CodingKeys: String, CodingKey {
        case id, name, category, chain, currentAPY, tvl, tvl7dChange, tvl30dChange
        case sentinelScore, previousScore, riskLevel, collateralRatio, auditStatus
        case teamTransparency, regulatoryStatus, insuranceCoverage, withdrawalTime
        case bridgeDependency, whaleConcentration, liquidityDepth, apyVolatility
        case contractAge, contractUpdateFrequency, socialSentiment, lastUpdated
        case historicalScores, logoSystemImage
        case protocol_ = "protocol"
    }

    var scoreChange: Int {
        guard let prev = previousScore else { return 0 }
        return sentinelScore - prev
    }

    var formattedTVL: String {
        if tvl >= 1_000_000_000 {
            return String(format: "$%.1fB", tvl / 1_000_000_000)
        } else if tvl >= 1_000_000 {
            return String(format: "$%.1fM", tvl / 1_000_000)
        } else if tvl >= 1_000 {
            return String(format: "$%.0fK", tvl / 1_000)
        }
        return String(format: "$%.0f", tvl)
    }

    var formattedAPY: String {
        String(format: "%.1f%%", currentAPY)
    }
}

// MARK: - Historical Score

struct HistoricalScore: Identifiable, Codable, Hashable {
    var id: Date { date }
    let date: Date
    let score: Int
}

// MARK: - Enums

enum ProductCategory: String, Codable, CaseIterable, Hashable {
    case lending = "Lending"
    case staking = "Staking"
    case liquidStaking = "Liquid Staking"
    case yieldAggregator = "Yield Aggregator"
    case dex = "DEX"
    case bridge = "Bridge"
    case restaking = "Restaking"
    case cdp = "CDP"

    var systemImage: String {
        switch self {
        case .lending: return "banknote"
        case .staking: return "lock.shield"
        case .liquidStaking: return "drop.fill"
        case .yieldAggregator: return "arrow.triangle.merge"
        case .dex: return "arrow.left.arrow.right"
        case .bridge: return "link"
        case .restaking: return "arrow.counterclockwise"
        case .cdp: return "dollarsign.circle"
        }
    }
}

enum RiskLevel: String, Codable, CaseIterable, Hashable {
    case low = "Low"
    case moderate = "Moderate"
    case elevated = "Elevated"
    case high = "High"
    case critical = "Critical"

    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .moderate: return 1
        case .elevated: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
}

enum AuditStatus: String, Codable, Hashable {
    case fresh = "Fresh"
    case stale = "Stale"
    case failed = "Failed"
    case none = "None"
}

enum TeamTransparency: String, Codable, Hashable {
    case fullyDoxxed = "Fully Doxxed"
    case partiallyDoxxed = "Partially Doxxed"
    case anonymous = "Anonymous"
}

enum RegulatoryStatus: String, Codable, Hashable {
    case approved = "Approved"
    case registered = "Registered"
    case unregistered = "Unregistered"
    case banned = "Banned"
    case unknown = "Unknown"
}

enum WithdrawalTime: String, Codable, Hashable {
    case instant = "Instant"
    case sameDay = "Same Day"
    case oneToThreeDays = "1-3 Days"
    case threePlusDays = "3+ Days"
    case locked = "Locked"
}

enum BridgeDependency: String, Codable, Hashable {
    case none = "None"
    case single = "Single Bridge"
    case multiple = "Multiple Bridges"
}

enum LiquidityDepth: String, Codable, Hashable {
    case deep = "Deep"
    case moderate = "Moderate"
    case shallow = "Shallow"
    case illiquid = "Illiquid"
}

enum SocialSentiment: String, Codable, Hashable {
    case positive = "Positive"
    case neutral = "Neutral"
    case cautious = "Cautious"
    case negative = "Negative"
}
