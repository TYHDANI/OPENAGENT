import SwiftUI
import MapKit

@main
struct NighteyeApp: App {
    @State private var dataOrchestrator = DataOrchestrator()
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataOrchestrator)
                .environment(appState)
                .preferredColorScheme(.dark)
                .task { await dataOrchestrator.startAllFeeds() }
        }
    }
}

@Observable
final class AppState {
    var selectedTab: AppTab = .globe
    var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarded")
    var showPaywall = false
    var searchText = ""
    var selectedRegion: RegionPreset = .global
    var activeDataLayers: Set<DataLayerType> = [.earthquakes, .wildfires, .weather, .satellites, .news]
    var timelinePosition: Date = .now
    var isTimelinePlaying = false
    var showLayerPanel = false
    var showAlerts = false
    var showWorldBrief = false

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarded")
        showOnboarding = false
    }
}

enum AppTab: String, CaseIterable {
    case globe = "Globe"
    case feeds = "Live Feeds"
    case smartMoney = "Smart Money"
    case intelligence = "Intel"
    case alerts = "Alerts"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .globe: return "globe"
        case .feeds: return "play.tv"
        case .smartMoney: return "banknote"
        case .intelligence: return "brain.head.profile"
        case .alerts: return "bell.badge"
        case .settings: return "gearshape"
        }
    }
}

enum RegionPreset: String, CaseIterable, Identifiable {
    case global = "Global"
    case americas = "Americas"
    case europe = "Europe"
    case mena = "MENA"
    case asiaPacific = "Asia-Pacific"
    case africa = "Africa"

    var id: String { rawValue }

    var center: CLLocationCoordinate2D {
        switch self {
        case .global: return CLLocationCoordinate2D(latitude: 20, longitude: 0)
        case .americas: return CLLocationCoordinate2D(latitude: 15, longitude: -80)
        case .europe: return CLLocationCoordinate2D(latitude: 50, longitude: 15)
        case .mena: return CLLocationCoordinate2D(latitude: 28, longitude: 45)
        case .asiaPacific: return CLLocationCoordinate2D(latitude: 25, longitude: 110)
        case .africa: return CLLocationCoordinate2D(latitude: 0, longitude: 25)
        }
    }

    var span: MKCoordinateSpan {
        switch self {
        case .global: return MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 360)
        default: return MKCoordinateSpan(latitudeDelta: 50, longitudeDelta: 60)
        }
    }
}
