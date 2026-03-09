import SwiftUI

struct ActivityMonitorView: View {
    @State private var viewModel = ActivityViewModel()

    var body: some View {
        VStack(spacing: 0) {
            filterBar
                .padding(.horizontal)
                .padding(.vertical, 8)

            if viewModel.filteredTransactions.isEmpty {
                ContentUnavailableView(
                    "No Activity",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Transactions will appear here once your accounts are synced.")
                )
            } else {
                List {
                    if !viewModel.anomalies.isEmpty {
                        anomalySection
                    }
                    transactionsList
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Activity")
        .task {
            await viewModel.loadTransactions()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Date Range
                Menu {
                    ForEach(ActivityViewModel.DateRange.allCases) { range in
                        Button {
                            viewModel.selectedDateRange = range
                            viewModel.applyFilters()
                        } label: {
                            if viewModel.selectedDateRange == range {
                                Label(range.displayName, systemImage: "checkmark")
                            } else {
                                Text(range.displayName)
                            }
                        }
                    }
                } label: {
                    filterChip(
                        label: viewModel.selectedDateRange.displayName,
                        isActive: viewModel.selectedDateRange != .all
                    )
                }

                // Platform Filter
                if !viewModel.uniquePlatforms.isEmpty {
                    Menu {
                        Button {
                            viewModel.selectedPlatform = nil
                            viewModel.applyFilters()
                        } label: {
                            if viewModel.selectedPlatform == nil {
                                Label("All Platforms", systemImage: "checkmark")
                            } else {
                                Text("All Platforms")
                            }
                        }

                        ForEach(viewModel.uniquePlatforms) { platform in
                            Button {
                                viewModel.selectedPlatform = platform
                                viewModel.applyFilters()
                            } label: {
                                if viewModel.selectedPlatform == platform {
                                    Label(platform.displayName, systemImage: "checkmark")
                                } else {
                                    Text(platform.displayName)
                                }
                            }
                        }
                    } label: {
                        filterChip(
                            label: viewModel.selectedPlatform?.displayName ?? "Platform",
                            isActive: viewModel.selectedPlatform != nil
                        )
                    }
                }

                // Asset Filter
                if !viewModel.uniqueAssets.isEmpty {
                    Menu {
                        Button {
                            viewModel.selectedAsset = nil
                            viewModel.applyFilters()
                        } label: {
                            if viewModel.selectedAsset == nil {
                                Label("All Assets", systemImage: "checkmark")
                            } else {
                                Text("All Assets")
                            }
                        }

                        ForEach(viewModel.uniqueAssets, id: \.self) { asset in
                            Button {
                                viewModel.selectedAsset = asset
                                viewModel.applyFilters()
                            } label: {
                                if viewModel.selectedAsset == asset {
                                    Label(asset, systemImage: "checkmark")
                                } else {
                                    Text(asset)
                                }
                            }
                        }
                    } label: {
                        filterChip(
                            label: viewModel.selectedAsset ?? "Asset",
                            isActive: viewModel.selectedAsset != nil
                        )
                    }
                }
            }
        }
    }

    private func filterChip(label: String, isActive: Bool) -> some View {
        Text(label)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1), in: Capsule())
            .foregroundStyle(isActive ? .blue : .secondary)
    }

    // MARK: - Anomaly Section

    private var anomalySection: some View {
        Section {
            ForEach(viewModel.anomalies.prefix(3)) { tx in
                anomalyRow(tx)
            }
        } header: {
            Label("Anomalies Detected", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    private func anomalyRow(_ tx: ActivityTransaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.anomalyReason ?? "Unusual activity detected")
                    .font(.subheadline.weight(.medium))
                Text("\(tx.type.rawValue.capitalized) · \(tx.amount, specifier: "%.4f") \(tx.asset)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(tx.date, format: .relative(presentation: .named))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        Section {
            ForEach(viewModel.filteredTransactions) { tx in
                transactionRow(tx)
            }
        } header: {
            Text("All Transactions (\(viewModel.filteredTransactions.count))")
        }
    }

    private func transactionRow(_ tx: ActivityTransaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: transactionIcon(tx.type))
                .font(.title3)
                .foregroundStyle(transactionColor(tx.type))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.type.rawValue.capitalized)
                    .font(.subheadline.weight(.medium))
                Text(tx.platform.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(tx.amount, specifier: "%.4f") \(tx.asset)")
                    .font(.subheadline)
                Text(tx.valueUSD, format: .currency(code: "USD"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func transactionIcon(_ type: TransactionType) -> String {
        switch type {
        case .buy: return "arrow.down.circle"
        case .sell: return "arrow.up.circle"
        case .transfer: return "arrow.left.arrow.right"
        case .deposit: return "arrow.down.to.line"
        case .withdrawal: return "arrow.up.to.line"
        case .stake: return "lock.circle"
        case .unstake: return "lock.open"
        case .unknown: return "questionmark.circle"
        }
    }

    private func transactionColor(_ type: TransactionType) -> Color {
        switch type {
        case .buy, .deposit: return .green
        case .sell, .withdrawal: return .red
        case .transfer: return .blue
        case .stake, .unstake: return .purple
        case .unknown: return .gray
        }
    }
}
