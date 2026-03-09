import Foundation

enum AlertSeverity: String, Codable { case info, warning, critical }
enum AlertCategory: String, Codable {
    case riskChange, washSale, taxDeadline, successionCheckin, priceAlert, tvlDrop
    var label: String {
        switch self {
        case .riskChange: "Risk Change"
        case .washSale: "Wash Sale"
        case .taxDeadline: "Tax Deadline"
        case .successionCheckin: "Check-in Reminder"
        case .priceAlert: "Price Alert"
        case .tvlDrop: "TVL Drop"
        }
    }
}

struct AlertItem: Identifiable, Codable {
    let id: UUID
    var category: AlertCategory
    var severity: AlertSeverity
    var title: String
    var message: String
    var timestamp: Date
    var isRead: Bool
    var relatedEntityID: UUID?

    init(id: UUID = UUID(), category: AlertCategory, severity: AlertSeverity,
         title: String, message: String, relatedEntityID: UUID? = nil) {
        self.id = id; self.category = category; self.severity = severity
        self.title = title; self.message = message; self.timestamp = Date()
        self.isRead = false; self.relatedEntityID = relatedEntityID
    }
}
