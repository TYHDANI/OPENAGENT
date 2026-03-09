import Foundation
import CoreLocation

// MARK: - CelesTrak TLE / GP Data
struct SatelliteGP: Codable, Identifiable {
    let objectName: String
    let noradCatId: Int
    let epoch: String
    let meanMotion: Double
    let eccentricity: Double
    let inclination: Double
    let raOfAscNode: Double
    let argOfPericenter: Double
    let meanAnomaly: Double
    let bstar: Double
    let revAtEpoch: Int?
    let objectType: String?

    var id: Int { noradCatId }

    enum CodingKeys: String, CodingKey {
        case objectName = "OBJECT_NAME"
        case noradCatId = "NORAD_CAT_ID"
        case epoch = "EPOCH"
        case meanMotion = "MEAN_MOTION"
        case eccentricity = "ECCENTRICITY"
        case inclination = "INCLINATION"
        case raOfAscNode = "RA_OF_ASC_NODE"
        case argOfPericenter = "ARG_OF_PERICENTER"
        case meanAnomaly = "MEAN_ANOMALY"
        case bstar = "BSTAR"
        case revAtEpoch = "REV_AT_EPOCH"
        case objectType = "OBJECT_TYPE"
    }
}

// MARK: - Satellite Group
enum SatelliteGroup: String, CaseIterable, Identifiable {
    case stations = "stations"
    case starlink = "starlink"
    case gpsOps = "gps-ops"
    case weather = "weather"
    case visual = "visual"
    case active = "active"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stations: return "Space Stations"
        case .starlink: return "Starlink"
        case .gpsOps: return "GPS"
        case .weather: return "Weather Sats"
        case .visual: return "Visible"
        case .active: return "All Active"
        }
    }

    var icon: String {
        switch self {
        case .stations: return "globe.americas"
        case .starlink: return "sparkles"
        case .gpsOps: return "location.north"
        case .weather: return "cloud.sun.bolt"
        case .visual: return "eye"
        case .active: return "satellite"
        }
    }

    var color: String {
        switch self {
        case .stations: return "#FFD700"
        case .starlink: return "#4FC3F7"
        case .gpsOps: return "#66BB6A"
        case .weather: return "#FFA726"
        case .visual: return "#CE93D8"
        case .active: return "#90A4AE"
        }
    }
}

// MARK: - Computed Satellite Position (simplified SGP4 output)
struct SatellitePosition: Identifiable {
    let id: Int
    let name: String
    let group: SatelliteGroup
    let coordinate: CLLocationCoordinate2D
    let altitude: Double // km
    let velocity: Double // km/s
    let timestamp: Date

    var altitudeFormatted: String {
        String(format: "%.0f km", altitude)
    }
}

// MARK: - Simple SGP4 Propagator
struct SimpleSGP4 {
    static let earthRadius = 6371.0 // km
    static let mu = 398600.4418 // km^3/s^2
    static let twoPi = 2.0 * Double.pi
    static let minutesPerDay = 1440.0
    static let degreesToRadians = Double.pi / 180.0

    static func propagate(satellite: SatelliteGP, to date: Date) -> SatellitePosition? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let epochDate = dateFormatter.date(from: satellite.epoch) else { return nil }

        let elapsed = date.timeIntervalSince(epochDate) / 60.0 // minutes
        let n = satellite.meanMotion * twoPi / minutesPerDay // rad/min
        let a = pow(mu / pow(n / 60.0, 2), 1.0/3.0) // semi-major axis km
        let M = (satellite.meanAnomaly * degreesToRadians) + n * elapsed
        let normalizedM = M.truncatingRemainder(dividingBy: twoPi)
        let E = solveKepler(M: normalizedM, e: satellite.eccentricity)
        let trueAnomaly = 2.0 * atan2(
            sqrt(1 + satellite.eccentricity) * sin(E / 2),
            sqrt(1 - satellite.eccentricity) * cos(E / 2)
        )
        let r = a * (1 - satellite.eccentricity * cos(E))
        let i = satellite.inclination * degreesToRadians
        let omega = satellite.argOfPericenter * degreesToRadians
        let raan = satellite.raOfAscNode * degreesToRadians

        // J2 perturbation for RAAN drift
        let j2 = 1.08263e-3
        let raanDot = -1.5 * j2 * pow(earthRadius / a, 2) * n * cos(i) / pow(1 - satellite.eccentricity * satellite.eccentricity, 2)
        let currentRaan = raan + raanDot * elapsed

        // Earth rotation
        let gmst = greenwichMeanSiderealTime(date: date)
        let argLat = omega + trueAnomaly
        let xECI = r * (cos(currentRaan) * cos(argLat) - sin(currentRaan) * sin(argLat) * cos(i))
        let yECI = r * (sin(currentRaan) * cos(argLat) + cos(currentRaan) * sin(argLat) * cos(i))
        let zECI = r * sin(argLat) * sin(i)

        // ECI to ECEF
        let xECEF = xECI * cos(gmst) + yECI * sin(gmst)
        let yECEF = -xECI * sin(gmst) + yECI * cos(gmst)
        let zECEF = zECI

        let lon = atan2(yECEF, xECEF) / degreesToRadians
        let lat = atan2(zECEF, sqrt(xECEF * xECEF + yECEF * yECEF)) / degreesToRadians
        let alt = r - earthRadius
        let vel = sqrt(mu / r)

        let group: SatelliteGroup = {
            let name = satellite.objectName.uppercased()
            if name.contains("ISS") || name.contains("TIANHE") { return .stations }
            if name.contains("STARLINK") { return .starlink }
            if name.contains("GPS") || name.contains("NAVSTAR") { return .gpsOps }
            return .active
        }()

        return SatellitePosition(
            id: satellite.noradCatId,
            name: satellite.objectName,
            group: group,
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            altitude: alt,
            velocity: vel,
            timestamp: date
        )
    }

    private static func solveKepler(M: Double, e: Double, tolerance: Double = 1e-8) -> Double {
        var E = M
        for _ in 0..<50 {
            let dE = (M - E + e * sin(E)) / (1 - e * cos(E))
            E += dE
            if abs(dE) < tolerance { break }
        }
        return E
    }

    private static func greenwichMeanSiderealTime(date: Date) -> Double {
        let j2000 = Date(timeIntervalSince1970: 946728000) // 2000-01-01T12:00:00Z
        let d = date.timeIntervalSince(j2000) / 86400.0
        let gmst = 280.46061837 + 360.98564736629 * d
        return (gmst.truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0) * degreesToRadians
    }
}
