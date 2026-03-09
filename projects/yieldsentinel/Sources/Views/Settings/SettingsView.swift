import SwiftUI

struct SettingsView: View {
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Subscription
                Section("Subscription") {
                    if storeManager.isSubscribed {
                        HStack {
                            Label("Current Plan", systemImage: "checkmark.seal.fill")
                            Spacer()
                            Text(storeManager.currentTier.rawValue)
                                .foregroundStyle(.green)
                                .fontWeight(.medium)
                        }

                        if let active = storeManager.activeSubscription {
                            LabeledContent("Price", value: active.displayPrice)
                        }

                        Button("Manage Subscription") {
                            openSubscriptionManagement()
                        }
                    } else {
                        HStack {
                            Label("Free Plan", systemImage: "person.crop.circle")
                            Spacer()
                            Text("Limited")
                                .foregroundStyle(.secondary)
                        }

                        NavigationLink("Upgrade to Premium") {
                            PaywallView()
                        }
                    }

                    Button("Restore Purchases") {
                        Task { await storeManager.restorePurchases() }
                    }
                }

                // MARK: - Tier Comparison
                Section("Plan Comparison") {
                    ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                        DisclosureGroup {
                            ForEach(tier.features, id: \.self) { feature in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    Text(feature)
                                        .font(.caption)
                                }
                            }
                        } label: {
                            HStack {
                                Text(tier.rawValue)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(tier.displayPrice)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // MARK: - Data
                Section("Data") {
                    LabeledContent("Data Freshness", value: storeManager.currentTier.dataDelay)
                    LabeledContent("Product Limit", value: "\(storeManager.currentTier.maxProducts)")
                    LabeledContent("Alert Limit", value: "\(storeManager.currentTier.maxAlerts)")
                }

                // MARK: - About
                Section("About") {
                    LabeledContent("Version", value: appVersionString)
                }

                // MARK: - Legal
                Section("Legal") {
                    Text("YieldSentinel provides risk analysis and scoring for informational purposes only. It is not investment advice. Past scoring accuracy does not guarantee future results. Always do your own research before making investment decisions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func openSubscriptionManagement() {
        #if os(iOS)
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
