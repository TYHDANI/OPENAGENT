import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel: SearchViewModel?
    @State private var featuredMaterials: [Material] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let viewModel = viewModel {
                    // Search bar and filters
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)

                            TextField("Search by spec (AMS 4911) or material name", text: $viewModel.searchQuery)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .onSubmit {
                                    performSearch()
                                }

                            if !viewModel.searchQuery.isEmpty {
                                Button {
                                    viewModel.clearSearch()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.categories, id: \.self) { category in
                                    CategoryChip(
                                        title: category,
                                        isSelected: viewModel.selectedCategory == category,
                                        action: {
                                            viewModel.selectedCategory = category
                                            performSearch()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground))

                    // Search results
                    if viewModel.isSearching {
                        Spacer()
                        ProgressView("Searching...")
                            .padding()
                        Spacer()
                    } else if viewModel.visibleResults.isEmpty && viewModel.hasSearched {
                        Spacer()
                        ContentUnavailableView {
                            Label("No Results", systemImage: "magnifyingglass")
                        } description: {
                            Text("Try a different specification or keyword")
                        }
                        Spacer()
                    } else if viewModel.visibleResults.isEmpty {
                        // Show featured materials when no search
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Featured Materials")
                                    .font(.headline)
                                    .padding(.horizontal)

                                LazyVStack(spacing: 12) {
                                    ForEach(featuredMaterials) { material in
                                        NavigationLink(destination: MaterialDetailView(material: material)) {
                                            MaterialRow(material: material, isProUser: viewModel.isProUser)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.visibleResults) { material in
                                    NavigationLink(destination: MaterialDetailView(material: material)) {
                                        MaterialRow(material: material, isProUser: viewModel.isProUser)
                                    }
                                }
                            }
                            .padding()
                        }
                    }

                    if !viewModel.isProUser && viewModel.hasSearched && viewModel.searchResults.contains(where: { $0.suppliers.count > 3 }) {
                        // Pro upsell banner
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Unlock All Suppliers")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("See all suppliers and unlimited RFQs")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            NavigationLink(destination: PaywallView()) {
                                Text("Go Pro")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                    }
                }
            }
            .navigationTitle("Search Materials")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                setupViewModel()
                Task {
                    featuredMaterials = await MaterialService(modelContext: modelContext).getFeaturedMaterials()
                }
            }
        }
    }

    private func setupViewModel() {
        let materialService = MaterialService(modelContext: modelContext)
        viewModel = SearchViewModel(materialService: materialService, storeManager: storeManager)
    }

    private func performSearch() {
        Task {
            await viewModel?.search()
        }
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct MaterialRow: View {
    let material: Material
    let isProUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Material icon
            Image(systemName: iconForCategory(material.category))
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Color.accentColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Material info
            VStack(alignment: .leading, spacing: 4) {
                Text(material.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if !material.specifications.isEmpty {
                    Text(material.specifications.map(\.fullSpec).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    let supplierCount = material.suppliers.count
                    if !isProUser && supplierCount > 3 {
                        Label("\(supplierCount) (\(3) shown)", systemImage: "building.2")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("\(supplierCount)", systemImage: "building.2")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let firstSupplier = material.suppliers.first,
                       let priceRange = firstSupplier.priceRange {
                        Text("• \(priceRange.displayRange)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Aerospace Alloys", "Titanium Alloys", "Nickel Alloys":
            return "airplane"
        case "Stainless Steels", "Aluminum Alloys":
            return "cube.fill"
        case "Composites":
            return "square.stack.3d.up.fill"
        case "Ceramics":
            return "hexagon.fill"
        case "Semiconductors":
            return "cpu"
        default:
            return "cube.transparent"
        }
    }
}

#Preview {
    SearchView()
        .environment(StoreManager())
        .modelContainer(for: [Material.self, Supplier.self])
}