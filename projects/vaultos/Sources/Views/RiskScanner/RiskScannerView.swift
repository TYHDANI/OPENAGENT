import SwiftUI

struct RiskScannerView: View {
    @State private var vm = RiskScannerViewModel()
    @Environment(PersistenceService.self) private var persistence

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    headerStats
                    filterBar
                    ForEach(vm.filteredProducts) { product in
                        NavigationLink(value: product.id) {
                            ProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Risk Scanner")
            .searchable(text: $vm.searchText, prompt: "Search protocols...")
            .navigationDestination(for: UUID.self) { id in
                if let product = vm.products.first(where: { $0.id == id }) {
                    ProductDetailView(product: product)
                }
            }
            .onAppear {
                vm.loadProducts(from: persistence)
                vm.refreshScores()
            }
        }
    }

    private var headerStats: some View {
        HStack(spacing: 12) {
            StatCard(title: "Protocols", value: "\(vm.products.count)", icon: "shield.checkered")
            StatCard(title: "Avg Score", value: vm.products.isEmpty ? "—" :
                        "\(vm.products.map(\.sentinelScore).reduce(0, +) / vm.products.count)", icon: "chart.bar")
            StatCard(title: "High Risk", value: "\(vm.products.filter { $0.riskLevel == .high || $0.riskLevel == .critical }.count)",
                     icon: "exclamationmark.triangle")
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("All") { vm.selectedCategory = nil }
                    ForEach(ProductCategory.allCases, id: \.self) { cat in
                        Button(cat.rawValue) { vm.selectedCategory = cat }
                    }
                } label: {
                    FilterChip(label: vm.selectedCategory?.rawValue ?? "Category", isActive: vm.selectedCategory != nil)
                }
                Menu {
                    Button("All") { vm.selectedChain = nil }
                    ForEach(vm.availableChains, id: \.self) { chain in
                        Button(chain) { vm.selectedChain = chain }
                    }
                } label: {
                    FilterChip(label: vm.selectedChain ?? "Chain", isActive: vm.selectedChain != nil)
                }
                Menu {
                    ForEach(RiskScannerViewModel.SortOption.allCases, id: \.self) { opt in
                        Button(opt.rawValue) { vm.sortBy = opt }
                    }
                } label: {
                    FilterChip(label: "Sort: \(vm.sortBy.rawValue)", isActive: true)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.accent)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard()
    }
}

struct FilterChip: View {
    let label: String
    let isActive: Bool

    var body: some View {
        Text(label)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? AppColors.accent.opacity(0.2) : Color.white.opacity(0.05))
            .foregroundStyle(isActive ? AppColors.accent : .secondary)
            .clipShape(Capsule())
    }
}
