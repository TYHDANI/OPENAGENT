import SwiftUI

struct SettingsView: View {
    @Environment(WearableAggregatorService.self) private var service
    @State private var notificationsEnabled = true
    @State private var biometricLock = false
    @State private var dataShareLevel: DataShareLevel = .anonymized
    @State private var showDeleteConfirmation = false

    enum DataShareLevel: String, CaseIterable {
        case none = "None"
        case anonymized = "Anonymized"
        case full = "Full (with consent)"
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Account Section
                Section {
                    HStack(spacing: VDSpacing.md) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(VDColors.accentTeal)

                        VStack(alignment: .leading, spacing: VDSpacing.xxs) {
                            Text("VitalDAO User")
                                .font(VDTypography.cardTitle)
                                .foregroundStyle(VDColors.textPrimary)

                            Text("Free Tier")
                                .font(VDTypography.caption)
                                .foregroundStyle(VDColors.textSecondary)
                        }

                        Spacer()

                        Text("Upgrade")
                            .font(VDTypography.caption)
                            .foregroundStyle(VDColors.textInverse)
                            .padding(.horizontal, VDSpacing.md)
                            .padding(.vertical, VDSpacing.sm)
                            .background(VDColors.gradientTeal)
                            .clipShape(Capsule())
                    }
                    .listRowBackground(VDColors.surface)
                }

                // MARK: - Data & Privacy
                Section("Data & Privacy") {
                    Picker("Data Sharing", selection: $dataShareLevel) {
                        ForEach(DataShareLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .tint(VDColors.accentTeal)

                    Toggle("Biometric Lock", isOn: $biometricLock)
                        .tint(VDColors.accentTeal)

                    NavigationLink {
                        consentLogView
                    } label: {
                        Label("Consent Log", systemImage: "list.bullet.clipboard")
                    }

                    NavigationLink {
                        Text("Export data feature coming soon")
                            .foregroundStyle(VDColors.textSecondary)
                    } label: {
                        Label("Export My Data", systemImage: "square.and.arrow.up")
                    }
                }
                .listRowBackground(VDColors.surface)

                // MARK: - Notifications
                Section("Notifications") {
                    Toggle("Insight Alerts", isOn: $notificationsEnabled)
                        .tint(VDColors.accentTeal)

                    NavigationLink {
                        Text("Notification preferences coming soon")
                            .foregroundStyle(VDColors.textSecondary)
                    } label: {
                        Label("Alert Thresholds", systemImage: "bell.badge")
                    }
                }
                .listRowBackground(VDColors.surface)

                // MARK: - Connected Devices Summary
                Section("Devices") {
                    ForEach(service.connections.filter { $0.status == .connected }) { connection in
                        HStack(spacing: VDSpacing.md) {
                            Image(systemName: connection.provider.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(connection.provider.color)
                                .frame(width: 28, height: 28)
                                .background(connection.provider.color.opacity(0.12))
                                .clipShape(Circle())

                            Text(connection.provider.rawValue)
                                .font(VDTypography.body)
                                .foregroundStyle(VDColors.textPrimary)

                            Spacer()

                            Circle()
                                .fill(VDColors.successGreen)
                                .frame(width: 8, height: 8)
                        }
                    }

                    if service.connectedProviderCount == 0 {
                        Text("No devices connected")
                            .font(VDTypography.body)
                            .foregroundStyle(VDColors.textTertiary)
                    }
                }
                .listRowBackground(VDColors.surface)

                // MARK: - About
                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundStyle(VDColors.textPrimary)
                        Spacer()
                        Text("1.0.0 (1)")
                            .foregroundStyle(VDColors.textTertiary)
                    }

                    NavigationLink {
                        Text("Privacy policy coming soon")
                            .foregroundStyle(VDColors.textSecondary)
                    } label: {
                        Text("Privacy Policy")
                    }

                    NavigationLink {
                        Text("Terms of service coming soon")
                            .foregroundStyle(VDColors.textSecondary)
                    } label: {
                        Text("Terms of Service")
                    }

                    Link(destination: URL(string: "https://vitaldao.health")!) {
                        HStack {
                            Text("Website")
                                .foregroundStyle(VDColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(VDColors.accentTeal)
                        }
                    }
                }
                .listRowBackground(VDColors.surface)

                // MARK: - Danger Zone
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                            .foregroundStyle(VDColors.heartRed)
                    }
                }
                .listRowBackground(VDColors.surface)
            }
            .scrollContentBackground(.hidden)
            .background(VDColors.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove all your health data, device connections, and consent records. This action cannot be undone.")
            }
        }
    }

    // MARK: - Consent Log View

    @ViewBuilder
    private var consentLogView: some View {
        List {
            Section("On-Chain Consent Records") {
                consentRow(
                    action: "Data Sharing Enabled",
                    detail: "Anonymized metrics shared with research pool",
                    date: Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now,
                    txHash: "0x7a3f...b2c1"
                )

                consentRow(
                    action: "Study Enrollment",
                    detail: "HRV-Guided Training Study — Stanford",
                    date: Calendar.current.date(byAdding: .day, value: -12, to: .now) ?? .now,
                    txHash: "0x4e8d...91f7"
                )

                consentRow(
                    action: "Device Connected",
                    detail: "Apple Health — full metrics access",
                    date: Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now,
                    txHash: "0x1b5a...c3e8"
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(VDColors.background.ignoresSafeArea())
        .navigationTitle("Consent Log")
    }

    @ViewBuilder
    private func consentRow(action: String, detail: String, date: Date, txHash: String) -> some View {
        VStack(alignment: .leading, spacing: VDSpacing.sm) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(VDColors.accentPurple)

                Text(action)
                    .font(VDTypography.bodyBold)
                    .foregroundStyle(VDColors.textPrimary)

                Spacer()

                Text(date, format: .dateTime.month(.abbreviated).day())
                    .font(VDTypography.captionSmall)
                    .foregroundStyle(VDColors.textTertiary)
            }

            Text(detail)
                .font(VDTypography.caption)
                .foregroundStyle(VDColors.textSecondary)

            HStack(spacing: VDSpacing.xs) {
                Image(systemName: "link")
                    .font(.system(size: 10))
                Text(txHash)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(VDColors.accentTeal.opacity(0.6))
        }
        .listRowBackground(VDColors.surface)
    }
}

#Preview {
    SettingsView()
        .environment(WearableAggregatorService())
        .preferredColorScheme(.dark)
}
