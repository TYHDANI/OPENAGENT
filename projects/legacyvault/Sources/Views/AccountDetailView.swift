import SwiftUI

struct AccountDetailView: View {
    let account: Account

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                holdingsList
                dormancySection
                dangerZone
            }
            .padding()
        }
        .navigationTitle(account.nickname)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: account.platform.iconSystemName)
                .font(.largeTitle)
                .foregroundStyle(.blue)

            Text(account.platform.displayName)
                .font(.headline)

            Text(account.totalValueUSD, format: .currency(code: "USD"))
                .font(.system(size: 32, weight: .bold, design: .rounded))

            HStack(spacing: 16) {
                statusPill(
                    label: "Status",
                    value: account.isConnected ? "Connected" : "Disconnected",
                    color: account.isConnected ? .green : .red
                )

                statusPill(
                    label: "Dormancy",
                    value: account.dormancyStatus.rawValue.capitalized,
                    color: dormancyStatusColor
                )
            }

            if let lastActivity = account.lastActivityDate {
                Text("Last activity: \(lastActivity, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let lastSync = account.lastSyncDate {
                Text("Last synced: \(lastSync, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func statusPill(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.15), in: Capsule())
        }
    }

    private var dormancyStatusColor: Color {
        switch account.dormancyStatus {
        case .active: return .green
        case .warning: return .yellow
        case .dormant: return .red
        case .unknown: return .gray
        }
    }

    // MARK: - Holdings

    private var holdingsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Holdings")
                .font(.headline)

            if account.holdings.isEmpty {
                Text("No holdings data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(account.holdings) { holding in
                    holdingRow(holding)
                    if holding.id != account.holdings.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func holdingRow(_ holding: Holding) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol)
                    .font(.subheadline.weight(.medium))
                Text(holding.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.valueUSD, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.medium))
                Text("\(holding.quantity, specifier: "%.6f") \(holding.symbol)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Dormancy

    private var dormancySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dormancy Monitor")
                .font(.headline)

            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(.orange)
                Text("Dormancy timer: \(account.dormancyDays) days")
                    .font(.subheadline)
            }

            if account.dormancyDays > 30 {
                Text("This account has been inactive for over 30 days. Consider verifying access.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Management")
                .font(.headline)

            if let error = account.connectionError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
