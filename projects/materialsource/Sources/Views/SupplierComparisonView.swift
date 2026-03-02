import SwiftUI

struct SupplierComparisonView: View {
    @Environment(\.dismiss) private var dismiss

    let material: Material
    let suppliers: [Supplier]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Material header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(material.name)
                                .font(.headline)

                            Text(material.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("\(suppliers.count) Suppliers")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(Capsule())
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Comparison table
                    VStack(spacing: 0) {
                        // Header row
                        ComparisonHeaderRow()

                        Divider()

                        // Supplier rows
                        ForEach(suppliers) { supplier in
                            SupplierComparisonRow(supplier: supplier)
                            if supplier.id != suppliers.last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Certifications comparison
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Certifications")
                            .font(.headline)

                        ForEach(suppliers) { supplier in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(supplier.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    if supplier.verified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                }

                                if supplier.certifications.isEmpty {
                                    Text("No certifications listed")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(supplier.certifications, id: \.self) { cert in
                                                Text(cert)
                                                    .font(.caption)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color(.tertiarySystemGroupedBackground))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Quick actions
                    VStack(spacing: 12) {
                        Text("Request quotes from all suppliers?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        NavigationLink(destination: BatchRFQView(material: material, suppliers: suppliers)) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Request Multiple Quotes")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Compare Suppliers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ComparisonHeaderRow: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Supplier")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
                .padding(.horizontal, 12)

            Divider()

            ComparisonHeaderItem(title: "Price", icon: "dollarsign.circle")
            Divider()
            ComparisonHeaderItem(title: "Lead Time", icon: "clock")
            Divider()
            ComparisonHeaderItem(title: "Min Order", icon: "cube.box")
            Divider()
            ComparisonHeaderItem(title: "Rating", icon: "star")
        }
        .frame(height: 40)
        .background(Color(.tertiarySystemGroupedBackground))
    }
}

struct ComparisonHeaderItem: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }
}

struct SupplierComparisonRow: View {
    let supplier: Supplier

    var body: some View {
        HStack(spacing: 0) {
            // Supplier name
            VStack(alignment: .leading, spacing: 2) {
                Text(supplier.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(supplier.location)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, alignment: .leading)
            .padding(.horizontal, 12)

            Divider()

            // Price
            if let priceRange = supplier.priceRange {
                Text(priceRange.displayRange)
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Contact")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }

            Divider()

            // Lead time
            Text(supplier.leadTimeRange)
                .font(.caption)
                .frame(maxWidth: .infinity)

            Divider()

            // Min order
            Text(supplier.minimumOrderQuantity)
                .font(.caption)
                .frame(maxWidth: .infinity)

            Divider()

            // Rating
            if let rating = supplier.rating {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 50)
    }
}

// Placeholder for batch RFQ view
struct BatchRFQView: View {
    let material: Material
    let suppliers: [Supplier]

    var body: some View {
        Text("Batch RFQ functionality coming soon")
            .navigationTitle("Request Multiple Quotes")
    }
}

#Preview {
    SupplierComparisonView(
        material: Material(
            name: "Ti-6Al-4V",
            category: "Titanium Alloys",
            descriptionText: "Premium titanium alloy"
        ),
        suppliers: [
            Supplier(
                name: "Supplier A",
                location: "USA",
                leadTimeRange: "2-4 weeks",
                minimumOrderQuantity: "10 lbs",
                verified: true
            ),
            Supplier(
                name: "Supplier B",
                location: "Germany",
                leadTimeRange: "1-3 weeks",
                minimumOrderQuantity: "5 kg",
                verified: true
            )
        ]
    )
}