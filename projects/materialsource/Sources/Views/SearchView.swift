import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel: SearchViewModel?
    @State private var featuredMaterials: [Material] = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark industrial background
                MSTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    if let viewModel = viewModel {
                        // Search bar and filters
                        VStack(spacing: 14) {
                            // Search field
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(MSTheme.accent)

                                TextField("Search by spec (AMS 4911) or name...", text: $viewModel.searchQuery)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(MSTheme.textPrimary)
                                    .autocorrectionDisabled()
                                    .onSubmit {
                                        performSearch()
                                    }

                                if !viewModel.searchQuery.isEmpty {
                                    Button {
                                        viewModel.clearSearch()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(MSTheme.textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: MSTheme.smallCornerRadius)
                                    .fill(MSTheme.surfaceElevated)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MSTheme.smallCornerRadius)
                                            .stroke(MSTheme.border, lineWidth: 0.5)
                                    )
                            )

                            // Category filter chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(viewModel.categories, id: \.self) { category in
                                        ThemedCategoryChip(
                                            title: category,
                                            icon: MSTheme.categoryIcon(category),
                                            color: MSTheme.categoryColor(category),
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
                        .padding(.vertical, 14)
                        .padding(.horizontal)

                        // Content area
                        if viewModel.isSearching {
                            Spacer()
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(MSTheme.accent)
                                    .scaleEffect(1.2)
                                Text("Searching materials database...")
                                    .font(.subheadline)
                                    .foregroundStyle(MSTheme.textSecondary)
                            }
                            Spacer()
                        } else if viewModel.visibleResults.isEmpty && viewModel.hasSearched {
                            Spacer()
                            VStack(spacing: 20) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundStyle(MSTheme.textTertiary)

                                Text("No Results Found")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(MSTheme.textPrimary)

                                Text("Try a different specification, keyword, or category")
                                    .font(.subheadline)
                                    .foregroundStyle(MSTheme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 40)
                            Spacer()
                        } else if viewModel.visibleResults.isEmpty {
                            // Hero + featured content for first-time users
                            ScrollView {
                                VStack(alignment: .leading, spacing: MSTheme.sectionSpacing) {
                                    // Hero Section
                                    heroSection

                                    // Quick Stats Row
                                    quickStatsRow

                                    // Featured Materials
                                    if !featuredMaterials.isEmpty {
                                        VStack(alignment: .leading, spacing: MSTheme.itemSpacing) {
                                            MSSectionHeader(
                                                title: "Featured Materials",
                                                icon: "star.fill",
                                                color: MSTheme.warning
                                            )
                                            .padding(.horizontal)

                                            LazyVStack(spacing: MSTheme.itemSpacing) {
                                                ForEach(featuredMaterials) { material in
                                                    NavigationLink(destination: MaterialDetailView(material: material)) {
                                                        ThemedMaterialRow(material: material, isProUser: viewModel.isProUser)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }

                                    // Browse by Category
                                    VStack(alignment: .leading, spacing: MSTheme.itemSpacing) {
                                        MSSectionHeader(
                                            title: "Browse by Category",
                                            icon: "square.grid.2x2.fill",
                                            color: MSTheme.accent
                                        )
                                        .padding(.horizontal)

                                        LazyVGrid(columns: [
                                            GridItem(.flexible(), spacing: MSTheme.itemSpacing),
                                            GridItem(.flexible(), spacing: MSTheme.itemSpacing)
                                        ], spacing: MSTheme.itemSpacing) {
                                            ForEach(viewModel.categories, id: \.self) { category in
                                                CategoryBrowseCard(
                                                    category: category,
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
                            }
                        } else {
                            // Search results
                            ScrollView {
                                VStack(alignment: .leading, spacing: MSTheme.itemSpacing) {
                                    // Results count badge
                                    HStack {
                                        MSBadge(
                                            text: "\(viewModel.visibleResults.count) results",
                                            color: MSTheme.accent,
                                            style: .subtle
                                        )
                                        Spacer()
                                    }
                                    .padding(.horizontal)

                                    LazyVStack(spacing: MSTheme.itemSpacing) {
                                        ForEach(viewModel.visibleResults) { material in
                                            NavigationLink(destination: MaterialDetailView(material: material)) {
                                                ThemedMaterialRow(material: material, isProUser: viewModel.isProUser)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.vertical)
                            }
                        }

                        // Pro upsell banner
                        if !viewModel.isProUser && viewModel.hasSearched && viewModel.searchResults.contains(where: { $0.suppliers.count > 3 }) {
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(MSTheme.warning)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unlock All Suppliers")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(MSTheme.textPrimary)
                                    Text("See every supplier and unlimited RFQs")
                                        .font(.caption)
                                        .foregroundStyle(MSTheme.textSecondary)
                                }
                                Spacer()
                                NavigationLink(destination: PaywallView()) {
                                    Text("Go Pro")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(MSTheme.accent)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(MSTheme.cardPadding)
                            .background(MSTheme.surfaceElevated)
                            .overlay(
                                Rectangle()
                                    .fill(MSTheme.accent)
                                    .frame(height: 2),
                                alignment: .top
                            )
                        }
                    }
                }
            }
            .navigationTitle("Materials")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                setupViewModel()
                Task {
                    featuredMaterials = await MaterialService(modelContext: modelContext).getFeaturedMaterials()
                }
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 20) {
            // Industrial graphic
            ZStack {
                Circle()
                    .fill(MSTheme.accent.opacity(0.08))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(MSTheme.accent.opacity(0.15))
                    .frame(width: 70, height: 70)

                Image(systemName: "atom")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(MSTheme.accent)
            }

            VStack(spacing: 8) {
                Text("Search 8,000+ Industrial Materials")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(MSTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Aerospace alloys, composites, ceramics, and more.\nCompare suppliers. Request quotes instantly.")
                    .font(.subheadline)
                    .foregroundStyle(MSTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Spec hint chips
            HStack(spacing: 8) {
                SpecHintChip(text: "AMS 4911")
                SpecHintChip(text: "Ti-6Al-4V")
                SpecHintChip(text: "Inconel 718")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Quick Stats

    private var quickStatsRow: some View {
        HStack(spacing: MSTheme.itemSpacing) {
            QuickStatCard(
                icon: "cube.fill",
                value: "8,000+",
                label: "Materials",
                color: MSTheme.accent
            )
            QuickStatCard(
                icon: "building.2.fill",
                value: "500+",
                label: "Suppliers",
                color: MSTheme.success
            )
            QuickStatCard(
                icon: "doc.text.fill",
                value: "12,000+",
                label: "Specs",
                color: MSTheme.warning
            )
        }
        .padding(.horizontal)
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

// MARK: - Themed Category Chip

struct ThemedCategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : MSTheme.surfaceElevated)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? color : MSTheme.border, lineWidth: isSelected ? 0 : 0.5)
                    )
            )
            .foregroundStyle(isSelected ? .white : MSTheme.textSecondary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Spec Hint Chip

struct SpecHintChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(MSTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(MSTheme.accent.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(MSTheme.accent.opacity(0.3), lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Category Browse Card

struct CategoryBrowseCard: View {
    let category: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: MSTheme.categoryIcon(category))
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(MSTheme.categoryGradient(category))
                    )
                    .shadow(color: MSTheme.categoryColor(category).opacity(0.3), radius: 8, y: 4)

                Text(category)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(MSTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: MSTheme.cornerRadius)
                    .fill(MSTheme.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: MSTheme.cornerRadius)
                            .stroke(MSTheme.border, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Themed Material Row

struct ThemedMaterialRow: View {
    let material: Material
    let isProUser: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Material icon with category color
            Image(systemName: MSTheme.categoryIcon(material.category))
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(MSTheme.categoryGradient(material.category))
                )
                .shadow(color: MSTheme.categoryColor(material.category).opacity(0.25), radius: 6, y: 3)

            // Material info
            VStack(alignment: .leading, spacing: 5) {
                Text(material.name)
                    .font(.headline)
                    .foregroundStyle(MSTheme.textPrimary)

                if !material.specifications.isEmpty {
                    Text(material.specifications.map(\.fullSpec).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(MSTheme.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    let supplierCount = material.suppliers.count
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.caption2)
                        if !isProUser && supplierCount > 3 {
                            Text("\(supplierCount) (\(3) shown)")
                                .font(.caption2)
                        } else {
                            Text("\(supplierCount) supplier\(supplierCount == 1 ? "" : "s")")
                                .font(.caption2)
                        }
                    }
                    .foregroundStyle(MSTheme.textSecondary)

                    if let firstSupplier = material.suppliers.first,
                       let priceRange = firstSupplier.priceRange {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle")
                                .font(.caption2)
                            Text(priceRange.displayRange)
                                .font(.caption2)
                        }
                        .foregroundStyle(MSTheme.success)
                    }
                }
            }

            Spacer()

            // Category badge
            MSBadge(
                text: material.category.components(separatedBy: " ").first ?? material.category,
                color: MSTheme.categoryColor(material.category),
                style: .subtle
            )
        }
        .padding(MSTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: MSTheme.cornerRadius)
                .fill(MSTheme.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: MSTheme.cornerRadius)
                        .stroke(MSTheme.border, lineWidth: 0.5)
                )
        )
    }
}

// Keep old CategoryChip for backward compatibility if referenced elsewhere
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        ThemedCategoryChip(
            title: title,
            icon: MSTheme.categoryIcon(title),
            color: MSTheme.categoryColor(title),
            isSelected: isSelected,
            action: action
        )
    }
}

// Keep old MaterialRow for backward compatibility if referenced elsewhere
struct MaterialRow: View {
    let material: Material
    let isProUser: Bool

    var body: some View {
        ThemedMaterialRow(material: material, isProUser: isProUser)
    }
}

#Preview {
    SearchView()
        .environment(StoreManager())
        .modelContainer(for: [Material.self, Supplier.self])
}
