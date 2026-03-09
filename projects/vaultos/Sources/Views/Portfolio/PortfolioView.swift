import SwiftUI

struct PortfolioView: View {
    @State private var vm = PortfolioViewModel()
    @Environment(PersistenceService.self) private var persistence

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Total value
                    VStack(spacing: 4) {
                        Text("Total Value").font(.caption).foregroundStyle(.secondary)
                        Text(formatCurrency(vm.totalPortfolioValue))
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(AppColors.accent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassCard()

                    // Entity picker
                    entityPicker

                    // Holdings breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Holdings").font(.headline)
                        ForEach(vm.holdingsByAsset, id: \.asset) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.asset).font(.headline)
                                    Text(String(format: "%.4f", item.quantity))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(formatCurrency(item.value))
                                    .font(.subheadline.bold())
                            }
                            .padding(.vertical, 4)
                            if item.asset != vm.holdingsByAsset.last?.asset {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .glassCard()

                    // Accounts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accounts").font(.headline)
                        ForEach(vm.filteredAccounts) { account in
                            HStack {
                                Image(systemName: "building.columns")
                                    .foregroundStyle(AppColors.accent)
                                VStack(alignment: .leading) {
                                    Text(account.accountName).font(.subheadline.bold())
                                    Text(account.custodian.rawValue).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(formatCurrency(account.totalValue)).font(.subheadline.bold())
                                    Text("\(account.holdings.count) assets").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .glassCard()
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Portfolio")
            .onAppear { vm.load(from: persistence) }
        }
    }

    private var entityPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.entities) { entity in
                    Button {
                        vm.selectedEntityID = entity.id
                    } label: {
                        Text(entity.name)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(vm.selectedEntityID == entity.id ? AppColors.accent : Color.white.opacity(0.05))
                            .foregroundStyle(vm.selectedEntityID == entity.id ? .black : .secondary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
