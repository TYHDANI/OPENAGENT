import Foundation
import SwiftUI

enum AQILevel: String, Codable {
    case good, moderate, unhealthySensitive, unhealthy, veryUnhealthy, hazardous

    var label: String {
        switch self {
        case .good: "Good"
        case .moderate: "Moderate"
        case .unhealthySensitive: "Unhealthy for Sensitive"
        case .unhealthy: "Unhealthy"
        case .veryUnhealthy: "Very Unhealthy"
        case .hazardous: "Hazardous"
        }
    }

    var color: Color {
        switch self {
        case .good: AppColors.success
        case .moderate: .yellow
        case .unhealthySensitive: .orange
        case .unhealthy: AppColors.danger
        case .veryUnhealthy: .purple
        case .hazardous: Color(hex: "7E0023")
        }
    }

    static func from(aqi: Int) -> AQILevel {
        switch aqi {
        case 0...50: .good
        case 51...100: .moderate
        case 101...150: .unhealthySensitive
        case 151...200: .unhealthy
        case 201...300: .veryUnhealthy
        default: .hazardous
        }
    }
}

struct AirReading: Identifiable, Codable {
    let id: UUID
    var roomID: UUID
    var timestamp: Date
    var pm25: Double          // PM2.5 µg/m³
    var pm10: Double          // PM10 µg/m³
    var co2: Double           // CO2 ppm
    var voc: Double           // VOC ppb
    var temperature: Double   // °F
    var humidity: Double      // %
    var aqi: Int

    init(id: UUID = UUID(), roomID: UUID, pm25: Double, pm10: Double, co2: Double,
         voc: Double, temperature: Double, humidity: Double) {
        self.id = id; self.roomID = roomID; self.timestamp = Date()
        self.pm25 = pm25; self.pm10 = pm10; self.co2 = co2; self.voc = voc
        self.temperature = temperature; self.humidity = humidity
        self.aqi = Self.calculateAQI(pm25: pm25, pm10: pm10)
    }

    var level: AQILevel { AQILevel.from(aqi: aqi) }

    static func calculateAQI(pm25: Double, pm10: Double) -> Int {
        // Simplified EPA AQI breakpoints for PM2.5
        let pm25AQI: Int
        switch pm25 {
        case 0..<12.1: pm25AQI = Int(pm25 / 12.0 * 50)
        case 12.1..<35.5: pm25AQI = Int(50 + (pm25 - 12.1) / 23.4 * 50)
        case 35.5..<55.5: pm25AQI = Int(100 + (pm25 - 35.5) / 20.0 * 50)
        case 55.5..<150.5: pm25AQI = Int(150 + (pm25 - 55.5) / 95.0 * 50)
        default: pm25AQI = 300
        }
        return min(500, max(0, pm25AQI))
    }
}
