import SwiftUI

struct ContentView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Dashboard Tab
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.pie.fill")
            }
            .tag(0)

            // MARK: - Accounts Tab
            NavigationStack {
                AccountsListView()
            }
            .tabItem {
                Label("Accounts", systemImage: "building.columns.fill")
            }
            .tag(1)

            // MARK: - Plan Tab
            NavigationStack {
                SuccessionPlanView()
            }
            .tabItem {
                Label("Plan", systemImage: "shield.checkered")
            }
            .tag(2)

            // MARK: - Activity Tab
            NavigationStack {
                ActivityMonitorView()
            }
            .tabItem {
                Label("Activity", systemImage: "clock.arrow.circlepath")
            }
            .tag(3)

            // MARK: - Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(4)
        }
    }
}

#Preview {
    ContentView()
        .environment(StoreManager())
}
