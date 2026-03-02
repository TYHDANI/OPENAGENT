import SwiftUI

struct ContentView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(DataManager.self) private var dataManager
    @Environment(AuthManager.self) private var authManager
    @State private var selectedTab: Tab = .patients

    enum Tab {
        case patients
        case charting
        case cases
        case settings
    }

    var body: some View {
        @Bindable var authManager = authManager
        @Bindable var storeManager = storeManager

        TabView(selection: $selectedTab) {
            // MARK: - Patients Tab
            NavigationStack {
                PatientsListView()
            }
            .tabItem {
                Label("Patients", systemImage: "person.3.fill")
            }
            .tag(Tab.patients)

            // MARK: - Voice Charting Tab
            NavigationStack {
                VoiceChartingView()
            }
            .tabItem {
                Label("Charting", systemImage: "mic.fill")
            }
            .tag(Tab.charting)

            // MARK: - Cases Tab
            NavigationStack {
                CasePresentationListView()
            }
            .tabItem {
                Label("Cases", systemImage: "doc.text.fill")
            }
            .tag(Tab.cases)

            // MARK: - Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $authManager.showLoginScreen) {
            LoginView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $storeManager.showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    ContentView()
        .environment(StoreManager())
        .environment(DataManager())
        .environment(AuthManager())
}
