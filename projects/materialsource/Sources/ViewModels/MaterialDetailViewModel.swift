import Foundation
import SwiftUI

/// View model for material detail view
@Observable
final class MaterialDetailViewModel {
    private let materialService: MaterialService
    private let rfqService: RFQService
    private let storeManager: StoreManager

    let material: Material
    var selectedSuppliers: Set<Supplier> = []
    var isFavorite = false
    var comparisons: [SupplierComparison] = []
    var showingRFQSheet = false
    var showingComparisonView = false

    init(
        material: Material,
        materialService: MaterialService,
        rfqService: RFQService,
        storeManager: StoreManager
    ) {
        self.material = material
        self.materialService = materialService
        self.rfqService = rfqService
        self.storeManager = storeManager
    }

    var isProUser: Bool {
        storeManager.isSubscribed
    }

    var visibleSuppliers: [Supplier] {
        if isProUser {
            return material.suppliers
        } else {
            // Free users see only 3 suppliers
            return Array(material.suppliers.prefix(3))
        }
    }

    var hasMoreSuppliers: Bool {
        !isProUser && material.suppliers.count > 3
    }

    var canCompareSuppliers: Bool {
        selectedSuppliers.count >= 2
    }

    func loadFavoriteStatus() async {
        isFavorite = await materialService.isFavorite(material)
    }

    func toggleFavorite() async {
        await materialService.toggleFavorite(material)
        isFavorite = await materialService.isFavorite(material)
    }

    func toggleSupplierSelection(_ supplier: Supplier) {
        if selectedSuppliers.contains(supplier) {
            selectedSuppliers.remove(supplier)
        } else {
            selectedSuppliers.insert(supplier)
        }
    }

    func loadComparisons() async {
        comparisons = await rfqService.compareQuotes(for: material)
    }

    func startRFQ() {
        if isProUser || selectedSuppliers.count == 1 {
            showingRFQSheet = true
        }
    }

    func compareSuppliers() {
        if canCompareSuppliers {
            showingComparisonView = true
        }
    }

    // Property grouping for display
    var groupedProperties: [(PropertyCategory, [MaterialProperty])] {
        let grouped = Dictionary(grouping: material.properties) { $0.category }
        return PropertyCategory.allCases.compactMap { category in
            if let properties = grouped[category] {
                return (category, properties)
            }
            return nil
        }
    }
}