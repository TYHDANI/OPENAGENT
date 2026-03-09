import SwiftUI
import MapKit

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(DataOrchestrator.self) private var data

    var body: some View {
        @Bindable var state = appState

        ZStack {
            NETheme.background.ignoresSafeArea()

            TabView(selection: $state.selectedTab) {
                GlobeTab()
                    .tag(AppTab.globe)
                    .tabItem { Label(AppTab.globe.rawValue, systemImage: AppTab.globe.icon) }

                LiveFeedsTab()
                    .tag(AppTab.feeds)
                    .tabItem { Label(AppTab.feeds.rawValue, systemImage: AppTab.feeds.icon) }

                SmartMoneyTab()
                    .tag(AppTab.smartMoney)
                    .tabItem { Label(AppTab.smartMoney.rawValue, systemImage: AppTab.smartMoney.icon) }

                IntelligenceTab()
                    .tag(AppTab.intelligence)
                    .tabItem { Label(AppTab.intelligence.rawValue, systemImage: AppTab.intelligence.icon) }

                AlertsTab()
                    .tag(AppTab.alerts)
                    .tabItem { Label(AppTab.alerts.rawValue, systemImage: AppTab.alerts.icon) }
                    .badge(data.alerts.filter { !$0.isRead }.count)

                SettingsTab()
                    .tag(AppTab.settings)
                    .tabItem { Label(AppTab.settings.rawValue, systemImage: AppTab.settings.icon) }
            }
            .tint(NETheme.accent)
        }
        .sheet(isPresented: $state.showOnboarding) {
            OnboardingView()
        }
    }
}
