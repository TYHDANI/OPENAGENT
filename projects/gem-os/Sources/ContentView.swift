import SwiftUI

struct ContentView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedTab: Tab = .gems
    @State private var navigationPath = NavigationPath()

    enum Tab: String, CaseIterable {
        case gems = "Gems"
        case simulation = "Simulate"
        case reactor = "Reactor"
        case garden = "Garden"
        case recipes = "Recipes"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .gems: return "diamond.fill"
            case .simulation: return "chart.scatter"
            case .reactor: return "waveform.badge.plus"
            case .garden: return "leaf.fill"
            case .recipes: return "book.pages"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Gem Search/Picker (NEW - Landing Page)
            GemSearchView()
                .tabItem {
                    Label(Tab.gems.rawValue, systemImage: Tab.gems.icon)
                }
                .tag(Tab.gems)

            // MARK: - Simulation Tab
            SimulationView()
                .tabItem {
                    Label(Tab.simulation.rawValue, systemImage: Tab.simulation.icon)
                }
                .tag(Tab.simulation)

            // MARK: - Digital Twin Tab
            ReactorView()
                .tabItem {
                    Label(Tab.reactor.rawValue, systemImage: Tab.reactor.icon)
                }
                .tag(Tab.reactor)

            // MARK: - Garden Tab (NEW)
            GardenView()
                .tabItem {
                    Label(Tab.garden.rawValue, systemImage: Tab.garden.icon)
                }
                .tag(Tab.garden)

            // MARK: - Recipes Tab
            RecipesView()
                .tabItem {
                    Label(Tab.recipes.rawValue, systemImage: Tab.recipes.icon)
                }
                .tag(Tab.recipes)

            // MARK: - Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
            }
            .tag(Tab.settings)
        }
        .overlay(alignment: .top) {
            if !storeManager.isSubscribed {
                SubscriptionBanner {
                    // Switch to settings tab to show paywall
                    selectedTab = .settings
                }
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var showingPaywall = false

    var body: some View {
        List {
            // Account Section
            Section("Account") {
                if storeManager.isSubscribed {
                    HStack {
                        Label("Premium Active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        if let product = storeManager.activeSubscription {
                            Text(product.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Manage Subscription") {
                        openSubscriptionManagement()
                    }
                } else {
                    Button(action: { showingPaywall = true }) {
                        HStack {
                            Label("Upgrade to Premium", systemImage: "star.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button("Restore Purchases") {
                    Task {
                        await storeManager.restorePurchases()
                    }
                }
            }

            // App Section
            Section("App") {
                LabeledContent("Version", value: Bundle.main.appVersion)
                LabeledContent("Build", value: Bundle.main.appBuild)

                Link(destination: URL(string: "mailto:support@gemos.app")!) {
                    Label("Contact Support", systemImage: "envelope")
                }
            }

            // Legal Section
            Section("Legal") {
                Link("Terms of Service", destination: URL(string: "https://gemos.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://gemos.app/privacy")!)
                Link("Acknowledgments", destination: URL(string: "https://gemos.app/acknowledgments")!)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func openSubscriptionManagement() {
        #if canImport(UIKit)
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Subscription Banner

struct SubscriptionBanner: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                Text("Unlock all features with Premium")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .foregroundStyle(.white)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
}

// MARK: - Bundle Extension

private extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    ContentView()
        .environment(StoreManager())
}
