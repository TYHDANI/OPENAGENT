import Foundation

/// Proprietary Sentinel Score algorithm — computes a 0-100 risk rating
/// using 15 weighted on-chain and off-chain signals.
struct ScoringEngine {

    // MARK: - Factor Weights (must sum to 1.0)

    static let weights: [RiskFactorType: Double] = [
        .tvlTrend:           0.12,
        .collateralRatio:    0.12,
        .reserveProof:       0.08,
        .auditRecency:       0.08,
        .contractAge:        0.06,
        .teamDoxxing:        0.07,
        .insuranceCoverage:  0.05,
        .withdrawalTime:     0.08,
        .regulatoryStatus:   0.06,
        .apyVolatility:      0.07,
        .bridgeDependency:   0.04,
        .socialSentiment:    0.04,
        .peerComparison:     0.03,
        .liquidityDepth:     0.06,
        .whaleConcentration: 0.04
    ]

    // MARK: - Compute Score

    static func computeScore(for product: YieldProduct) -> (score: Int, factors: [RiskFactor]) {
        var factors: [RiskFactor] = []

        for factorType in RiskFactorType.allCases {
            let weight = weights[factorType] ?? 0
            let rawValue = computeRawValue(for: factorType, product: product)
            let factor = RiskFactor(type: factorType, rawValue: rawValue, weight: weight)
            factors.append(factor)
        }

        let totalWeight = factors.reduce(0.0) { $0 + $1.weight }
        let weightedSum = factors.reduce(0.0) { $0 + $1.weightedScore }
        let finalScore = totalWeight > 0 ? Int(round(weightedSum / totalWeight)) : 50

        return (score: max(0, min(100, finalScore)), factors: factors)
    }

    // MARK: - Individual Factor Scoring

    private static func computeRawValue(for type: RiskFactorType, product: YieldProduct) -> Double {
        switch type {
        case .tvlTrend:
            return scoreTVLTrend(change7d: product.tvl7dChange, change30d: product.tvl30dChange)
        case .collateralRatio:
            return scoreCollateralRatio(product.collateralRatio)
        case .reserveProof:
            return scoreReserveProof(audit: product.auditStatus, collateral: product.collateralRatio)
        case .auditRecency:
            return scoreAuditStatus(product.auditStatus)
        case .contractAge:
            return scoreContractAge(days: product.contractAge, updateFreq: product.contractUpdateFrequency)
        case .teamDoxxing:
            return scoreTeamTransparency(product.teamTransparency)
        case .insuranceCoverage:
            return scoreInsurance(coverage: product.insuranceCoverage, tvl: product.tvl)
        case .withdrawalTime:
            return scoreWithdrawalTime(product.withdrawalTime)
        case .regulatoryStatus:
            return scoreRegulatoryStatus(product.regulatoryStatus)
        case .apyVolatility:
            return scoreAPYVolatility(product.apyVolatility)
        case .bridgeDependency:
            return scoreBridgeDependency(product.bridgeDependency)
        case .socialSentiment:
            return scoreSocialSentiment(product.socialSentiment)
        case .peerComparison:
            // Peer comparison is relative; default to neutral without peer data
            return 60.0
        case .liquidityDepth:
            return scoreLiquidityDepth(product.liquidityDepth)
        case .whaleConcentration:
            return scoreWhaleConcentration(product.whaleConcentration)
        }
    }

    // MARK: - Scoring Functions

    private static func scoreTVLTrend(change7d: Double, change30d: Double) -> Double {
        // Positive growth = good. Severe decline = bad.
        let score7d: Double
        switch change7d {
        case 5...: score7d = 90
        case 0..<5: score7d = 75
        case -5..<0: score7d = 55
        case -15..<(-5): score7d = 35
        default: score7d = 15
        }

        let score30d: Double
        switch change30d {
        case 10...: score30d = 90
        case 0..<10: score30d = 70
        case -10..<0: score30d = 50
        case -25..<(-10): score30d = 30
        default: score30d = 10
        }

        return score7d * 0.6 + score30d * 0.4
    }

    private static func scoreCollateralRatio(_ ratio: Double?) -> Double {
        guard let ratio else { return 40.0 }
        switch ratio {
        case 1.5...: return 95
        case 1.2..<1.5: return 80
        case 1.0..<1.2: return 60
        case 0.8..<1.0: return 30
        default: return 10
        }
    }

    private static func scoreReserveProof(audit: AuditStatus, collateral: Double?) -> Double {
        let auditScore: Double = audit == .fresh ? 80 : (audit == .stale ? 50 : 20)
        let collateralScore: Double = (collateral ?? 0) >= 1.0 ? 80 : 30
        return auditScore * 0.6 + collateralScore * 0.4
    }

    private static func scoreAuditStatus(_ status: AuditStatus) -> Double {
        switch status {
        case .fresh: return 90
        case .stale: return 55
        case .failed: return 15
        case .none: return 25
        }
    }

    private static func scoreContractAge(days: Int, updateFreq: Int) -> Double {
        let ageScore: Double
        switch days {
        case 730...: ageScore = 90 // 2+ years
        case 365..<730: ageScore = 75
        case 180..<365: ageScore = 55
        case 90..<180: ageScore = 35
        default: ageScore = 20
        }

        // Moderate update frequency is ideal (not too frequent, not abandoned)
        let updateScore: Double
        switch updateFreq {
        case 4...12: updateScore = 80
        case 1..<4: updateScore = 60
        case 13...24: updateScore = 50
        case 0: updateScore = 30 // abandoned
        default: updateScore = 40 // too frequent
        }

        return ageScore * 0.7 + updateScore * 0.3
    }

    private static func scoreTeamTransparency(_ transparency: TeamTransparency) -> Double {
        switch transparency {
        case .fullyDoxxed: return 90
        case .partiallyDoxxed: return 55
        case .anonymous: return 20
        }
    }

    private static func scoreInsurance(coverage: Double?, tvl: Double) -> Double {
        guard let coverage, tvl > 0 else { return 20.0 }
        let ratio = coverage / tvl
        switch ratio {
        case 0.5...: return 90
        case 0.2..<0.5: return 70
        case 0.05..<0.2: return 50
        default: return 25
        }
    }

    private static func scoreWithdrawalTime(_ time: WithdrawalTime) -> Double {
        switch time {
        case .instant: return 95
        case .sameDay: return 80
        case .oneToThreeDays: return 55
        case .threePlusDays: return 30
        case .locked: return 15
        }
    }

    private static func scoreRegulatoryStatus(_ status: RegulatoryStatus) -> Double {
        switch status {
        case .approved: return 95
        case .registered: return 75
        case .unregistered: return 45
        case .unknown: return 35
        case .banned: return 5
        }
    }

    private static func scoreAPYVolatility(_ volatility: Double) -> Double {
        // Lower volatility = more stable = better score
        switch volatility {
        case 0..<0.05: return 90
        case 0.05..<0.15: return 70
        case 0.15..<0.3: return 50
        case 0.3..<0.5: return 30
        default: return 15
        }
    }

    private static func scoreBridgeDependency(_ dependency: BridgeDependency) -> Double {
        switch dependency {
        case .none: return 90
        case .multiple: return 60
        case .single: return 30
        }
    }

    private static func scoreSocialSentiment(_ sentiment: SocialSentiment) -> Double {
        switch sentiment {
        case .positive: return 85
        case .neutral: return 60
        case .cautious: return 40
        case .negative: return 15
        }
    }

    private static func scoreLiquidityDepth(_ depth: LiquidityDepth) -> Double {
        switch depth {
        case .deep: return 90
        case .moderate: return 65
        case .shallow: return 35
        case .illiquid: return 10
        }
    }

    private static func scoreWhaleConcentration(_ concentration: Double) -> Double {
        // Lower whale concentration = better
        switch concentration {
        case 0..<0.1: return 90
        case 0.1..<0.25: return 70
        case 0.25..<0.5: return 45
        case 0.5..<0.75: return 25
        default: return 10
        }
    }

    // MARK: - Risk Level

    static func riskLevel(for score: Int) -> RiskLevel {
        switch score {
        case 75...100: return .low
        case 55..<75: return .moderate
        case 40..<55: return .elevated
        case 20..<40: return .high
        default: return .critical
        }
    }

    // MARK: - Alert Evaluation

    static func evaluateAlerts(
        product: YieldProduct,
        previousScore: Int,
        config: AlertConfiguration
    ) -> AlertSeverity? {
        guard config.isEnabled else { return nil }

        let scoreDrop = previousScore - product.sentinelScore
        if scoreDrop >= 30 || product.sentinelScore < 20 {
            return .critical
        } else if scoreDrop >= config.scoreDropThreshold || product.sentinelScore < config.minimumScoreThreshold {
            return .moderate
        } else if scoreDrop >= 10 {
            return .info
        }
        return nil
    }
}
