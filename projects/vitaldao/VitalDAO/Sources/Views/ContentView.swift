import SwiftUI

struct ContentView: View {
    @Environment(WearableAggregatorService.self) private var service
    @State private var selectedTab: AppTab = .dashboard

    enum AppTab: String, CaseIterable {
        case dashboard, wearables, insights, studies, settings

        var title: String { rawValue.capitalized }

        var icon: String {
            switch self {
            case .dashboard: "heart.text.clipboard"
            case .wearables: "applewatch.watchface"
            case .insights: "lightbulb.fill"
            case .studies: "flask.fill"
            case .settings: "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.icon) }
                .tag(AppTab.dashboard)

            WearablesView()
                .tabItem { Label(AppTab.wearables.title, systemImage: AppTab.wearables.icon) }
                .tag(AppTab.wearables)

            InsightsView()
                .tabItem { Label(AppTab.insights.title, systemImage: AppTab.insights.icon) }
                .tag(AppTab.insights)

            StudiesView()
                .tabItem { Label(AppTab.studies.title, systemImage: AppTab.studies.icon) }
                .tag(AppTab.studies)

            SettingsView()
                .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.icon) }
                .tag(AppTab.settings)
        }
        .tint(VDColors.accentTeal)
    }
}

#Preview {
    ContentView()
        .environment(WearableAggregatorService())
        .preferredColorScheme(.dark)
}
