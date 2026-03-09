import Foundation

enum AlertSeverity: String, Codable { case info, warning, critical }
enum AlertCategory: String, Codable {
    case aqiSpike, filterChange, co2High, humidityOutOfRange, vocAlert, temperatureAlert

    var label: String {
        switch self {
        case .aqiSpike: "AQI Spike"
        case .filterChange: "Filter Change"
        case .co2High: "High CO2"
        case .humidityOutOfRange: "Humidity Alert"
        case .vocAlert: "VOC Alert"
        case .temperatureAlert: "Temperature Alert"
        }
    }

    var icon: String {
        switch self {
        case .aqiSpike: "exclamationmark.triangle.fill"
        case .filterChange: "air.purifier.fill"
        case .co2High: "carbon.dioxide.cloud.fill"
        case .humidityOutOfRange: "humidity.fill"
        case .vocAlert: "aqi.medium"
        case .temperatureAlert: "thermometer.high"
        }
    }
}

struct AlertItem: Identifiable, Codable {
    let id: UUID
    var category: AlertCategory
    var severity: AlertSeverity
    var title: String
    var message: String
    var roomID: UUID?
    var propertyID: UUID?
    var timestamp: Date
    var isRead: Bool

    init(id: UUID = UUID(), category: AlertCategory, severity: AlertSeverity,
         title: String, message: String, roomID: UUID? = nil, propertyID: UUID? = nil) {
        self.id = id; self.category = category; self.severity = severity
        self.title = title; self.message = message; self.roomID = roomID
        self.propertyID = propertyID; self.timestamp = Date(); self.isRead = false
    }
}
