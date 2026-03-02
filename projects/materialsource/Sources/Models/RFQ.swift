import Foundation
import SwiftData

/// Request for Quote (RFQ) entity
@Model
final class RFQ {
    var id: String = UUID().uuidString
    var material: Material
    var supplier: Supplier
    var quantity: String
    var unit: String // e.g., "kg", "sheets", "meters"
    var specifications: String // Additional specs or requirements
    var targetDeliveryDate: Date?
    var status: RFQStatus
    var submittedDate: Date
    var lastUpdatedDate: Date
    var quoteReceived: Quote?
    var notes: String?

    init(
        material: Material,
        supplier: Supplier,
        quantity: String,
        unit: String,
        specifications: String,
        targetDeliveryDate: Date? = nil
    ) {
        self.material = material
        self.supplier = supplier
        self.quantity = quantity
        self.unit = unit
        self.specifications = specifications
        self.targetDeliveryDate = targetDeliveryDate
        self.status = .draft
        self.submittedDate = Date()
        self.lastUpdatedDate = Date()
    }
}

enum RFQStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case submitted = "Submitted"
    case pending = "Pending Response"
    case quoted = "Quote Received"
    case accepted = "Accepted"
    case declined = "Declined"
    case expired = "Expired"

    var color: String {
        switch self {
        case .draft: return "gray"
        case .submitted, .pending: return "blue"
        case .quoted: return "green"
        case .accepted: return "purple"
        case .declined, .expired: return "red"
        }
    }
}

/// Quote response from supplier
struct Quote: Codable {
    let id: String
    let unitPrice: Double
    let totalPrice: Double
    let currency: String
    let leadTime: String
    let validUntil: Date
    let termsAndConditions: String?
    let receivedDate: Date

    init(
        unitPrice: Double,
        totalPrice: Double,
        currency: String = "USD",
        leadTime: String,
        validUntil: Date,
        termsAndConditions: String? = nil
    ) {
        self.id = UUID().uuidString
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.currency = currency
        self.leadTime = leadTime
        self.validUntil = validUntil
        self.termsAndConditions = termsAndConditions
        self.receivedDate = Date()
    }
}