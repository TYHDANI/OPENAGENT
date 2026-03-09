import Foundation

@Observable
final class DashboardViewModel {

    // MARK: - State

    private(set) var products: [YieldProduct] = []
    private(set) var watchlist: [YieldProduct] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var lastUpdated: Date?

    var searchText = ""
    var selectedCategory: ProductCategory?
    var sortOption: SortOption = .score

    // MARK: - Dependencies

    private let dataService = DeFiDataService()
    private let persistence = PersistenceService.shared
    private var watchlistIDs: Set<String> = []

    // MARK: - Computed

    var filteredProducts: [YieldProduct] {
        var result = products

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.chain.lowercased().contains(query) ||
                $0.category.rawValue.lowercased().contains(query)
            }
        }

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        switch sortOption {
        case .score:
            result.sort { $0.sentinelScore > $1.sentinelScore }
        case .scoreAscending:
            result.sort { $0.sentinelScore < $1.sentinelScore }
        case .tvl:
            result.sort { $0.tvl > $1.tvl }
        case .apy:
            result.sort { $0.currentAPY > $1.currentAPY }
        case .name:
            result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .risk:
            result.sort { $0.riskLevel.sortOrder > $1.riskLevel.sortOrder }
        }

        return result
    }

    var portfolioWeightedRisk: Double? {
        let positions = persistence.loadPortfolio()
        guard !positions.isEmpty else { return nil }

        let totalValue = positions.reduce(0.0) { $0 + $1.amountUSD }
        guard totalValue > 0 else { return nil }

        var weightedScore = 0.0
        for position in positions {
            if let product = products.first(where: { $0.id == position.productID }) {
                let weight = position.amountUSD / totalValue
                weightedScore += Double(product.sentinelScore) * weight
            }
        }
        return weightedScore
    }

    var riskDistribution: [RiskLevel: Int] {
        var dist: [RiskLevel: Int] = [:]
        for product in products {
            dist[product.riskLevel, default: 0] += 1
        }
        return dist
    }

    // MARK: - Actions

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        // Load cached data first for instant display
        if let cached = persistence.loadCachedProducts(), products.isEmpty {
            products = cached
            updateWatchlist()
        }

        // Load watchlist IDs
        let savedIDs = persistence.loadWatchlist()
        watchlistIDs = Set(savedIDs)

        do {
            let fetched = try await dataService.fetchProducts()
            products = fetched
            persistence.saveCachedProducts(fetched)
            updateWatchlist()
            lastUpdated = Date()

            // Save current scores for future alert comparison
            var scores: [String: Int] = [:]
            for product in fetched {
                scores[product.id] = product.sentinelScore
            }
            persistence.savePreviousScores(scores)
        } catch {
            if products.isEmpty {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func toggleWatchlist(_ productID: String) {
        if watchlistIDs.contains(productID) {
            watchlistIDs.remove(productID)
        } else {
            watchlistIDs.insert(productID)
        }
        persistence.saveWatchlist(Array(watchlistIDs))
        updateWatchlist()
    }

    func isInWatchlist(_ productID: String) -> Bool {
        watchlistIDs.contains(productID)
    }

    private func updateWatchlist() {
        watchlist = products.filter { watchlistIDs.contains($0.id) }
    }

    // MARK: - Tier Gating

    func visibleProducts(for tier: SubscriptionTier) -> [YieldProduct] {
        let filtered = filteredProducts
        if tier == .free {
            return Array(filtered.prefix(tier.maxProducts))
        }
        return filtered
    }
}

// MARK: - Sort Option

enum SortOption: String, CaseIterable {
    case score = "Sentinel Score"
    case scoreAscending = "Risk (Highest)"
    case tvl = "TVL"
    case apy = "APY"
    case name = "Name"
    case risk = "Risk Level"
}
