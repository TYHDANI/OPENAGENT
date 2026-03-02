import Foundation
import SwiftData

/// User-created collection of materials
@Model
final class MaterialCollection {
    var id: String = UUID().uuidString
    var name: String
    var descriptionText: String?
    var iconName: String
    var colorName: String
    var createdDate: Date
    var modifiedDate: Date

    @Relationship(deleteRule: .cascade)
    var materials: [Material] = []

    init(
        name: String,
        descriptionText: String? = nil,
        iconName: String = "folder.fill",
        colorName: String = "blue"
    ) {
        self.name = name
        self.descriptionText = descriptionText
        self.iconName = iconName
        self.colorName = colorName
        self.createdDate = Date()
        self.modifiedDate = Date()
    }

    func addMaterial(_ material: Material) {
        if !materials.contains(where: { $0.id == material.id }) {
            materials.append(material)
            modifiedDate = Date()
        }
    }

    func removeMaterial(_ material: Material) {
        materials.removeAll { $0.id == material.id }
        modifiedDate = Date()
    }
}

/// Favorite material tracking
@Model
final class FavoriteMaterial {
    var id: String = UUID().uuidString
    var material: Material
    var addedDate: Date

    init(material: Material) {
        self.material = material
        self.addedDate = Date()
    }
}