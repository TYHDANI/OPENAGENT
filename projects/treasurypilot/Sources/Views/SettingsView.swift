import SwiftUI

struct SettingsView: View {
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        NavigationStack {
            List {
                Section("Subscription") {
                    if storeManager.isSubscribed {
                        HStack {
                            Label("Active: \(storeManager.currentTier.rawValue)", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    NavigationLink {
                        PaywallView()
                    } label: {
                        Label(
                            storeManager.isSubscribed ? "Manage Subscription" : "Upgrade to Pro",
                            systemImage: "crown"
                        )
                    }
                    Button {
                        Task { await storeManager.restorePurchases() }
                    } label: {
                        Label("Restore Purchases", systemImage: "arrow.clockwise")
                    }
                }

                Section("Users & Access") {
                    NavigationLink {
                        UserManagementView()
                    } label: {
                        Label("Manage Users", systemImage: "person.2")
                    }
                }

                Section("Data") {
                    NavigationLink {
                        ReportsView()
                    } label: {
                        Label("Reports & Exports", systemImage: "doc.text")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.appVersion)
                    LabeledContent("Tier", value: storeManager.currentTier.rawValue)
                    LabeledContent("Max Entities", value: storeManager.currentTier.maxEntities == .max ? "Unlimited" : "\(storeManager.currentTier.maxEntities)")
                }

                Section {
                    Text("TreasuryPilot is a tax accounting tool. It does not provide tax advice. Consult a qualified tax professional before making any tax-related decisions.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
