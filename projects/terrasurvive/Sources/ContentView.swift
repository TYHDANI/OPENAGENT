import SwiftUI

// MARK: - Content View (5-Tab Layout)

struct ContentView: View {
    @State private var selectedTab: AppTab = .map

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Label(AppTab.map.title, systemImage: AppTab.map.icon)
                }
                .tag(AppTab.map)

            GuidesView()
                .tabItem {
                    Label(AppTab.guides.title, systemImage: AppTab.guides.icon)
                }
                .tag(AppTab.guides)

            SpeciesView()
                .tabItem {
                    Label(AppTab.species.title, systemImage: AppTab.species.icon)
                }
                .tag(AppTab.species)

            SOSView()
                .tabItem {
                    Label(AppTab.sos.title, systemImage: AppTab.sos.icon)
                }
                .tag(AppTab.sos)

            SettingsView()
                .tabItem {
                    Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(TSTheme.accentOrange)
    }
}

// MARK: - App Tab

enum AppTab: String, CaseIterable, Identifiable {
    case map
    case guides
    case species
    case sos
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .map: return "Map"
        case .guides: return "Guides"
        case .species: return "Species"
        case .sos: return "SOS"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .map: return "map.fill"
        case .guides: return "book.fill"
        case .species: return "leaf.fill"
        case .sos: return "sos"
        case .settings: return "gearshape.fill"
        }
    }
}
