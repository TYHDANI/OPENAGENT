import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "gauge.open.with.lines.needle.33percent") }
                .tag(0)

            RoomsView()
                .tabItem { Label("Rooms", systemImage: "house.fill") }
                .tag(1)

            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)

            FleetView()
                .tabItem { Label("Fleet", systemImage: "building.2.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(AppColors.accent)
    }
}
