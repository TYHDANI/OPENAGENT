import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                estateValueCard
                healthStatusCard
                accountsOverview
                allocationBreakdown
                quickActions
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .refreshable {
            await viewModel.syncAllAccounts()
        }
        .task {
            await viewModel.loadAccounts()
        }
        .overlay {
            if viewModel.isLoading && viewModel.accounts.isEmpty {
                ProgressView("Loading estate data...")
            }
        }
    }

    // MARK: - Estate Value Card

    private var estateValueCard: some View {
        VStack(spacing: 8) {
            Text("Total Estate Value")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(viewModel.totalEstateValue, format: .currency(code: "USD"))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .contentTransition(.numericText())

            if let lastSync = viewModel.lastSyncDate {
                Text("Last synced \(lastSync, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Health Status

    private var healthStatusCard: some View {
        HStack(spacing: 16) {
            Image(systemName: healthIcon)
                .font(.title2)
                .foregroundStyle(healthColor)
                .frame(width: 44, height: 44)
                .background(healthColor.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Estate Health")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(viewModel.overallHealthStatus.displayName)
                    .font(.headline)
            }

            Spacer()

            Text("\(viewModel.accounts.count)")
                .font(.title2.bold())
            Text("accounts")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Estate health: \(viewModel.overallHealthStatus.displayName), \(viewModel.accounts.count) accounts")
    }

    private var healthIcon: String {
        switch viewModel.overallHealthStatus {
        case .healthy: return "checkmark.shield.fill"
        case .warning: return "exclamationmark.shield.fill"
        case .critical: return "xmark.shield.fill"
        case .unknown: return "questionmark.shield"
        }
    }

    private var healthColor: Color {
        switch viewModel.overallHealthStatus {
        case .healthy: return .green
        case .warning: return .yellow
        case .critical: return .red
        case .unknown: return .gray
        }
    }

    // MARK: - Accounts Overview

    private var accountsOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected Accounts")
                .font(.headline)

            if viewModel.accounts.isEmpty {
                ContentUnavailableView(
                    "No Accounts Connected",
                    systemImage: "link.badge.plus",
                    description: Text("Connect your exchange accounts and wallets to monitor your estate.")
                )
                .frame(height: 150)
            } else {
                ForEach(viewModel.accounts) { account in
                    NavigationLink(value: account.id) {
                        accountRow(account)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func accountRow(_ account: Account) -> some View {
        HStack(spacing: 12) {
            Image(systemName: account.platform.iconSystemName)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.nickname)
                    .font(.subheadline.weight(.medium))
                Text(account.platform.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(account.totalValueUSD, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.medium))

                dormancyBadge(account.dormancyStatus)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func dormancyBadge(_ status: DormancyStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dormancyColor(status))
                .frame(width: 6, height: 6)
            Text(status.rawValue.capitalized)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func dormancyColor(_ status: DormancyStatus) -> Color {
        switch status {
        case .active: return .green
        case .warning: return .yellow
        case .dormant: return .red
        case .unknown: return .gray
        }
    }

    // MARK: - Allocation Breakdown

    private var allocationBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Asset Allocation")
                .font(.headline)

            if viewModel.allocationsByAsset.isEmpty {
                Text("No holdings data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.allocationsByAsset.prefix(5), id: \.symbol) { allocation in
                    HStack {
                        Text(allocation.symbol)
                            .font(.subheadline.weight(.medium))
                            .frame(width: 50, alignment: .leading)

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.blue.gradient)
                                .frame(width: geo.size.width * allocation.percentage / 100)
                        }
                        .frame(height: 8)

                        Text("\(allocation.percentage, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickActionButton(
                    title: "Check In",
                    icon: "checkmark.circle",
                    color: .green
                )

                quickActionButton(
                    title: "Sync All",
                    icon: "arrow.triangle.2.circlepath",
                    color: .blue
                )

                quickActionButton(
                    title: "Add Account",
                    icon: "plus.circle",
                    color: .purple
                )

                quickActionButton(
                    title: "View Activity",
                    icon: "clock.arrow.circlepath",
                    color: .orange
                )
            }
        }
    }

    private func quickActionButton(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}
