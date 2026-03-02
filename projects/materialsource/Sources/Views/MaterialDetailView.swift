import SwiftUI
import SwiftData

struct MaterialDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel: MaterialDetailViewModel?

    let material: Material

    var body: some View {
        Group {
            if let viewModel = viewModel {
                detailContent(viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        setupViewModel()
                    }
            }
        }
        .navigationTitle(material.name)
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func detailContent(_ viewModel: MaterialDetailViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(material.category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())

                        Spacer()

                        Button {
                            Task { await viewModel.toggleFavorite() }
                        } label: {
                            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                                .foregroundStyle(viewModel.isFavorite ? .red : .secondary)
                        }
                    }

                    Text(material.descriptionText)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if !material.applications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Applications")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            ForEach(material.applications, id: \.self) { app in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    Text(app)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Specifications
                if !material.specifications.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Specifications", icon: "doc.text.fill")

                        ForEach(material.specifications) { spec in
                            SpecificationRow(specification: spec)
                        }
                    }
                }

                // Properties
                if !viewModel.groupedProperties.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Material Properties", icon: "wrench.and.screwdriver.fill")

                        ForEach(viewModel.groupedProperties, id: \.0) { category, properties in
                            PropertiesCard(category: category, properties: properties)
                        }
                    }
                }

                // Suppliers
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SectionHeader(title: "Suppliers", icon: "building.2.fill")

                        Spacer()

                        if viewModel.canCompareSuppliers {
                            Button("Compare") {
                                viewModel.compareSuppliers()
                            }
                            .font(.subheadline)
                            .foregroundStyle(.accentColor)
                        }
                    }

                    ForEach(viewModel.visibleSuppliers) { supplier in
                        SupplierCard(
                            supplier: supplier,
                            isSelected: viewModel.selectedSuppliers.contains(supplier),
                            canSelect: viewModel.isProUser || viewModel.selectedSuppliers.count < 1,
                            onToggle: { viewModel.toggleSupplierSelection(supplier) }
                        )
                    }

                    if viewModel.hasMoreSuppliers {
                        NavigationLink(destination: PaywallView()) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                Text("Unlock \(material.suppliers.count - 3) More Suppliers")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    // RFQ Button
                    if !viewModel.selectedSuppliers.isEmpty {
                        Button {
                            viewModel.startRFQ()
                        } label: {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Request Quote")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showingRFQSheet) {
            if let supplier = viewModel.selectedSuppliers.first {
                RFQFormView(material: material, supplier: supplier)
            }
        }
        .sheet(isPresented: $viewModel.showingComparisonView) {
            SupplierComparisonView(
                material: material,
                suppliers: Array(viewModel.selectedSuppliers)
            )
        }
        .task {
            await viewModel.loadFavoriteStatus()
            await viewModel.loadComparisons()
        }
    }

    private func setupViewModel() {
        let materialService = MaterialService(modelContext: modelContext)
        let rfqService = RFQService(modelContext: modelContext)
        viewModel = MaterialDetailViewModel(
            material: material,
            materialService: materialService,
            rfqService: rfqService,
            storeManager: storeManager
        )
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
        }
    }
}

struct SpecificationRow: View {
    let specification: Specification

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(specification.fullSpec)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(specification.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PropertiesCard: View {
    let category: PropertyCategory
    let properties: [MaterialProperty]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(properties) { property in
                    HStack {
                        Text(property.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(property.displayValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct SupplierCard: View {
    let supplier: Supplier
    let isSelected: Bool
    let canSelect: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(supplier.name)
                            .font(.headline)

                        if supplier.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }

                    HStack(spacing: 12) {
                        Label(supplier.location, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let rating = supplier.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                Button {
                    if canSelect || isSelected {
                        onToggle()
                    }
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .accentColor : .secondary)
                        .opacity(canSelect || isSelected ? 1 : 0.3)
                }
                .buttonStyle(.plain)
                .disabled(!canSelect && !isSelected)
            }

            // Details grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                DetailItem(label: "Lead Time", value: supplier.leadTimeRange)
                DetailItem(label: "Min Order", value: supplier.minimumOrderQuantity)

                if let priceRange = supplier.priceRange {
                    DetailItem(label: "Price Range", value: priceRange.displayRange)
                } else {
                    DetailItem(label: "Price", value: "Contact for pricing")
                }

                if !supplier.certifications.isEmpty {
                    DetailItem(label: "Certs", value: "\(supplier.certifications.count)")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
    }
}

struct DetailItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        MaterialDetailView(material: Material(
            name: "Ti-6Al-4V",
            category: "Titanium Alloys",
            descriptionText: "Premium titanium alloy"
        ))
        .environment(StoreManager())
        .modelContainer(for: [Material.self, Supplier.self])
    }
}