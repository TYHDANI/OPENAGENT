import SwiftUI

struct RFQDetailView: View {
    let rfq: RFQ

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Status Header
                HStack {
                    StatusBadge(status: rfq.status)
                    Spacer()
                    Text("ID: \(rfq.id.prefix(8))...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Material & Supplier Info
                VStack(spacing: 16) {
                    DetailCard(
                        title: "Material",
                        icon: "cube.fill"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(rfq.material.name)
                                .font(.headline)

                            if !rfq.material.specifications.isEmpty {
                                Text(rfq.material.specifications.map(\.fullSpec).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    DetailCard(
                        title: "Supplier",
                        icon: "building.2.fill"
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(rfq.supplier.name)
                                .font(.headline)

                            HStack(spacing: 16) {
                                Label(rfq.supplier.location, systemImage: "location")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if rfq.supplier.verified {
                                    Label("Verified", systemImage: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                // Request Details
                DetailCard(
                    title: "Request Details",
                    icon: "doc.text.fill"
                ) {
                    VStack(spacing: 12) {
                        DetailRow(label: "Quantity", value: "\(rfq.quantity) \(rfq.unit)")
                        DetailRow(label: "Submitted", value: formatDate(rfq.submittedDate))

                        if let targetDate = rfq.targetDeliveryDate {
                            DetailRow(label: "Target Delivery", value: formatDate(targetDate))
                        }

                        if !rfq.specifications.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Specifications")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(rfq.specifications)
                                    .font(.subheadline)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }

                // Quote Details (if received)
                if let quote = rfq.quoteReceived {
                    DetailCard(
                        title: "Quote Received",
                        icon: "envelope.open.fill",
                        tintColor: .green
                    ) {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Unit Price")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(formatCurrency(quote.unitPrice))
                                        .font(.headline)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Total")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(formatCurrency(quote.totalPrice))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.green)
                                }
                            }

                            Divider()

                            DetailRow(label: "Lead Time", value: quote.leadTime)
                            DetailRow(label: "Valid Until", value: formatDate(quote.validUntil))
                            DetailRow(label: "Received", value: formatDate(quote.receivedDate))

                            if let terms = quote.termsAndConditions {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Terms & Conditions")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text(terms)
                                        .font(.caption)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.tertiarySystemGroupedBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }

                    // Action buttons for quoted RFQs
                    HStack(spacing: 12) {
                        Button {
                            // Accept quote action
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Accept Quote")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            // Decline quote action
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Decline")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                // Notes section
                if let notes = rfq.notes, !notes.isEmpty {
                    DetailCard(
                        title: "Notes",
                        icon: "note.text"
                    ) {
                        Text(notes)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("RFQ Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct DetailCard<Content: View>: View {
    let title: String
    let icon: String
    var tintColor: Color = .accentColor
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tintColor)
                Text(title)
                    .font(.headline)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        RFQDetailView(
            rfq: RFQ(
                material: Material(
                    name: "Ti-6Al-4V",
                    category: "Titanium Alloys",
                    descriptionText: "Premium titanium alloy"
                ),
                supplier: Supplier(
                    name: "Test Supplier",
                    location: "USA",
                    leadTimeRange: "2-4 weeks",
                    minimumOrderQuantity: "10 lbs"
                ),
                quantity: "100",
                unit: "kg",
                specifications: "Need aerospace grade with certifications"
            )
        )
    }
}