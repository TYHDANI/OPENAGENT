import Foundation
import SwiftData

/// Supplier/vendor entity providing materials
@Model
final class Supplier {
    var id: String = UUID().uuidString
    var name: String
    var website: String?
    var contactEmail: String?
    var contactPhone: String?
    var certifications: [String] = [] // e.g., ["ISO 9001", "AS9100", "ITAR Registered"]
    var location: String // Country/Region
    var leadTimeRange: String // e.g., "2-4 weeks"
    var minimumOrderQuantity: String // e.g., "10 lbs", "1 sheet"
    var priceRange: PriceRange?
    var rating: Double? // 1-5 scale
    var verified: Bool = false
    var lastUpdated: Date = Date()

    @Relationship(inverse: \Material.suppliers)
    var materials: [Material]?

    @Relationship(deleteRule: .cascade, inverse: \RFQ.supplier)
    var rfqs: [RFQ]?

    init(
        name: String,
        location: String,
        leadTimeRange: String,
        minimumOrderQuantity: String,
        certifications: [String] = [],
        verified: Bool = false
    ) {
        self.name = name
        self.location = location
        self.leadTimeRange = leadTimeRange
        self.minimumOrderQuantity = minimumOrderQuantity
        self.certifications = certifications
        self.verified = verified
    }
}

/// Price range structure for materials from suppliers
struct PriceRange: Codable {
    let minPrice: Double
    let maxPrice: Double
    let currency: String // e.g., "USD"
    let unit: String // e.g., "per kg", "per sheet"

    var displayRange: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency

        let min = formatter.string(from: NSNumber(value: minPrice)) ?? ""
        let max = formatter.string(from: NSNumber(value: maxPrice)) ?? ""

        return "\(min) - \(max) \(unit)"
    }
}