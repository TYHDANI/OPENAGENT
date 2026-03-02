import Foundation
import Observation

/// ViewModel for managing synthesis recipes
@MainActor
@Observable
final class RecipesViewModel {

    // MARK: - State

    /// All available recipes
    private(set) var recipes: [Recipe] = []

    /// Filtered recipes based on search and gemstone type
    private(set) var filteredRecipes: [Recipe] = []

    /// Currently selected gemstone type filter (nil = all)
    var selectedGemstoneFilter: GemstoneType? {
        didSet { filterRecipes() }
    }

    /// Search query
    var searchQuery = "" {
        didSet {
            filterRecipes()
        }
    }

    /// Error message if operations fail
    private(set) var errorMessage: String?

    // MARK: - Initialization

    init() {
        loadRecipes()
    }

    // MARK: - Recipe Management

    /// Load all recipes
    func loadRecipes() {
        // For MVP, we'll use in-memory storage with default recipes
        // In a production app, this would load from Core Data or CloudKit
        if recipes.isEmpty {
            recipes = Recipe.defaultRecipes
        }
        filterRecipes()
    }

    /// Add a new recipe
    func addRecipe(_ recipe: Recipe) {
        recipes.append(recipe)
        filterRecipes()
    }

    /// Update an existing recipe
    func updateRecipe(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
            filterRecipes()
        }
    }

    /// Delete a recipe
    func deleteRecipe(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        filterRecipes()
    }

    /// Duplicate a recipe
    func duplicateRecipe(_ recipe: Recipe) {
        var newRecipe = recipe
        newRecipe.id = UUID()
        newRecipe.name = "\(recipe.name) (Copy)"
        addRecipe(newRecipe)
    }

    // MARK: - Filtering

    /// Filter recipes based on search query and gemstone type
    private func filterRecipes() {
        filteredRecipes = recipes.filter { recipe in
            // Filter by gemstone type
            if let filter = selectedGemstoneFilter, recipe.gemstoneType != filter {
                return false
            }

            // Filter by search query
            if !searchQuery.isEmpty {
                let lowercasedQuery = searchQuery.lowercased()
                return recipe.name.lowercased().contains(lowercasedQuery) ||
                       recipe.description.lowercased().contains(lowercasedQuery) ||
                       recipe.notes.lowercased().contains(lowercasedQuery)
            }

            return true
        }
    }

    /// Clear all filters
    func clearFilters() {
        selectedGemstoneFilter = nil
        searchQuery = ""
        filterRecipes()
    }
}