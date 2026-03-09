import Foundation

struct ScoringEngine {
    static func computeSentinelScore(factors: [RiskFactor]) -> Int {
        guard !factors.isEmpty else { return 50 }
        let weighted = factors.reduce(0.0) { sum, f in
            sum + Double(f.score) * f.type.weight
        }
        let totalWeight = factors.map { $0.type.weight }.reduce(0, +)
        guard totalWeight > 0 else { return 50 }
        return min(100, max(0, Int(weighted / totalWeight)))
    }

    static func generateFactors(for product: YieldProduct) -> [RiskFactor] {
        var factors: [RiskFactor] = []

        // TVL Trend
        let tvlScore: Int
        if product.tvlChange30d > 10 { tvlScore = 85 }
        else if product.tvlChange30d > 0 { tvlScore = 70 }
        else if product.tvlChange30d > -10 { tvlScore = 50 }
        else { tvlScore = 25 }
        factors.append(RiskFactor(type: .tvlTrend, score: tvlScore, detail: "\(String(format: "%.1f", product.tvlChange30d))% 30d change"))

        // Collateral Ratio
        let crScore = product.collateralRatio >= 1.5 ? 90 :
                       product.collateralRatio >= 1.1 ? 70 :
                       product.collateralRatio >= 1.0 ? 50 : 20
        factors.append(RiskFactor(type: .collateralRatio, score: crScore, detail: "\(String(format: "%.0f", product.collateralRatio * 100))%"))

        // APY Volatility — high APY = higher risk
        let apyScore = product.apy < 5 ? 85 : product.apy < 15 ? 65 : product.apy < 30 ? 40 : 15
        factors.append(RiskFactor(type: .apyVolatility, score: apyScore, detail: "\(String(format: "%.1f", product.apy))% APY"))

        // Contract Age (simulated)
        factors.append(RiskFactor(type: .contractAge, score: 60, detail: "Simulated"))
        factors.append(RiskFactor(type: .auditRecency, score: 65, detail: "Simulated"))
        factors.append(RiskFactor(type: .teamTransparency, score: 55, detail: "Simulated"))
        factors.append(RiskFactor(type: .liquidityDepth, score: 70, detail: "Simulated"))

        return factors
    }
}
