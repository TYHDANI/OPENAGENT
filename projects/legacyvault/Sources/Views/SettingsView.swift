import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        List {
            subscriptionSection
            accountStatsSection
            notificationsSection
            securitySection
            aboutSection
        }
        .navigationTitle("Settings")
        .task {
            await viewModel.loadSettings()
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section("Subscription") {
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
            } else {
                NavigationLink {
                    PaywallView()
                } label: {
                    Label("Upgrade to Premium", systemImage: "star.fill")
                        .foregroundStyle(.blue)
                }
            }

            Button("Restore Purchases") {
                Task { await storeManager.restorePurchases() }
            }
        }
    }

    // MARK: - Account Stats

    private var accountStatsSection: some View {
        Section("Your Estate") {
            LabeledContent("Connected Accounts", value: "\(viewModel.accountCount)")
            LabeledContent("Beneficiaries", value: "\(viewModel.beneficiaryCount)")
            LabeledContent("Current Tier", value: viewModel.currentTier.displayName)

            if !storeManager.isSubscribed {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("Free tier: \(SubscriptionTier.free.maxAccounts) accounts, \(SubscriptionTier.free.maxBeneficiaries) beneficiary")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                .onChange(of: viewModel.notificationsEnabled) { _, enabled in
                    if enabled {
                        Task { await viewModel.requestNotificationPermission() }
                    }
                }

            if viewModel.notificationsEnabled {
                Toggle("Dormancy Alerts", isOn: $viewModel.dormancyAlertsEnabled)
                Toggle("Security Alerts", isOn: $viewModel.securityAlertsEnabled)
                Toggle("Portfolio Alerts", isOn: $viewModel.portfolioAlertsEnabled)
            }
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        Section("Security") {
            HStack {
                Label("Keychain Encryption", systemImage: "lock.shield")
                Spacer()
                Text("Active")
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            HStack {
                Label("API Key Storage", systemImage: "key.fill")
                Spacer()
                Text("On-Device Only")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.appVersion)

            NavigationLink("Privacy Policy") {
                Text("Privacy Policy content would be displayed here.")
                    .padding()
                    .navigationTitle("Privacy Policy")
            }

            NavigationLink("Terms of Service") {
                Text("Terms of Service content would be displayed here.")
                    .padding()
                    .navigationTitle("Terms of Service")
            }

            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text("This app does not constitute legal or tax advice.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
