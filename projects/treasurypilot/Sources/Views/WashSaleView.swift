import SwiftUI

struct WashSaleView: View {
    @Environment(EntityViewModel.self) private var entityVM
    @Environment(TransactionViewModel.self) private var transactionVM
    @Environment(TaxViewModel.self) private var taxVM
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        NavigationStack {
            Group {
                if !storeManager.currentTier.hasWashSaleDetection {
                    ContentUnavailableView(
                        "Wash Sale Detection",
                        systemImage: "lock.fill",
                        description: Text("Upgrade to Family Office or Enterprise to enable cross-entity wash sale detection.")
                    )
                } else if taxVM.washSaleAlerts.isEmpty {
                    ContentUnavailableView(
                        "No Wash Sales Detected",
                        systemImage: "checkmark.shield",
                        description: Text("No wash sale violations found across your entities.")
                    )
                } else {
                    List {
                        Section {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("\(taxVM.washSaleAlerts.count) Wash Sale Alert\(taxVM.washSaleAlerts.count == 1 ? "" : "s")")
                                        .fontWeight(.semibold)
                                    let totalDisallowed = taxVM.washSaleAlerts.reduce(0.0) { $0 + $1.disallowedLoss }
                                    Text("Total Disallowed: \(ReportGenerator.formatCurrency(totalDisallowed))")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }

                        ForEach(taxVM.washSaleAlerts) { alert in
                            WashSaleAlertRow(alert: alert, entities: entityVM.entities)
                        }
                    }
                }
            }
            .navigationTitle("Wash Sales")
            .toolbar {
                if storeManager.currentTier.hasWashSaleDetection {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                await taxVM.detectWashSales(
                                    transactions: transactionVM.transactions,
                                    lots: transactionVM.taxLots,
                                    entities: entityVM.entities
                                )
                            }
                        } label: {
                            Label("Scan", systemImage: "arrow.clockwise")
                        }
                        .accessibilityLabel("Scan for wash sales")
                    }
                }
            }
        }
    }
}

struct WashSaleAlertRow: View {
    let alert: WashSaleAlert
    let entities: [LegalEntity]

    private var saleEntityName: String {
        entities.first { $0.id == alert.saleEntityID }?.name ?? "Unknown"
    }

    private var buyEntityName: String {
        entities.first { $0.id == alert.buyEntityID }?.name ?? "Unknown"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(alert.asset)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(alert.daysApart) days apart")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Sale: \(saleEntityName)")
                        .font(.caption)
                    Text(alert.saleDate, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Buy: \(buyEntityName)")
                        .font(.caption)
                    Text(alert.buyDate, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("Disallowed Loss:")
                    .font(.caption)
                Text(ReportGenerator.formatCurrency(alert.disallowedLoss))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
                Spacer()
                if alert.isResolved {
                    Label("Resolved", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
