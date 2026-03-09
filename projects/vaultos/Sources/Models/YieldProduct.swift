import Foundation
import SwiftUI

enum ProductCategory: String, Codable, CaseIterable {
    case lending = "Lending"
    case staking = "Staking"
    case liquidStaking = "Liquid Staking"
    case yieldAggregator = "Yield Aggregator"
    case dex = "DEX"
    case bridge = "Bridge"
    case restaking = "Restaking"
    case cdp = "CDP"
}

enum RiskLevel: String, Codable {
    case low, moderate, elevated, high, critical
    var color: Color {
        switch self {
        case .low: AppColors.success
        case .moderate: .yellow
        case .elevated: .orange
        case .high: AppColors.danger
        case .critical: AppColors.danger
        }
    }
    var label: String { rawValue.capitalized }
}

struct YieldProduct: Identifiable, Codable {
    let id: UUID
    var name: String
    var chain: String
    var category: ProductCategory
    var apy: Double
    var tvl: Double
    var tvlChange7d: Double
    var tvlChange30d: Double
    var collateralRatio: Double
    var sentinelScore: Int
    var riskLevel: RiskLevel
    var riskFactors: [RiskFactor]
    var isFavorited: Bool

    init(id: UUID = UUID(), name: String, chain: String, category: ProductCategory,
         apy: Double, tvl: Double, tvlChange7d: Double = 0, tvlChange30d: Double = 0,
         collateralRatio: Double = 1.0, sentinelScore: Int = 50, riskFactors: [RiskFactor] = [],
         isFavorited: Bool = false) {
        self.id = id; self.name = name; self.chain = chain; self.category = category
        self.apy = apy; self.tvl = tvl; self.tvlChange7d = tvlChange7d; self.tvlChange30d = tvlChange30d
        self.collateralRatio = collateralRatio; self.sentinelScore = sentinelScore
        self.riskLevel = Self.riskLevelFor(score: sentinelScore)
        self.riskFactors = riskFactors; self.isFavorited = isFavorited
    }

    static func riskLevelFor(score: Int) -> RiskLevel {
        switch score {
        case 75...100: .low
        case 55...74: .moderate
        case 40...54: .elevated
        case 20...39: .high
        default: .critical
        }
    }
}
