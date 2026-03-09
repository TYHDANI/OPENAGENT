import Foundation
import SwiftUI
import CoreLocation

// MARK: - Biome Types

enum BiomeType: String, CaseIterable, Identifiable, Codable {
    case temperate = "Temperate Forest"
    case tropical = "Tropical Rainforest"
    case desert = "Desert"
    case arctic = "Arctic / Tundra"
    case mountain = "Mountain"
    case coastal = "Coastal"
    case grassland = "Grassland"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .temperate: return "tree.fill"
        case .tropical: return "leaf.fill"
        case .desert: return "sun.max.fill"
        case .arctic: return "snowflake"
        case .mountain: return "mountain.2.fill"
        case .coastal: return "water.waves"
        case .grassland: return "wind"
        }
    }

    var color: Color {
        switch self {
        case .temperate: return TSTheme.accentGreen
        case .tropical: return Color(hex: "00C853")
        case .desert: return TSTheme.sandBrown
        case .arctic: return TSTheme.waterBlue
        case .mountain: return TSTheme.textSecondary
        case .coastal: return TSTheme.water
        case .grassland: return TSTheme.warningYellow
        }
    }
}

// MARK: - Guide Category

enum GuideCategory: String, CaseIterable, Identifiable, Codable {
    case fire = "Fire"
    case water = "Water"
    case shelter = "Shelter"
    case signaling = "Signaling"
    case firstAid = "First Aid"
    case navigation = "Navigation"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fire: return "flame.fill"
        case .water: return "drop.fill"
        case .shelter: return "house.fill"
        case .signaling: return "antenna.radiowaves.left.and.right"
        case .firstAid: return "cross.case.fill"
        case .navigation: return "safari.fill"
        }
    }

    var color: Color {
        switch self {
        case .fire: return TSTheme.fire
        case .water: return TSTheme.water
        case .shelter: return TSTheme.sandBrown
        case .signaling: return TSTheme.warningYellow
        case .firstAid: return TSTheme.danger
        case .navigation: return TSTheme.accentGreen
        }
    }
}

// MARK: - Guide Difficulty

enum GuideDifficulty: String, CaseIterable, Identifiable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .beginner: return TSTheme.safe
        case .intermediate: return TSTheme.waterBlue
        case .advanced: return TSTheme.warningYellow
        case .expert: return TSTheme.danger
        }
    }
}

// MARK: - Survival Guide

struct SurvivalGuide: Identifiable, Codable {
    let id: UUID
    let title: String
    let category: GuideCategory
    let difficulty: GuideDifficulty
    let summary: String
    let steps: [String]
    let tips: [String]
    let applicableBiomes: [BiomeType]
    let isOfflineAvailable: Bool
    let estimatedTime: String

    init(
        id: UUID = UUID(),
        title: String,
        category: GuideCategory,
        difficulty: GuideDifficulty,
        summary: String,
        steps: [String],
        tips: [String] = [],
        applicableBiomes: [BiomeType] = BiomeType.allCases,
        isOfflineAvailable: Bool = true,
        estimatedTime: String = ""
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.difficulty = difficulty
        self.summary = summary
        self.steps = steps
        self.tips = tips
        self.applicableBiomes = applicableBiomes
        self.isOfflineAvailable = isOfflineAvailable
        self.estimatedTime = estimatedTime
    }
}

// MARK: - Danger Level

enum DangerLevel: String, CaseIterable, Identifiable, Codable {
    case safe = "Safe"
    case caution = "Caution"
    case deadly = "Deadly"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .safe: return TSTheme.safe
        case .caution: return TSTheme.caution
        case .deadly: return TSTheme.danger
        }
    }

    var icon: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .deadly: return "xmark.octagon.fill"
        }
    }
}

// MARK: - Species

enum SpeciesKind: String, CaseIterable, Identifiable, Codable {
    case plant = "Plant"
    case animal = "Animal"
    case insect = "Insect"
    case fungus = "Fungus"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .plant: return "leaf.fill"
        case .animal: return "pawprint.fill"
        case .insect: return "ant.fill"
        case .fungus: return "circle.hexagongrid.fill"
        }
    }
}

struct Species: Identifiable, Codable {
    let id: UUID
    let commonName: String
    let scientificName: String
    let kind: SpeciesKind
    let dangerLevel: DangerLevel
    let isEdible: Bool
    let description: String
    let identificationTips: [String]
    let regions: [String]
    let habitat: String
    let seasonality: String

    init(
        id: UUID = UUID(),
        commonName: String,
        scientificName: String,
        kind: SpeciesKind,
        dangerLevel: DangerLevel,
        isEdible: Bool,
        description: String,
        identificationTips: [String],
        regions: [String],
        habitat: String = "",
        seasonality: String = "Year-round"
    ) {
        self.id = id
        self.commonName = commonName
        self.scientificName = scientificName
        self.kind = kind
        self.dangerLevel = dangerLevel
        self.isEdible = isEdible
        self.description = description
        self.identificationTips = identificationTips
        self.regions = regions
        self.habitat = habitat
        self.seasonality = seasonality
    }
}

// MARK: - SOS Beacon

struct SOSBeacon: Identifiable, Codable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let message: String
    var isSent: Bool

    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        message: String = "SOS — Emergency assistance needed",
        isSent: Bool = false
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.message = message
        self.isSent = isSent
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var coordinateString: String {
        let latDir = latitude >= 0 ? "N" : "S"
        let lonDir = longitude >= 0 ? "E" : "W"
        return String(format: "%.4f%@ %.4f%@", abs(latitude), latDir, abs(longitude), lonDir)
    }
}

// MARK: - Emergency Contact

struct EmergencyContact: Identifiable, Codable {
    let id: UUID
    let country: String
    let countryCode: String
    let police: String
    let fire: String
    let ambulance: String
    let universalEmergency: String
    let coastGuard: String?
    let mountainRescue: String?

    init(
        id: UUID = UUID(),
        country: String,
        countryCode: String,
        police: String,
        fire: String,
        ambulance: String,
        universalEmergency: String,
        coastGuard: String? = nil,
        mountainRescue: String? = nil
    ) {
        self.id = id
        self.country = country
        self.countryCode = countryCode
        self.police = police
        self.fire = fire
        self.ambulance = ambulance
        self.universalEmergency = universalEmergency
        self.coastGuard = coastGuard
        self.mountainRescue = mountainRescue
    }
}

// MARK: - Region

struct Region: Identifiable, Codable {
    let id: UUID
    let name: String
    let biome: BiomeType
    let latitude: Double
    let longitude: Double
    let radiusKm: Double
    let description: String
    let keyThreats: [String]
    let downloadSizeMB: Int
    var isDownloaded: Bool

    init(
        id: UUID = UUID(),
        name: String,
        biome: BiomeType,
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 100,
        description: String = "",
        keyThreats: [String] = [],
        downloadSizeMB: Int = 50,
        isDownloaded: Bool = false
    ) {
        self.id = id
        self.name = name
        self.biome = biome
        self.latitude = latitude
        self.longitude = longitude
        self.radiusKm = radiusKm
        self.description = description
        self.keyThreats = keyThreats
        self.downloadSizeMB = downloadSizeMB
        self.isDownloaded = isDownloaded
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Map Annotation Item

struct MapAnnotationItem: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
    let kind: AnnotationKind

    enum AnnotationKind: String {
        case waterSource = "Water Source"
        case shelter = "Shelter"
        case danger = "Danger Zone"
        case campsite = "Campsite"
        case trailhead = "Trailhead"
    }

    var icon: String {
        switch kind {
        case .waterSource: return "drop.fill"
        case .shelter: return "house.fill"
        case .danger: return "exclamationmark.triangle.fill"
        case .campsite: return "tent.fill"
        case .trailhead: return "figure.hiking"
        }
    }

    var color: Color {
        switch kind {
        case .waterSource: return TSTheme.water
        case .shelter: return TSTheme.sandBrown
        case .danger: return TSTheme.danger
        case .campsite: return TSTheme.accentGreen
        case .trailhead: return TSTheme.accentOrange
        }
    }
}

// MARK: - Units Preference

enum UnitsPreference: String, CaseIterable, Identifiable, Codable {
    case metric = "Metric"
    case imperial = "Imperial"

    var id: String { rawValue }

    var distanceLabel: String {
        switch self {
        case .metric: return "km"
        case .imperial: return "mi"
        }
    }

    var temperatureLabel: String {
        switch self {
        case .metric: return "C"
        case .imperial: return "F"
        }
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Identifiable, Codable {
    case free = "Free"
    case pro = "Pro"
    case lifetime = "Expedition"

    var id: String { rawValue }
}
