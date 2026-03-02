import Foundation
import SwiftData

/// Service for material search, filtering, and management
@Observable
final class MaterialService {
    private let modelContext: ModelContext
    private(set) var searchResults: [Material] = []
    private(set) var isSearching = false
    private(set) var errorMessage: String?

    /// Categories available for filtering
    let categories = [
        "All Materials",
        "Aerospace Alloys",
        "Titanium Alloys",
        "Nickel Alloys",
        "Stainless Steels",
        "Aluminum Alloys",
        "Composites",
        "Ceramics",
        "Semiconductors",
        "Specialty Materials"
    ]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Search materials by specification or keyword
    func searchMaterials(query: String, category: String? = nil) async {
        isSearching = true
        errorMessage = nil

        await MainActor.run {
            do {
                var descriptor = FetchDescriptor<Material>()

                // Build predicate based on search query and category
                var predicates: [Predicate<Material>] = []

                if !query.isEmpty {
                    let searchQuery = query.lowercased()

                    // Search in name, specifications, and description
                    let namePredicate = #Predicate<Material> { material in
                        material.name.localizedStandardContains(searchQuery)
                    }

                    let descPredicate = #Predicate<Material> { material in
                        material.descriptionText.localizedStandardContains(searchQuery)
                    }

                    // For spec search (e.g., "AMS 4911")
                    let specPredicate = #Predicate<Material> { material in
                        material.specifications.contains { spec in
                            spec.fullSpec.localizedStandardContains(searchQuery) ||
                            spec.title.localizedStandardContains(searchQuery)
                        }
                    }

                    predicates.append(namePredicate || descPredicate || specPredicate)
                }

                if let category = category, category != "All Materials" {
                    let categoryPredicate = #Predicate<Material> { material in
                        material.category == category
                    }
                    predicates.append(categoryPredicate)
                }

                // Combine predicates
                if !predicates.isEmpty {
                    descriptor.predicate = predicates.reduce(predicates[0]) { $0 && $1 }
                }

                descriptor.sortBy = [SortDescriptor(\.name)]

                searchResults = try modelContext.fetch(descriptor)
            } catch {
                errorMessage = "Search failed: \(error.localizedDescription)"
                searchResults = []
            }

            isSearching = false
        }
    }

    /// Get featured materials for home screen
    func getFeaturedMaterials() async -> [Material] {
        await MainActor.run {
            do {
                var descriptor = FetchDescriptor<Material>()
                descriptor.fetchLimit = 6
                descriptor.sortBy = [SortDescriptor(\.lastUpdated, order: .reverse)]
                return try modelContext.fetch(descriptor)
            } catch {
                return []
            }
        }
    }

    /// Get materials by category
    func getMaterialsByCategory(_ category: String) async -> [Material] {
        await MainActor.run {
            do {
                var descriptor = FetchDescriptor<Material>()
                descriptor.predicate = #Predicate<Material> { material in
                    material.category == category
                }
                descriptor.sortBy = [SortDescriptor(\.name)]
                return try modelContext.fetch(descriptor)
            } catch {
                return []
            }
        }
    }

    /// Toggle favorite status
    func toggleFavorite(_ material: Material) async {
        await MainActor.run {
            do {
                // Check if already favorited
                let descriptor = FetchDescriptor<FavoriteMaterial>(
                    predicate: #Predicate { favorite in
                        favorite.material.id == material.id
                    }
                )

                let favorites = try modelContext.fetch(descriptor)

                if let existing = favorites.first {
                    // Remove from favorites
                    modelContext.delete(existing)
                } else {
                    // Add to favorites
                    let favorite = FavoriteMaterial(material: material)
                    modelContext.insert(favorite)
                }

                try modelContext.save()
            } catch {
                errorMessage = "Failed to update favorites: \(error.localizedDescription)"
            }
        }
    }

    /// Check if material is favorited
    func isFavorite(_ material: Material) async -> Bool {
        await MainActor.run {
            do {
                let descriptor = FetchDescriptor<FavoriteMaterial>(
                    predicate: #Predicate { favorite in
                        favorite.material.id == material.id
                    }
                )
                let count = try modelContext.fetchCount(descriptor)
                return count > 0
            } catch {
                return false
            }
        }
    }

    /// Get all favorite materials
    func getFavorites() async -> [Material] {
        await MainActor.run {
            do {
                var descriptor = FetchDescriptor<FavoriteMaterial>()
                descriptor.sortBy = [SortDescriptor(\.addedDate, order: .reverse)]
                let favorites = try modelContext.fetch(descriptor)
                return favorites.map { $0.material }
            } catch {
                return []
            }
        }
    }
}