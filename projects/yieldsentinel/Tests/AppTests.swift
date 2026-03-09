import XCTest
@testable import YieldSentinel

final class YieldSentinelTests: XCTestCase {

    // MARK: - StoreManager Tests

    func testStoreManagerInitialState() {
        let manager = StoreManager()
        XCTAssertFalse(manager.isSubscribed)
        XCTAssertTrue(manager.products.isEmpty)
        XCTAssertNil(manager.activeSubscription)
        XCTAssertNil(manager.errorMessage)
        XCTAssertFalse(manager.isPurchasing)
        XCTAssertEqual(manager.currentTier, .free)
    }

    func testProductIdentifiersAreUnique() {
        let ids = StoreManager.allProductIDs
        XCTAssertEqual(ids.count, 4, "Should have 4 product identifiers (analyst+professional x monthly+yearly)")
    }

    // MARK: - Scoring Engine Tests

    func testScoringEngineWeightsSumToOne() {
        let totalWeight = ScoringEngine.weights.values.reduce(0.0, +)
        XCTAssertEqual(totalWeight, 1.0, accuracy: 0.001, "Weights must sum to 1.0")
    }

    func testScoringEngineAllFactorsCovered() {
        XCTAssertEqual(
            ScoringEngine.weights.count,
            RiskFactorType.allCases.count,
            "Every risk factor type must have a weight"
        )
    }

    func testScoringEngineHighQualityProtocol() {
        let product = makeProduct(
            tvl7dChange: 5, tvl30dChange: 10,
            collateralRatio: 1.5, auditStatus: .fresh,
            teamTransparency: .fullyDoxxed, regulatoryStatus: .approved,
            withdrawalTime: .instant, bridgeDependency: .none,
            whaleConcentration: 0.05, liquidityDepth: .deep,
            apyVolatility: 0.03, contractAge: 900
        )

        let (score, factors) = ScoringEngine.computeScore(for: product)
        XCTAssertGreaterThan(score, 70, "High-quality protocol should score above 70")
        XCTAssertEqual(factors.count, 15, "Should produce 15 risk factors")
    }

    func testScoringEngineRiskyProtocol() {
        let product = makeProduct(
            tvl7dChange: -25, tvl30dChange: -40,
            collateralRatio: 0.6, auditStatus: .failed,
            teamTransparency: .anonymous, regulatoryStatus: .banned,
            withdrawalTime: .locked, bridgeDependency: .single,
            whaleConcentration: 0.8, liquidityDepth: .illiquid,
            apyVolatility: 0.6, contractAge: 30
        )

        let (score, _) = ScoringEngine.computeScore(for: product)
        XCTAssertLessThan(score, 30, "Risky protocol should score below 30")
    }

    func testScoringEngineScoreRange() {
        for _ in 0..<20 {
            let product = makeRandomProduct()
            let (score, _) = ScoringEngine.computeScore(for: product)
            XCTAssertGreaterThanOrEqual(score, 0)
            XCTAssertLessThanOrEqual(score, 100)
        }
    }

    // MARK: - Risk Level Tests

    func testRiskLevelMapping() {
        XCTAssertEqual(ScoringEngine.riskLevel(for: 90), .low)
        XCTAssertEqual(ScoringEngine.riskLevel(for: 75), .low)
        XCTAssertEqual(ScoringEngine.riskLevel(for: 60), .moderate)
        XCTAssertEqual(ScoringEngine.riskLevel(for: 45), .elevated)
        XCTAssertEqual(ScoringEngine.riskLevel(for: 30), .high)
        XCTAssertEqual(ScoringEngine.riskLevel(for: 10), .critical)
    }

    // MARK: - Risk Factor Tests

    func testRiskFactorStatusMapping() {
        XCTAssertEqual(FactorStatus.from(score: 80), .good)
        XCTAssertEqual(FactorStatus.from(score: 60), .fair)
        XCTAssertEqual(FactorStatus.from(score: 35), .warning)
        XCTAssertEqual(FactorStatus.from(score: 10), .danger)
    }

    func testRiskFactorTypeDisplayNames() {
        for type in RiskFactorType.allCases {
            XCTAssertFalse(type.displayName.isEmpty, "\(type) should have a display name")
            XCTAssertFalse(type.description.isEmpty, "\(type) should have a description")
            XCTAssertFalse(type.systemImage.isEmpty, "\(type) should have a system image")
        }
    }

    // MARK: - Alert Evaluation Tests

    func testAlertEvaluationCriticalDrop() {
        let product = makeProduct(sentinelScore: 25)
        let config = AlertConfiguration(productID: product.id)
        let severity = ScoringEngine.evaluateAlerts(product: product, previousScore: 70, config: config)
        XCTAssertEqual(severity, .critical, "45-point drop should trigger CRITICAL")
    }

    func testAlertEvaluationModerateDrop() {
        let product = makeProduct(sentinelScore: 55)
        let config = AlertConfiguration(productID: product.id, scoreDropThreshold: 15)
        let severity = ScoringEngine.evaluateAlerts(product: product, previousScore: 72, config: config)
        XCTAssertEqual(severity, .moderate, "17-point drop should trigger MODERATE")
    }

    func testAlertEvaluationNoAlert() {
        let product = makeProduct(sentinelScore: 75)
        let config = AlertConfiguration(productID: product.id)
        let severity = ScoringEngine.evaluateAlerts(product: product, previousScore: 78, config: config)
        XCTAssertNil(severity, "3-point drop should not trigger an alert")
    }

    func testAlertEvaluationDisabled() {
        let product = makeProduct(sentinelScore: 10)
        let config = AlertConfiguration(productID: product.id, isEnabled: false)
        let severity = ScoringEngine.evaluateAlerts(product: product, previousScore: 90, config: config)
        XCTAssertNil(severity, "Disabled config should never trigger alerts")
    }

    // MARK: - Subscription Tier Tests

    func testSubscriptionTierLimits() {
        XCTAssertEqual(SubscriptionTier.free.maxProducts, 10)
        XCTAssertEqual(SubscriptionTier.analyst.maxProducts, 500)
        XCTAssertEqual(SubscriptionTier.professional.maxProducts, 500)

        XCTAssertEqual(SubscriptionTier.free.maxAlerts, 0)
        XCTAssertEqual(SubscriptionTier.analyst.maxAlerts, 10)
        XCTAssertEqual(SubscriptionTier.professional.maxAlerts, 100)

        XCTAssertFalse(SubscriptionTier.free.hasRealTimeData)
        XCTAssertTrue(SubscriptionTier.analyst.hasRealTimeData)
        XCTAssertTrue(SubscriptionTier.professional.hasRealTimeData)

        XCTAssertFalse(SubscriptionTier.free.hasSMSAlerts)
        XCTAssertFalse(SubscriptionTier.analyst.hasSMSAlerts)
        XCTAssertTrue(SubscriptionTier.professional.hasSMSAlerts)
    }

    // MARK: - YieldProduct Tests

    func testYieldProductFormattedTVL() {
        let p1 = makeProduct(tvl: 5_200_000_000)
        XCTAssertEqual(p1.formattedTVL, "$5.2B")

        let p2 = makeProduct(tvl: 150_000_000)
        XCTAssertEqual(p2.formattedTVL, "$150.0M")

        let p3 = makeProduct(tvl: 50_000)
        XCTAssertEqual(p3.formattedTVL, "$50K")
    }

    func testYieldProductScoreChange() {
        var product = makeProduct(sentinelScore: 60)
        product.previousScore = 75
        XCTAssertEqual(product.scoreChange, -15)

        product.previousScore = nil
        XCTAssertEqual(product.scoreChange, 0)
    }

    // MARK: - Persistence Tests

    func testPersistenceRoundTrip() {
        let persistence = PersistenceService()
        let testKey = "test_roundtrip_\(UUID().uuidString)"

        let original = [1, 2, 3, 4, 5]
        persistence.save(original, key: testKey)

        let loaded: [Int]? = persistence.load(key: testKey)
        XCTAssertEqual(loaded, original)

        persistence.delete(key: testKey)
        let deleted: [Int]? = persistence.load(key: testKey)
        XCTAssertNil(deleted)
    }

    // MARK: - Portfolio Tests

    func testPortfolioPositionCreation() {
        let position = PortfolioPosition(productID: "aave", productName: "Aave", amountUSD: 5000)
        XCTAssertEqual(position.productID, "aave")
        XCTAssertEqual(position.productName, "Aave")
        XCTAssertEqual(position.amountUSD, 5000)
    }

    // MARK: - Alert Service Tests

    func testAlertServiceInitialState() {
        let service = AlertService()
        XCTAssertTrue(service.alerts.isEmpty)
        XCTAssertEqual(service.unreadCount, 0)
    }

    func testAlertServiceAddAndRead() {
        let service = AlertService()
        let alert = AlertItem(
            productID: "test",
            productName: "Test Protocol",
            severity: .critical,
            title: "Test Alert",
            message: "Test message"
        )
        service.addAlert(alert)
        XCTAssertEqual(service.alerts.count, 1)
        XCTAssertEqual(service.unreadCount, 1)

        service.markAsRead(alert.id)
        XCTAssertEqual(service.unreadCount, 0)
    }

    // MARK: - Helpers

    private func makeProduct(
        sentinelScore: Int = 50,
        tvl: Double = 1_000_000_000,
        tvl7dChange: Double = 0,
        tvl30dChange: Double = 0,
        collateralRatio: Double? = 1.2,
        auditStatus: AuditStatus = .fresh,
        teamTransparency: TeamTransparency = .fullyDoxxed,
        regulatoryStatus: RegulatoryStatus = .registered,
        withdrawalTime: WithdrawalTime = .instant,
        bridgeDependency: BridgeDependency = .none,
        whaleConcentration: Double = 0.1,
        liquidityDepth: LiquidityDepth = .deep,
        apyVolatility: Double = 0.05,
        contractAge: Int = 500
    ) -> YieldProduct {
        YieldProduct(
            id: UUID().uuidString,
            name: "TestProtocol",
            protocol_: "TestProtocol",
            category: .lending,
            chain: "Ethereum",
            currentAPY: 5.0,
            tvl: tvl,
            tvl7dChange: tvl7dChange,
            tvl30dChange: tvl30dChange,
            sentinelScore: sentinelScore,
            previousScore: nil,
            riskLevel: ScoringEngine.riskLevel(for: sentinelScore),
            collateralRatio: collateralRatio,
            auditStatus: auditStatus,
            teamTransparency: teamTransparency,
            regulatoryStatus: regulatoryStatus,
            insuranceCoverage: 100_000_000,
            withdrawalTime: withdrawalTime,
            bridgeDependency: bridgeDependency,
            whaleConcentration: whaleConcentration,
            liquidityDepth: liquidityDepth,
            apyVolatility: apyVolatility,
            contractAge: contractAge,
            contractUpdateFrequency: 6,
            socialSentiment: .neutral,
            lastUpdated: Date(),
            historicalScores: [],
            logoSystemImage: "banknote"
        )
    }

    private func makeRandomProduct() -> YieldProduct {
        makeProduct(
            tvl7dChange: Double.random(in: -30...30),
            tvl30dChange: Double.random(in: -50...50),
            collateralRatio: Double.random(in: 0.5...2.0),
            auditStatus: [.fresh, .stale, .failed, .none].randomElement()!,
            teamTransparency: [.fullyDoxxed, .partiallyDoxxed, .anonymous].randomElement()!,
            regulatoryStatus: [.approved, .registered, .unregistered, .banned].randomElement()!,
            withdrawalTime: [.instant, .sameDay, .oneToThreeDays, .locked].randomElement()!,
            bridgeDependency: [.none, .single, .multiple].randomElement()!,
            whaleConcentration: Double.random(in: 0...1),
            liquidityDepth: [.deep, .moderate, .shallow, .illiquid].randomElement()!,
            apyVolatility: Double.random(in: 0...0.8),
            contractAge: Int.random(in: 10...1500)
        )
    }
}
