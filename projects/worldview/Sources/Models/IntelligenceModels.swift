import Foundation
import CoreLocation

// MARK: - World Brief
struct WorldBrief: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let events: [BriefEvent]
    let generatedAt: Date
    let globalThreatLevel: ThreatLevel
}

struct BriefEvent: Identifiable {
    let id = UUID()
    let headline: String
    let description: String
    let region: String
    let category: EventCategory
    let severity: ThreatLevel
    let coordinate: CLLocationCoordinate2D?
    let sources: [String]
    let timestamp: Date
}

enum EventCategory: String, CaseIterable, Codable {
    case conflict = "Conflict"
    case naturalDisaster = "Natural Disaster"
    case political = "Political"
    case economic = "Economic"
    case cyber = "Cyber"
    case health = "Health"
    case environmental = "Environmental"
    case maritime = "Maritime"
    case aviation = "Aviation"
    case space = "Space"

    var icon: String {
        switch self {
        case .conflict: return "exclamationmark.triangle"
        case .naturalDisaster: return "tornado"
        case .political: return "building.columns"
        case .economic: return "chart.line.downtrend.xyaxis"
        case .cyber: return "lock.shield"
        case .health: return "heart.text.square"
        case .environmental: return "leaf.arrow.triangle.circlepath"
        case .maritime: return "ferry"
        case .aviation: return "airplane"
        case .space: return "satellite"
        }
    }
}

enum ThreatLevel: Int, CaseIterable, Codable, Comparable {
    case low = 1
    case guarded = 2
    case elevated = 3
    case high = 4
    case severe = 5

    var label: String {
        switch self {
        case .low: return "LOW"
        case .guarded: return "GUARDED"
        case .elevated: return "ELEVATED"
        case .high: return "HIGH"
        case .severe: return "SEVERE"
        }
    }

    var colorHex: String {
        switch self {
        case .low: return "#4CAF50"
        case .guarded: return "#2196F3"
        case .elevated: return "#FFC107"
        case .high: return "#FF9800"
        case .severe: return "#F44336"
        }
    }

    static func < (lhs: ThreatLevel, rhs: ThreatLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Breaking Alert
struct BreakingAlert: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: EventCategory
    let severity: ThreatLevel
    let coordinate: CLLocationCoordinate2D?
    let timestamp: Date
    let source: String
    let isRead: Bool

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - Country Intelligence
struct CountryIntelligence: Identifiable {
    let id: String // ISO country code
    let name: String
    let instabilityIndex: Double // 0-100
    let threatLevel: ThreatLevel
    let activeConflicts: Int
    let recentEvents: Int
    let economicPressure: Double
    let socialUnrest: Double
    let cyberThreats: Int
    let naturalDisasterRisk: Double
}

// MARK: - Elevation Response
struct ElevationResponse: Codable {
    let elevation: [Double]
}

// MARK: - OpenSky Flight
struct OpenSkyResponse: Codable {
    let time: Int
    let states: [[OpenSkyState]]?
}

enum OpenSkyState: Codable {
    case string(String?)
    case double(Double?)
    case int(Int?)
    case bool(Bool?)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let val = try? container.decode(String.self) { self = .string(val); return }
        if let val = try? container.decode(Double.self) { self = .double(val); return }
        if let val = try? container.decode(Int.self) { self = .int(val); return }
        if let val = try? container.decode(Bool.self) { self = .bool(val); return }
        if container.decodeNil() { self = .string(nil); return }
        self = .string(nil)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        }
    }

    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }

    var doubleValue: Double? {
        switch self {
        case .double(let v): return v
        case .int(let v): return v.map { Double($0) }
        default: return nil
        }
    }

    var boolValue: Bool? {
        if case .bool(let v) = self { return v }
        return nil
    }
}

struct FlightPin: Identifiable {
    let id: String // ICAO24
    let callsign: String?
    let coordinate: CLLocationCoordinate2D
    let altitude: Double // meters
    let velocity: Double // m/s
    let heading: Double // degrees
    let verticalRate: Double // m/s
    let onGround: Bool
    let originCountry: String
    let isMilitary: Bool

    var altitudeFeet: Int { Int(altitude * 3.281) }
    var speedKnots: Int { Int(velocity * 1.944) }
}
