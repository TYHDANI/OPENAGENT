import SwiftUI

enum DataLayerType: String, CaseIterable, Identifiable, Codable {
    // Natural Hazards
    case earthquakes = "Earthquakes"
    case wildfires = "Wildfires"
    case floods = "Floods"
    case volcanoes = "Volcanoes"

    // Weather & Climate
    case weather = "Weather"
    case weatherRadar = "Weather Radar"
    case airQuality = "Air Quality"
    case marineConditions = "Marine"
    case uvIndex = "UV Index"
    case historicalWeather = "Historical Weather"

    // Space & Satellites
    case satellites = "Satellites"
    case issTracker = "ISS Tracker"
    case starlinkConstellation = "Starlink"
    case gpsSatellites = "GPS Sats"
    case weatherSatellites = "Weather Sats"

    // Satellite Imagery
    case maxarImagery = "Maxar Satellite"
    case arcgisImagery = "ArcGIS Imagery"

    // Military & Security
    case militaryFlights = "Military Flights"
    case gpsJamming = "GPS Jamming"
    case cyberThreats = "Cyber Threats"
    case conflicts = "Conflicts"

    // Maritime & Transport
    case shipping = "Shipping"
    case navalActivity = "Naval Activity"

    // Media & Feeds
    case news = "News"
    case liveTVNews = "Live TV News"
    case liveTVWeather = "Live TV Weather"
    case webcams = "Webcams"

    // Economic
    case markets = "Markets"
    case commodities = "Commodities"

    // Social & Humanitarian
    case protests = "Protests"
    case displacement = "Displacement"
    case internetOutages = "Internet Outages"

    // RF Intelligence (from RuView WiFi-DensePose)
    case wifiSensing = "WiFi Sensing"
    case rfPresence = "RF Presence"
    case vitalSigns = "Vital Signs"
    case disasterResponse = "Disaster Response"
    case rfInterference = "RF Interference"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .earthquakes: return "waveform.path.ecg"
        case .wildfires: return "flame"
        case .floods: return "water.waves"
        case .volcanoes: return "mountain.2"
        case .weather: return "cloud.sun"
        case .weatherRadar: return "antenna.radiowaves.left.and.right"
        case .airQuality: return "aqi.medium"
        case .marineConditions: return "water.waves.and.arrow.up"
        case .uvIndex: return "sun.max.trianglebadge.exclamationmark"
        case .historicalWeather: return "clock.arrow.circlepath"
        case .satellites: return "satellite"
        case .issTracker: return "globe.americas"
        case .starlinkConstellation: return "sparkles"
        case .gpsSatellites: return "location.north"
        case .weatherSatellites: return "cloud.sun.bolt"
        case .maxarImagery: return "photo.artframe"
        case .arcgisImagery: return "map"
        case .militaryFlights: return "airplane"
        case .gpsJamming: return "antenna.radiowaves.left.and.right.slash"
        case .cyberThreats: return "lock.shield"
        case .conflicts: return "exclamationmark.triangle"
        case .shipping: return "ferry"
        case .navalActivity: return "scope"
        case .news: return "newspaper"
        case .liveTVNews: return "play.tv"
        case .liveTVWeather: return "tv"
        case .webcams: return "web.camera"
        case .markets: return "chart.line.uptrend.xyaxis"
        case .commodities: return "barrel"
        case .protests: return "person.3"
        case .displacement: return "figure.walk.departure"
        case .internetOutages: return "wifi.slash"
        case .wifiSensing: return "wifi.router"
        case .rfPresence: return "person.wave.2"
        case .vitalSigns: return "heart.text.clipboard"
        case .disasterResponse: return "cross.case"
        case .rfInterference: return "waveform.path.ecg.rectangle"
        }
    }

    var color: Color {
        switch self {
        case .earthquakes: return .orange
        case .wildfires: return .red
        case .floods: return .cyan
        case .volcanoes: return .red
        case .weather, .weatherRadar, .historicalWeather: return .blue
        case .airQuality: return .green
        case .marineConditions: return .teal
        case .uvIndex: return .yellow
        case .satellites, .issTracker, .starlinkConstellation, .gpsSatellites, .weatherSatellites: return .purple
        case .maxarImagery, .arcgisImagery: return .indigo
        case .militaryFlights: return .red
        case .gpsJamming: return .pink
        case .cyberThreats: return .orange
        case .conflicts: return .red
        case .shipping, .navalActivity: return .blue
        case .news: return .gray
        case .liveTVNews, .liveTVWeather: return .mint
        case .webcams: return .teal
        case .markets, .commodities: return .green
        case .protests: return .yellow
        case .displacement: return .orange
        case .internetOutages: return .red
        case .wifiSensing: return .cyan
        case .rfPresence: return .green
        case .vitalSigns: return .pink
        case .disasterResponse: return .red
        case .rfInterference: return .orange
        }
    }

    var category: LayerCategory {
        switch self {
        case .earthquakes, .wildfires, .floods, .volcanoes: return .naturalHazards
        case .weather, .weatherRadar, .airQuality, .marineConditions, .uvIndex, .historicalWeather: return .weatherClimate
        case .satellites, .issTracker, .starlinkConstellation, .gpsSatellites, .weatherSatellites: return .space
        case .maxarImagery, .arcgisImagery: return .satelliteImagery
        case .militaryFlights, .gpsJamming, .cyberThreats, .conflicts: return .security
        case .shipping, .navalActivity: return .maritime
        case .news, .liveTVNews, .liveTVWeather, .webcams: return .media
        case .markets, .commodities: return .economic
        case .protests, .displacement, .internetOutages: return .social
        case .wifiSensing, .rfPresence, .vitalSigns, .disasterResponse, .rfInterference: return .rfIntelligence
        }
    }
}

enum LayerCategory: String, CaseIterable, Identifiable {
    case naturalHazards = "Natural Hazards"
    case weatherClimate = "Weather & Climate"
    case space = "Space & Satellites"
    case satelliteImagery = "Satellite Imagery"
    case security = "Military & Security"
    case maritime = "Maritime & Transport"
    case media = "Media & Feeds"
    case economic = "Economic"
    case social = "Social & Humanitarian"
    case rfIntelligence = "RF Intelligence"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .naturalHazards: return "exclamationmark.triangle"
        case .weatherClimate: return "cloud.sun"
        case .space: return "satellite"
        case .satelliteImagery: return "photo"
        case .security: return "shield.checkered"
        case .maritime: return "ferry"
        case .media: return "play.rectangle"
        case .economic: return "chart.bar"
        case .social: return "person.3"
        case .rfIntelligence: return "wifi.router"
        }
    }
}
