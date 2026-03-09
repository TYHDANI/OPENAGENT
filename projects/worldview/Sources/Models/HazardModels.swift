import Foundation
import CoreLocation

// MARK: - USGS Earthquake
struct USGSResponse: Codable {
    let type: String
    let features: [USGSFeature]
}

struct USGSFeature: Codable, Identifiable {
    let id: String
    let properties: USGSProperties
    let geometry: USGSGeometry
}

struct USGSProperties: Codable {
    let mag: Double?
    let place: String?
    let time: Int?
    let updated: Int?
    let url: String?
    let detail: String?
    let felt: Int?
    let cdi: Double?
    let mmi: Double?
    let alert: String?
    let status: String?
    let tsunami: Int?
    let sig: Int?
    let title: String?
    let type: String?
}

struct USGSGeometry: Codable {
    let type: String
    let coordinates: [Double] // [lon, lat, depth]
}

struct EarthquakePin: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let magnitude: Double
    let depth: Double
    let place: String
    let time: Date
    let tsunami: Bool
    let alert: String?
    let significance: Int

    var severityColor: String {
        switch magnitude {
        case ..<3: return "severity-low"
        case 3..<5: return "severity-medium"
        case 5..<7: return "severity-high"
        default: return "severity-critical"
        }
    }

    var radiusPoints: Double {
        max(6, magnitude * 4)
    }
}

// MARK: - NASA FIRMS Wildfires
struct FIRMSFire: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let brightness: Double
    let confidence: String
    let frp: Double // Fire Radiative Power
    let satellite: String
    let acquisitionDate: String
    let acquisitionTime: String
    let dayNight: String

    var isHighConfidence: Bool {
        confidence == "high" || confidence == "h" || (Double(confidence) ?? 0) > 80
    }
}

// MARK: - Maxar STAC Satellite Imagery
struct STACCatalog: Codable {
    let type: String?
    let id: String
    let title: String?
    let description: String?
    let links: [STACLink]
}

struct STACLink: Codable {
    let href: String
    let rel: String
    let type: String?
    let title: String?
}

struct MaxarEvent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let bbox: [Double]?
    let links: [STACLink]?

    var coordinate: CLLocationCoordinate2D? {
        guard let bbox = bbox, bbox.count >= 4 else { return nil }
        return CLLocationCoordinate2D(
            latitude: (bbox[1] + bbox[3]) / 2,
            longitude: (bbox[0] + bbox[2]) / 2
        )
    }

    var eventType: String {
        let lower = title.lowercased()
        if lower.contains("earthquake") { return "Earthquake" }
        if lower.contains("hurricane") || lower.contains("cyclone") { return "Hurricane" }
        if lower.contains("flood") { return "Flood" }
        if lower.contains("fire") || lower.contains("wildfire") { return "Wildfire" }
        if lower.contains("volcano") { return "Volcano" }
        if lower.contains("explosion") { return "Explosion" }
        if lower.contains("landslide") { return "Landslide" }
        return "Disaster"
    }

    var icon: String {
        switch eventType {
        case "Earthquake": return "waveform.path.ecg"
        case "Hurricane": return "hurricane"
        case "Flood": return "water.waves"
        case "Wildfire": return "flame"
        case "Volcano": return "mountain.2"
        case "Explosion": return "burst"
        case "Landslide": return "mountain.2.fill"
        default: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Flood Data
struct FloodPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let riverDischarge: Double
    let date: Date
    let severity: FloodSeverity
}

enum FloodSeverity: String {
    case low, moderate, high, extreme

    var color: String {
        switch self {
        case .low: return "severity-low"
        case .moderate: return "severity-medium"
        case .high: return "severity-high"
        case .extreme: return "severity-critical"
        }
    }
}
