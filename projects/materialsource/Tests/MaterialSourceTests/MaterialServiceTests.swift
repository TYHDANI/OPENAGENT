import XCTest
import SwiftData
@testable import MaterialSource

final class MaterialServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var materialService: MaterialService!

    @MainActor override func setUp() async throws {
        // Create in-memory model container for testing
        let schema = Schema([
            Material.self,
            Supplier.self,
            Specification.self,
            MaterialProperty.self,
            FavoriteMaterial.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])

        materialService = MaterialService(modelContext: modelContainer.mainContext)

        // Seed test data
        await seedTestData()
    }

    @MainActor private func seedTestData() async {
        let supplier = Supplier(
            name: "Test Supplier",
            location: "USA",
            leadTimeRange: "2-4 weeks",
            minimumOrderQuantity: "10 lbs"
        )

        let spec = Specification(
            standard: "AMS",
            number: "4911",
            title: "Titanium Alloy Sheet"
        )

        let property = MaterialProperty(
            name: "Density",
            value: "4.43",
            unit: "g/cm³",
            category: .physical
        )

        let material = Material(
            name: "Ti-6Al-4V",
            category: "Titanium Alloys",
            descriptionText: "Test titanium alloy",
            specifications: [spec],
            properties: [property],
            suppliers: [supplier]
        )

        modelContainer.mainContext.insert(material)

        do {
            try modelContainer.mainContext.save()
        } catch {
            XCTFail("Failed to seed test data: \(error)")
        }
    }

    @MainActor func testSearchMaterialsByName() async {
        // When
        await materialService.searchMaterials(query: "Ti-6Al-4V")

        // Then
        XCTAssertFalse(materialService.isSearching)
        XCTAssertEqual(materialService.searchResults.count, 1)
        XCTAssertEqual(materialService.searchResults.first?.name, "Ti-6Al-4V")
    }

    @MainActor func testSearchMaterialsBySpecification() async {
        // When
        await materialService.searchMaterials(query: "AMS 4911")

        // Then
        XCTAssertFalse(materialService.isSearching)
        XCTAssertEqual(materialService.searchResults.count, 1)
        XCTAssertEqual(materialService.searchResults.first?.specifications.first?.fullSpec, "AMS 4911")
    }

    @MainActor func testSearchMaterialsByCategory() async {
        // When
        await materialService.searchMaterials(query: "", category: "Titanium Alloys")

        // Then
        XCTAssertFalse(materialService.isSearching)
        XCTAssertEqual(materialService.searchResults.count, 1)
        XCTAssertEqual(materialService.searchResults.first?.category, "Titanium Alloys")
    }

    @MainActor func testToggleFavorite() async {
        // Given
        let materials = await materialService.getFeaturedMaterials()
        guard let material = materials.first else {
            XCTFail("No material found")
            return
        }

        // When - Add to favorites
        await materialService.toggleFavorite(material)
        let isFavorite1 = await materialService.isFavorite(material)

        // Then
        XCTAssertTrue(isFavorite1)

        // When - Remove from favorites
        await materialService.toggleFavorite(material)
        let isFavorite2 = await materialService.isFavorite(material)

        // Then
        XCTAssertFalse(isFavorite2)
    }

    @MainActor func testGetFavorites() async {
        // Given
        let materials = await materialService.getFeaturedMaterials()
        guard let material = materials.first else {
            XCTFail("No material found")
            return
        }

        // When
        await materialService.toggleFavorite(material)
        let favorites = await materialService.getFavorites()

        // Then
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.id, material.id)
    }
}

// MARK: - Mock Data Generator

extension MaterialServiceTests {
    static func createMockMaterial(name: String = "Test Material") -> Material {
        Material(
            name: name,
            category: "Test Category",
            descriptionText: "Test description for \(name)"
        )
    }

    static func createMockSupplier(name: String = "Test Supplier") -> Supplier {
        Supplier(
            name: name,
            location: "Test Location",
            leadTimeRange: "1-2 weeks",
            minimumOrderQuantity: "1 unit"
        )
    }
}