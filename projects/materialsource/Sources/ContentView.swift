import SwiftUI

struct ContentView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = Tab.search

    enum Tab {
        case search
        case favorites
        case rfqs
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Search Tab
            SearchView()
                .tag(Tab.search)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            // MARK: - Favorites Tab
            FavoritesView()
                .tag(Tab.favorites)
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }

            // MARK: - RFQs Tab
            RFQListView()
                .tag(Tab.rfqs)
                .tabItem {
                    Label("RFQs", systemImage: "envelope.fill")
                }

            // MARK: - Settings Tab
            NavigationStack {
                List {
                    Section("Account") {
                        if storeManager.isSubscribed {
                            Label("Pro Active", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        } else {
                            NavigationLink("Upgrade to Pro") {
                                PaywallView()
                            }
                        }

                        Button {
                            Task {
                                do {
                                    try await storeManager.restorePurchases()
                                } catch {
                                    print("Restore failed: \(error)")
                                }
                            }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                        }
                    }

                    Section("Support") {
                        Link(destination: URL(string: "https://materialsource.app/support")!) {
                            Label("Help & Support", systemImage: "questionmark.circle")
                        }

                        Link(destination: URL(string: "https://materialsource.app/privacy")!) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                        }

                        Link(destination: URL(string: "https://materialsource.app/terms")!) {
                            Label("Terms of Use", systemImage: "doc.text")
                        }
                    }

                    Section("About") {
                        LabeledContent("Version", value: Bundle.main.appVersion)

                        HStack {
                            Text("Made for Engineers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "wrench.and.screwdriver")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Settings")
            }
            .tag(Tab.settings)
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(.accentColor)
    }
}

// MARK: - Bundle Extension

private extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    ContentView()
        .environment(StoreManager())
}
