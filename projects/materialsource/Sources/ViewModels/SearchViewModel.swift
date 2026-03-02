import Foundation
import SwiftUI
import SwiftData

/// View model for material search functionality
@Observable
final class SearchViewModel {
    private let materialService: MaterialService
    private let storeManager: StoreManager

    var searchQuery = ""
    var selectedCategory = "All Materials"
    var searchResults: [Material] {
        materialService.searchResults
    }
    var isSearching: Bool {
        materialService.isSearching
    }
    var hasSearched = false

    init(materialService: MaterialService, storeManager: StoreManager) {
        self.materialService = materialService
        self.storeManager = storeManager
    }

    var categories: [String] {
        materialService.categories
    }

    var isProUser: Bool {
        storeManager.isSubscribed
    }

    var visibleResults: [Material] {
        // Free users see up to 3 suppliers per material
        // Note: Supplier limitation is handled in the UI layer to avoid mutating SwiftData models
        return searchResults
    }

    func search() async {
        hasSearched = true
        await materialService.searchMaterials(
            query: searchQuery.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory == "All Materials" ? nil : selectedCategory
        )
    }

    func clearSearch() {
        searchQuery = ""
        selectedCategory = "All Materials"
        hasSearched = false
        Task {
            await materialService.searchMaterials(query: "", category: nil)
        }
    }
}