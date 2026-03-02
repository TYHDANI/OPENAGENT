import SwiftUI

struct SettingsView: View {
    @Environment(StoreManager.self) private var storeManager
    @EnvironmentObject var habitRepository: HabitRepository
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var showingPaywall = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        List {
            // Premium Section
            Section {
                if storeManager.isSubscribed {
                    SubscriptionStatusView()
                } else {
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upgrade to Pro")
                                    .font(.body)
                                    .fontWeight(.medium)

                                Text("Advanced analytics, themes & more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Notifications
            Section {
                Toggle("Gentle Reminders", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, enabled in
                        handleNotificationToggle(enabled)
                    }

                if notificationsEnabled && notificationStatus != .authorized {
                    Button("Enable in Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundStyle(.accent)
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Receive encouraging reminders for your habits")
            }

            // Data Management
            Section("Data") {
                if storeManager.isSubscribed {
                    Button {
                        exportData()
                    } label: {
                        Label("Export Progress Data", systemImage: "square.and.arrow.up")
                    }
                }

                NavigationLink {
                    ArchivedHabitsView(habitRepository: habitRepository)
                } label: {
                    Label("Archived Habits", systemImage: "archivebox")
                }
            }

            // Support
            Section("Support") {
                Link(destination: URL(string: "https://streamflow.app/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Link(destination: URL(string: "https://streamflow.app/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }

                Link(destination: URL(string: "mailto:support@streamflow.app")!) {
                    Label("Contact Support", systemImage: "envelope")
                }
            }

            // About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.appVersion)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    AboutView()
                } label: {
                    Label("About StreamFlow", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            await checkNotificationStatus()
        }
        .sheet(isPresented: $showingPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        Task {
            if enabled {
                let granted = await NotificationService.shared.requestPermission()
                if !granted {
                    await MainActor.run {
                        notificationsEnabled = false
                    }
                }
            } else {
                // Cancel all notifications
                await NotificationService.shared.cancelAllReminders()
            }
            await checkNotificationStatus()
        }
    }

    private func checkNotificationStatus() async {
        let status = await NotificationService.shared.checkPermissionStatus()
        await MainActor.run {
            notificationStatus = status
            if status != .authorized {
                notificationsEnabled = false
            }
        }
    }

    private func exportData() {
        // Pro feature - export CSV data
        // Implementation would go here
    }
}

// MARK: - Subscription Status View

struct SubscriptionStatusView: View {
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)

                Text("Pro Subscriber")
                    .font(.body)
                    .fontWeight(.medium)
            }

            if let product = storeManager.activeSubscription {
                Text(product.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Restore Purchases") {
                Task {
                    await storeManager.restorePurchases()
                }
            }
            .font(.caption)
            .foregroundStyle(.accent)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon and Name
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.accent)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 120, height: 120)
                        )

                    Text("StreamFlow")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("The habit tracker that won't judge you for being human")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Philosophy
                VStack(alignment: .leading, spacing: 12) {
                    Text("Our Philosophy")
                        .font(.headline)

                    Text("StreamFlow is designed around one core belief: progress matters more than perfection. We focus on your cumulative achievements, not streaks that reset when life gets in the way.")
                        .font(.body)

                    Text("Every completion counts. Miss a day? No problem. Your total progress is still there, celebrating every step you've taken on your journey.")
                        .font(.body)
                }
                .padding(.horizontal)

                // Features
                VStack(alignment: .leading, spacing: 12) {
                    Text("Features")
                        .font(.headline)

                    FeatureRow(icon: "infinity", title: "Unlimited Habits", description: "Track as many habits as you want, free forever")
                    FeatureRow(icon: "heart.fill", title: "Anxiety-Free", description: "No streak pressure, just cumulative progress")
                    FeatureRow(icon: "bell.badge", title: "Gentle Reminders", description: "Encouraging notifications that motivate, not guilt")
                    FeatureRow(icon: "icloud", title: "Sync Everywhere", description: "Your habits sync across all your devices")
                }
                .padding(.horizontal)

                // Credits
                VStack(spacing: 8) {
                    Text("Made with ❤️ by the StreamFlow team")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("© 2026 StreamFlow. All rights reserved.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.accent)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
    NavigationStack {
        SettingsView()
            .environment(StoreManager())
            .environmentObject(HabitRepository(persistenceController: .preview))
    }
}