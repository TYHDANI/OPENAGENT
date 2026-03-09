import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            RiskScannerView()
                .tabItem {
                    Label("Risk Scanner", systemImage: "shield.checkered")
                }
                .tag(0)

            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }
                .tag(1)

            TaxCenterView()
                .tabItem {
                    Label("Tax Center", systemImage: "doc.text.fill")
                }
                .tag(2)

            LegacyView()
                .tabItem {
                    Label("Legacy", systemImage: "lock.shield.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(AppColors.accent)
    }
}
