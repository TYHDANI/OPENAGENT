import SwiftUI

struct DashboardView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Portfolio Risk Summary
                if let weightedRisk = viewModel.portfolioWeightedRisk {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Portfolio Risk Score")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(weightedRisk))")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(colorForScore(Int(weightedRisk)))
                            }
                            Spacer()
                            ScoreGaugeView(score: Int(weightedRisk), size: 60)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: - Risk Distribution
                if !viewModel.products.isEmpty {
                    Section("Risk Overview") {
                        let dist = viewModel.riskDistribution
                        HStack(spacing: 12) {
                            ForEach(RiskLevel.allCases, id: \.self) { level in
                                if let count = dist[level], count > 0 {
                                    VStack(spacing: 4) {
                                        Text("\(count)")
                                            .font(.headline)
                                            .foregroundStyle(colorForRiskLevel(level))
                                        Text(level.rawValue)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: - Watchlist
                if !viewModel.watchlist.isEmpty {
                    Section("Watchlist") {
                        ForEach(viewModel.watchlist) { product in
                            NavigationLink(value: product) {
                                ProductCardView(
                                    product: product,
                                    isWatchlisted: true,
                                    onToggleWatchlist: { viewModel.toggleWatchlist(product.id) }
                                )
                            }
                        }
                    }
                }

                // MARK: - All Products
                Section {
                    let products = viewModel.visibleProducts(for: storeManager.currentTier)
                    if products.isEmpty && !viewModel.isLoading {
                        ContentUnavailableView(
                            "No Products Found",
                            systemImage: "magnifyingglass",
                            description: Text("Try adjusting your search or filters.")
                        )
                    } else {
                        ForEach(products) { product in
                            NavigationLink(value: product) {
                                ProductCardView(
                                    product: product,
                                    isWatchlisted: viewModel.isInWatchlist(product.id),
                                    onToggleWatchlist: { viewModel.toggleWatchlist(product.id) }
                                )
                            }
                        }
                    }

                    if storeManager.currentTier == .free && viewModel.filteredProducts.count > 10 {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Upgrade to see \(viewModel.filteredProducts.count - 10) more products")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                } header: {
                    HStack {
                        Text("All Products (\(viewModel.filteredProducts.count))")
                        Spacer()
                        if let lastUpdated = viewModel.lastUpdated {
                            Text(lastUpdated, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("YieldSentinel")
            .navigationDestination(for: YieldProduct.self) { product in
                ProductDetailView(product: product)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search protocols...")
            .refreshable {
                await viewModel.loadProducts()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }

                        Divider()

                        Menu("Filter by Category") {
                            Button("All Categories") {
                                viewModel.selectedCategory = nil
                            }
                            ForEach(ProductCategory.allCases, id: \.self) { cat in
                                Button {
                                    viewModel.selectedCategory = cat
                                } label: {
                                    Label(cat.rawValue, systemImage: cat.systemImage)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.products.isEmpty {
                    ProgressView("Loading protocols...")
                }
            }
            .task {
                await viewModel.loadProducts()
            }
        }
    }
}

// MARK: - Helpers

func colorForScore(_ score: Int) -> Color {
    switch score {
    case 75...100: return .green
    case 55..<75: return .yellow
    case 40..<55: return .orange
    case 20..<40: return .red
    default: return .red
    }
}

func colorForRiskLevel(_ level: RiskLevel) -> Color {
    switch level {
    case .low: return .green
    case .moderate: return .yellow
    case .elevated: return .orange
    case .high: return .red
    case .critical: return .red
    }
}
