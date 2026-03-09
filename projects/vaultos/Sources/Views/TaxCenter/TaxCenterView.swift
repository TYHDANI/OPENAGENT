import SwiftUI

struct TaxCenterView: View {
    @State private var vm = TaxCenterViewModel()
    @Environment(PersistenceService.self) private var persistence
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        TaxStatCard(title: "Realized Gains", value: formatCurrency(vm.totalRealizedGains),
                                    color: vm.totalRealizedGains >= 0 ? AppColors.success : AppColors.danger)
                        TaxStatCard(title: "Short-Term", value: formatCurrency(vm.shortTermGains),
                                    color: .orange)
                        TaxStatCard(title: "Long-Term", value: formatCurrency(vm.longTermGains),
                                    color: AppColors.accent)
                        TaxStatCard(title: "Wash Sales", value: "\(vm.activeWashSales.count)",
                                    color: vm.activeWashSales.isEmpty ? AppColors.success : AppColors.danger)
                    }
                    .padding()
                }

                Picker("Tab", selection: $selectedTab) {
                    Text("Tax Lots").tag(0)
                    Text("Wash Sales").tag(1)
                    Text("Quarterly").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    switch selectedTab {
                    case 0: taxLotsView
                    case 1: washSalesView
                    case 2: quarterlyView
                    default: EmptyView()
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle("Tax Center")
            .onAppear { vm.load(from: persistence, entities: persistence.entities) }
        }
    }

    private var taxLotsView: some View {
        LazyVStack(spacing: 8) {
            if vm.filteredLots.isEmpty {
                ContentUnavailableView("No Tax Lots", systemImage: "doc.text",
                                       description: Text("Tax lots will appear as you add transactions"))
                    .padding(.top, 40)
            }
            ForEach(vm.filteredLots) { lot in
                HStack {
                    VStack(alignment: .leading) {
                        Text(lot.asset).font(.headline)
                        Text(String(format: "%.4f units", lot.quantity)).font(.caption).foregroundStyle(.secondary)
                        Text(lot.acquisitionDate, style: .date).font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(formatCurrency(lot.totalCostBasis)).font(.subheadline.bold())
                        Text(lot.holdingPeriod.rawValue)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(lot.holdingPeriod == .longTerm ? AppColors.success : .orange)
                        if let gain = lot.gainLoss {
                            Text(formatCurrency(gain))
                                .font(.caption.bold())
                                .foregroundStyle(gain >= 0 ? AppColors.success : AppColors.danger)
                        }
                    }
                }
                .padding()
                .glassCard()
            }
        }
        .padding()
    }

    private var washSalesView: some View {
        LazyVStack(spacing: 8) {
            if vm.activeWashSales.isEmpty {
                ContentUnavailableView("No Wash Sales", systemImage: "checkmark.shield",
                                       description: Text("No wash sale violations detected"))
                    .padding(.top, 40)
            }
            ForEach(vm.activeWashSales) { alert in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppColors.danger)
                        Text(alert.asset).font(.headline)
                        Spacer()
                        Text(formatCurrency(alert.disallowedLoss))
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.danger)
                    }
                    HStack {
                        Text("Sold: \(alert.saleDate, style: .date)")
                        Spacer()
                        Text("Bought: \(alert.buyDate, style: .date)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Text("\(alert.daysApart) days apart")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .glassCard()
            }
        }
        .padding()
    }

    private var quarterlyView: some View {
        VStack(spacing: 12) {
            ForEach(Quarter.allCases, id: \.self) { q in
                let deadline = QuarterlyTaxCalculator.deadlines(for: vm.selectedYear)
                    .first { $0.0 == q }?.1 ?? Date()
                HStack {
                    VStack(alignment: .leading) {
                        Text(q.rawValue).font(.headline)
                        Text(deadline, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    let estimate = vm.quarterlyEstimates.first { $0.quarter == q }
                    Text(estimate.map { formatCurrency($0.estimatedTaxOwed) } ?? "—")
                        .font(.subheadline.bold())
                }
                .padding()
                .glassCard()
            }
        }
        .padding()
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct TaxStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(width: 120)
        .padding(.vertical, 12)
        .glassCard()
    }
}
