import Foundation
import SwiftUI
import SwiftData

/// View model for favorites and collections management
@Observable
final class FavoritesViewModel {
    private let modelContext: ModelContext
    private let materialService: MaterialService

    var favorites: [Material] = []
    var collections: [MaterialCollection] = []
    var isLoading = false
    var errorMessage: String?

    // Collection creation
    var showingNewCollection = false
    var newCollectionName = ""
    var newCollectionDescription = ""
    var selectedIcon = "folder.fill"
    var selectedColor = "blue"

    let availableIcons = [
        "folder.fill", "star.fill", "bookmark.fill", "tag.fill",
        "cube.fill", "cylinder.fill", "hexagon.fill", "diamond.fill"
    ]

    let availableColors = [
        "blue", "purple", "pink", "red", "orange", "yellow", "green", "teal"
    ]

    init(modelContext: ModelContext, materialService: MaterialService) {
        self.modelContext = modelContext
        self.materialService = materialService
    }

    func loadFavorites() async {
        isLoading = true
        favorites = await materialService.getFavorites()
        isLoading = false
    }

    func loadCollections() async {
        await MainActor.run {
            do {
                var descriptor = FetchDescriptor<MaterialCollection>()
                descriptor.sortBy = [SortDescriptor(\.modifiedDate, order: .reverse)]
                collections = try modelContext.fetch(descriptor)
            } catch {
                errorMessage = "Failed to load collections: \(error.localizedDescription)"
                collections = []
            }
        }
    }

    func createCollection() async -> Bool {
        guard !newCollectionName.isEmpty else {
            errorMessage = "Collection name is required"
            return false
        }

        await MainActor.run {
            let collection = MaterialCollection(
                name: newCollectionName,
                descriptionText: newCollectionDescription.isEmpty ? nil : newCollectionDescription,
                iconName: selectedIcon,
                colorName: selectedColor
            )

            modelContext.insert(collection)

            do {
                try modelContext.save()
                // Reset form
                newCollectionName = ""
                newCollectionDescription = ""
                selectedIcon = "folder.fill"
                selectedColor = "blue"
                showingNewCollection = false
            } catch {
                errorMessage = "Failed to create collection: \(error.localizedDescription)"
            }
        }

        await loadCollections()
        return true
    }

    func deleteCollection(_ collection: MaterialCollection) async {
        await MainActor.run {
            modelContext.delete(collection)
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to delete collection: \(error.localizedDescription)"
            }
        }
        await loadCollections()
    }

    func addToCollection(material: Material, collection: MaterialCollection) async {
        await MainActor.run {
            collection.addMaterial(material)
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to add to collection: \(error.localizedDescription)"
            }
        }
    }

    func removeFromCollection(material: Material, collection: MaterialCollection) async {
        await MainActor.run {
            collection.removeMaterial(material)
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to remove from collection: \(error.localizedDescription)"
            }
        }
    }

    func removeFavorite(_ material: Material) async {
        await materialService.toggleFavorite(material)
        await loadFavorites()
    }
}