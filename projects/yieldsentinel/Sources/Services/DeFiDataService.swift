import Foundation

/// Service for fetching DeFi protocol data from public APIs.
/// Uses DeFiLlama (TVL), CoinGecko (pricing), and mock data for signals
/// not available via free APIs.
actor DeFiDataService {

    // MARK: - API Endpoints

    private let defiLlamaBaseURL = "https://api.llama.fi"
    private let coinGeckoBaseURL = "https://api.coingecko.com/api/v3"

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Fetch All Products

    func fetchProducts() async throws -> [YieldProduct] {
        // In production, this combines data from multiple APIs.
        // For MVP, we use curated protocol data supplemented with
        // mock signals for factors not yet available via public APIs.
        async let protocols = fetchDeFiLlamaProtocols()
        let protocolData = try await protocols
        return protocolData
    }

    // MARK: - DeFiLlama Integration

    private func fetchDeFiLlamaProtocols() async throws -> [YieldProduct] {
        guard let url = URL(string: "\(defiLlamaBaseURL)/protocols") else {
            throw DeFiDataError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DeFiDataError.serverError
        }

        let protocols = try JSONDecoder().decode([DeFiLlamaProtocol].self, from: data)

        // Filter to yield-relevant protocols and transform
        return protocols
            .filter { isYieldProtocol($0) }
            .prefix(100)
            .map { transformToYieldProduct($0) }
    }

    private func isYieldProtocol(_ p: DeFiLlamaProtocol) -> Bool {
        let yieldCategories: Set<String> = [
            "Lending", "Yield", "Yield Aggregator", "Liquid Staking",
            "Dexes", "CDP", "Bridge", "Restaking"
        ]
        return yieldCategories.contains(p.category ?? "") && (p.tvl ?? 0) > 1_000_000
    }

    private func transformToYieldProduct(_ p: DeFiLlamaProtocol) -> YieldProduct {
        let tvl = p.tvl ?? 0
        let change7d = p.change_7d ?? 0
        let change30d = p.change_30d ?? 0
        let chain = p.chain ?? p.chains?.first ?? "Multi-chain"

        let category = mapCategory(p.category)
        let auditStatus = mapAuditStatus(p.audits, auditNote: p.audit_note)
        let teamStatus = mapTeamStatus(p.openSource)

        // Construct product with available data + simulated signals for MVP
        var product = YieldProduct(
            id: p.slug ?? UUID().uuidString,
            name: p.name ?? "Unknown",
            protocol_: p.name ?? "Unknown",
            category: category,
            chain: chain,
            currentAPY: simulateAPY(category: category, tvl: tvl),
            tvl: tvl,
            tvl7dChange: change7d,
            tvl30dChange: change30d,
            sentinelScore: 50,
            previousScore: nil,
            riskLevel: .moderate,
            collateralRatio: simulateCollateralRatio(category: category),
            auditStatus: auditStatus,
            teamTransparency: teamStatus,
            regulatoryStatus: simulateRegulatoryStatus(),
            insuranceCoverage: simulateInsurance(tvl: tvl),
            withdrawalTime: simulateWithdrawalTime(category: category),
            bridgeDependency: chain == "Multi-chain" ? .multiple : .none,
            whaleConcentration: simulateWhaleConcentration(tvl: tvl),
            liquidityDepth: simulateLiquidityDepth(tvl: tvl),
            apyVolatility: simulateAPYVolatility(),
            contractAge: simulateContractAge(),
            contractUpdateFrequency: simulateUpdateFrequency(),
            socialSentiment: simulateSentiment(change7d: change7d),
            lastUpdated: Date(),
            historicalScores: [],
            logoSystemImage: category.systemImage
        )

        // Compute Sentinel Score using the scoring engine
        let (score, _) = ScoringEngine.computeScore(for: product)
        product.sentinelScore = score
        product.riskLevel = ScoringEngine.riskLevel(for: score)

        return product
    }

    // MARK: - Mapping Helpers

    private func mapCategory(_ category: String?) -> ProductCategory {
        switch category?.lowercased() {
        case "lending": return .lending
        case "liquid staking": return .liquidStaking
        case "yield aggregator", "yield": return .yieldAggregator
        case "dexes": return .dex
        case "bridge": return .bridge
        case "restaking": return .restaking
        case "cdp": return .cdp
        default: return .lending
        }
    }

    private func mapAuditStatus(_ audits: String?, auditNote: String?) -> AuditStatus {
        guard let audits else { return .none }
        if audits == "2" || audits == "3" { return .fresh }
        if audits == "1" { return .stale }
        if auditNote?.lowercased().contains("fail") == true { return .failed }
        return .none
    }

    private func mapTeamStatus(_ openSource: Bool?) -> TeamTransparency {
        if openSource == true { return .fullyDoxxed }
        return .partiallyDoxxed
    }

    // MARK: - Signal Simulation (MVP placeholder — replaced with real data feeds)

    private func simulateAPY(category: ProductCategory, tvl: Double) -> Double {
        // Larger TVL protocols tend to offer lower, more sustainable APY
        let baseAPY: Double
        switch category {
        case .lending: baseAPY = 4.5
        case .staking: baseAPY = 5.0
        case .liquidStaking: baseAPY = 4.2
        case .yieldAggregator: baseAPY = 8.0
        case .dex: baseAPY = 12.0
        case .bridge: baseAPY = 3.0
        case .restaking: baseAPY = 6.0
        case .cdp: baseAPY = 3.5
        }

        let tvlFactor = tvl > 1_000_000_000 ? 0.7 : (tvl > 100_000_000 ? 0.85 : 1.2)
        return baseAPY * tvlFactor
    }

    private func simulateCollateralRatio(category: ProductCategory) -> Double? {
        switch category {
        case .lending: return 1.3
        case .cdp: return 1.5
        case .liquidStaking: return 1.0
        default: return nil
        }
    }

    private func simulateRegulatoryStatus() -> RegulatoryStatus {
        [.registered, .unregistered, .unknown].randomElement() ?? .unknown
    }

    private func simulateInsurance(tvl: Double) -> Double? {
        if tvl > 1_000_000_000 { return tvl * 0.1 }
        if tvl > 100_000_000 { return tvl * 0.05 }
        return nil
    }

    private func simulateWithdrawalTime(category: ProductCategory) -> WithdrawalTime {
        switch category {
        case .lending, .dex: return .instant
        case .liquidStaking: return .oneToThreeDays
        case .staking, .restaking: return .threePlusDays
        default: return .sameDay
        }
    }

    private func simulateWhaleConcentration(tvl: Double) -> Double {
        // Larger protocols tend to have lower whale concentration
        if tvl > 5_000_000_000 { return 0.08 }
        if tvl > 1_000_000_000 { return 0.15 }
        if tvl > 100_000_000 { return 0.25 }
        return 0.40
    }

    private func simulateLiquidityDepth(tvl: Double) -> LiquidityDepth {
        if tvl > 1_000_000_000 { return .deep }
        if tvl > 100_000_000 { return .moderate }
        if tvl > 10_000_000 { return .shallow }
        return .illiquid
    }

    private func simulateAPYVolatility() -> Double {
        Double.random(in: 0.02...0.4)
    }

    private func simulateContractAge() -> Int {
        Int.random(in: 90...1200)
    }

    private func simulateUpdateFrequency() -> Int {
        Int.random(in: 2...15)
    }

    private func simulateSentiment(change7d: Double) -> SocialSentiment {
        if change7d > 5 { return .positive }
        if change7d > -5 { return .neutral }
        if change7d > -15 { return .cautious }
        return .negative
    }

    // MARK: - Fetch Single Product Detail

    func fetchProductDetail(id: String) async throws -> YieldProduct? {
        let products = try await fetchProducts()
        return products.first { $0.id == id }
    }
}

// MARK: - DeFiLlama Response Models

private struct DeFiLlamaProtocol: Codable {
    let name: String?
    let slug: String?
    let tvl: Double?
    let chain: String?
    let chains: [String]?
    let category: String?
    let change_7d: Double?
    let change_30d: Double?
    let audits: String?
    let audit_note: String?
    let openSource: Bool?
}

// MARK: - Errors

enum DeFiDataError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .serverError: return "Server returned an error"
        case .decodingError: return "Failed to decode response"
        case .noData: return "No data available"
        }
    }
}
