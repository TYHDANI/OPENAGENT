import Foundation
import SwiftUI

@Observable
final class RiskScannerViewModel {
    var products: [YieldProduct] = []
    var searchText = ""
    var selectedCategory: ProductCategory?
    var selectedChain: String?
    var sortBy: SortOption = .score
    var isLoading = false

    enum SortOption: String, CaseIterable {
        case score = "Sentinel Score"
        case apy = "APY"
        case tvl = "TVL"
        case name = "Name"
    }

    var filteredProducts: [YieldProduct] {
        var result = products
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if let chain = selectedChain {
            result = result.filter { $0.chain == chain }
        }
        switch sortBy {
        case .score: result.sort { $0.sentinelScore > $1.sentinelScore }
        case .apy: result.sort { $0.apy > $1.apy }
        case .tvl: result.sort { $0.tvl > $1.tvl }
        case .name: result.sort { $0.name < $1.name }
        }
        return result
    }

    var availableChains: [String] {
        Array(Set(products.map { $0.chain })).sorted()
    }

    func loadProducts(from persistence: PersistenceService) {
        products = persistence.products
    }

    func refreshScores() {
        for i in products.indices {
            products[i].riskFactors = ScoringEngine.generateFactors(for: products[i])
            products[i].sentinelScore = ScoringEngine.computeSentinelScore(factors: products[i].riskFactors)
            products[i].riskLevel = YieldProduct.riskLevelFor(score: products[i].sentinelScore)
        }
    }
}
