import SwiftUI

struct ContentView: View {
    @Environment(StoreManager.self) private var storeManager
    let alertService: AlertService
    @State private var alertsViewModel: AlertsViewModel
    @State private var portfolioViewModel = PortfolioViewModel()
    @State private var dashboardViewModel = DashboardViewModel()

    init(alertService: AlertService) {
        self.alertService = alertService
        self._alertsViewModel = State(initialValue: AlertsViewModel(alertService: alertService))
    }

    var body: some View {
        TabView {
            // MARK: - Dashboard
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            // MARK: - Alerts
            AlertsCenterView(viewModel: alertsViewModel)
                .tabItem {
                    Label("Alerts", systemImage: "bell.fill")
                }
                .badge(alertService.unreadCount)

            // MARK: - Portfolio
            PortfolioView(viewModel: portfolioViewModel, products: dashboardViewModel.products)
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }

            // MARK: - Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .task {
            await dashboardViewModel.loadProducts()
        }
    }
}

#Preview {
    ContentView(alertService: AlertService())
        .environment(StoreManager())
}
