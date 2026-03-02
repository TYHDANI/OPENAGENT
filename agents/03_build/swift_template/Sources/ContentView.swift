import SwiftUI

struct ContentView: View {
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        TabView {
            // MARK: - Home Tab
            NavigationStack {
                VStack(spacing: 20) {
                    Text("{{APP_NAME}}")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Welcome to your app")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .navigationTitle("Home")
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            // MARK: - Settings Tab
            NavigationStack {
                List {
                    Section("Account") {
                        if storeManager.isSubscribed {
                            Label("Premium Active", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        } else {
                            NavigationLink("Upgrade to Premium") {
                                PaywallView()
                            }
                        }
                    }

                    Section("About") {
                        LabeledContent("Version", value: Bundle.main.appVersion)
                    }
                }
                .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
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
