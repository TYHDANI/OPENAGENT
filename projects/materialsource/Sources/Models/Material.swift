import Foundation
import SwiftData

/// Core material entity representing industrial materials like alloys, ceramics, composites
@Model
final class Material {
    var id: String = UUID().uuidString
    var name: String
    var category: String // e.g., "Aerospace Alloy", "Semiconductor", "Ceramic"
    var specifications: [Specification] = []
    var properties: [MaterialProperty] = []
    var suppliers: [Supplier] = []
    var imageURL: String?
    var descriptionText: String
    var applications: [String] = []
    var lastUpdated: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \FavoriteMaterial.material)
    var favoriteEntries: [FavoriteMaterial]?

    init(
        name: String,
        category: String,
        descriptionText: String,
        specifications: [Specification] = [],
        properties: [MaterialProperty] = [],
        suppliers: [Supplier] = [],
        applications: [String] = []
    ) {
        self.name = name
        self.category = category
        self.descriptionText = descriptionText
        self.specifications = specifications
        self.properties = properties
        self.suppliers = suppliers
        self.applications = applications
    }
}

/// Material specification standards (AMS, ASTM, ISO, etc.)
@Model
final class Specification {
    var id: String = UUID().uuidString
    var standard: String // e.g., "AMS", "ASTM", "ISO"
    var number: String // e.g., "4911", "B265", "9001"
    var title: String
    var revision: String?

    @Relationship(inverse: \Material.specifications)
    var materials: [Material]?

    init(standard: String, number: String, title: String, revision: String? = nil) {
        self.standard = standard
        self.number = number
        self.title = title
        self.revision = revision
    }

    var fullSpec: String {
        if let revision = revision {
            return "\(standard) \(number) Rev. \(revision)"
        }
        return "\(standard) \(number)"
    }
}

/// Physical, chemical, or mechanical properties of materials
@Model
final class MaterialProperty {
    var id: String = UUID().uuidString
    var name: String
    var value: String
    var unit: String?
    var category: PropertyCategory

    @Relationship(inverse: \Material.properties)
    var materials: [Material]?

    init(name: String, value: String, unit: String? = nil, category: PropertyCategory) {
        self.name = name
        self.value = value
        self.unit = unit
        self.category = category
    }

    var displayValue: String {
        if let unit = unit {
            return "\(value) \(unit)"
        }
        return value
    }
}

enum PropertyCategory: String, Codable, CaseIterable {
    case physical = "Physical"
    case mechanical = "Mechanical"
    case thermal = "Thermal"
    case electrical = "Electrical"
    case chemical = "Chemical"
}