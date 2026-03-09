import SwiftUI

struct EntityDetailView: View {
    let entity: LegalEntity
    @Environment(EntityViewModel.self) private var entityVM
    @Environment(TransactionViewModel.self) private var transactionVM
    @Environment(TaxViewModel.self) private var taxVM
    @State private var showAddAccount = false

    private var entityAccounts: [CustodialAccount] {
        entityVM.accounts(for: entity.id)
    }

    private var entityLots: [TaxLot] {
        transactionVM.taxLots.filter { $0.entityID == entity.id && !$0.isDisposed }
    }

    var body: some View {
        List {
            Section("Entity Details") {
                LabeledContent("Type", value: entity.entityType.rawValue)
                LabeledContent("Tax Treatment", value: entity.taxTreatment.rawValue)
                LabeledContent("Cost Basis Method", value: entity.costBasisMethod.rawValue)
                LabeledContent("Fiscal Year End", value: entity.fiscalYearEnd.rawValue)
                if !entity.ein.isEmpty {
                    LabeledContent("EIN/SSN", value: entity.ein)
                }
            }

            if let parent = entityVM.parentEntity(of: entity) {
                Section("Ownership") {
                    LabeledContent("Parent Entity", value: parent.name)
                    if let pct = entity.ownershipPercentage {
                        LabeledContent("Ownership %", value: "\(String(format: "%.1f", pct))%")
                    }
                }
            }

            let children = entityVM.childEntities(of: entity.id)
            if !children.isEmpty {
                Section("Subsidiary Entities") {
                    ForEach(children) { child in
                        NavigationLink(value: child) {
                            Label(child.name, systemImage: child.entityType.icon)
                        }
                    }
                }
            }

            Section {
                ForEach(entityAccounts) { account in
                    HStack {
                        Image(systemName: account.custodian.icon)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(account.accountName)
                                .font(.body)
                            Text(account.custodian.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusBadge(status: account.connectionStatus)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            await entityVM.deleteAccount(entityAccounts[index])
                        }
                    }
                }

                Button {
                    showAddAccount = true
                } label: {
                    Label("Add Account", systemImage: "plus.circle")
                }
            } header: {
                Text("Connected Accounts (\(entityAccounts.count))")
            }

            Section("Holdings") {
                if entityLots.isEmpty {
                    Text("No holdings")
                        .foregroundStyle(.secondary)
                } else {
                    let grouped = Dictionary(grouping: entityLots, by: \.asset)
                    ForEach(grouped.keys.sorted(), id: \.self) { asset in
                        let lots = grouped[asset] ?? []
                        let totalQty = lots.reduce(0) { $0 + $1.quantity }
                        let totalCost = lots.reduce(0) { $0 + $1.totalCostBasis }
                        HStack {
                            Text(asset)
                                .fontWeight(.medium)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(String(format: "%.6f", totalQty))
                                    .font(.subheadline)
                                Text("Cost: \(ReportGenerator.formatCurrency(totalCost))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            let estimates = taxVM.estimates(for: entity.id)
            if !estimates.isEmpty {
                Section("Quarterly Tax Estimates") {
                    ForEach(estimates) { estimate in
                        HStack {
                            Text(estimate.quarter.rawValue)
                                .fontWeight(.medium)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(ReportGenerator.formatCurrency(estimate.estimatedTaxOwed))
                                    .font(.subheadline)
                                Text("Due: \(estimate.quarter.estimatedPaymentDeadline)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            let alerts = taxVM.alerts(for: entity.id)
            if !alerts.isEmpty {
                Section("Wash Sale Alerts") {
                    ForEach(alerts) { alert in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            VStack(alignment: .leading) {
                                Text("\(alert.asset) — \(alert.daysApart) days apart")
                                    .font(.subheadline)
                                Text("Disallowed: \(ReportGenerator.formatCurrency(alert.disallowedLoss))")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(entity.name)
        .sheet(isPresented: $showAddAccount) {
            AddAccountSheet(entityID: entity.id)
        }
    }
}

struct StatusBadge: View {
    let status: ConnectionStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch status {
        case .connected: return .green
        case .disconnected: return .gray
        case .error: return .red
        case .pending: return .orange
        }
    }
}
