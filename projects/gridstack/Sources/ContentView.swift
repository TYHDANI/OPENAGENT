import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard

    enum AppTab: String, CaseIterable {
        case dashboard = "Dashboard"
        case drHub = "DR Hub"
        case mining = "Mining"
        case prosumer = "Prosumer"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .dashboard: return "bolt.fill"
            case .drHub: return "arrow.triangle.2.circlepath"
            case .mining: return "cpu"
            case .prosumer: return "person.crop.circle.badge.checkmark"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(AppTab.dashboard.rawValue, systemImage: AppTab.dashboard.icon)
                }
                .tag(AppTab.dashboard)

            DRHubView()
                .tabItem {
                    Label(AppTab.drHub.rawValue, systemImage: AppTab.drHub.icon)
                }
                .tag(AppTab.drHub)

            MiningView()
                .tabItem {
                    Label(AppTab.mining.rawValue, systemImage: AppTab.mining.icon)
                }
                .tag(AppTab.mining)

            ProsumerView()
                .tabItem {
                    Label(AppTab.prosumer.rawValue, systemImage: AppTab.prosumer.icon)
                }
                .tag(AppTab.prosumer)

            SettingsView()
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(AppColors.accent)
    }
}

#Preview {
    ContentView()
        .environment(EnergyService())
        .environment(StoreManager())
        .preferredColorScheme(.dark)
}
