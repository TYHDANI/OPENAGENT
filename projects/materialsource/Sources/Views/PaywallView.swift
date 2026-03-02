import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedProduct: Product?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Hero section
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.yellow.opacity(0.1))
                            )

                        Text("Upgrade to Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Unlock the full power of MaterialSource")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Benefits
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "building.2.fill",
                            title: "All Suppliers",
                            description: "Access every verified supplier for each material"
                        )

                        FeatureRow(
                            icon: "envelope.fill",
                            title: "Unlimited RFQs",
                            description: "Send unlimited quote requests every month"
                        )

                        FeatureRow(
                            icon: "chart.bar.fill",
                            title: "Price Comparisons",
                            description: "Compare suppliers side-by-side with detailed analytics"
                        )

                        FeatureRow(
                            icon: "doc.text.fill",
                            title: "Export Data",
                            description: "Download material specs and supplier data"
                        )

                        FeatureRow(
                            icon: "bell.fill",
                            title: "Quote Alerts",
                            description: "Get notified when suppliers respond to your RFQs"
                        )
                    }
                    .padding(.horizontal)

                    // Pricing options
                    VStack(spacing: 12) {
                        ForEach(storeManager.products.filter { product in
                            product.id == StoreManager.monthlyID ||
                            product.id == StoreManager.yearlyID
                        }) { product in
                            PricingCard(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                action: { selectedProduct = product }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // CTA Button
                    Button {
                        Task {
                            await subscribeToPro()
                        }
                    } label: {
                        HStack {
                            if storeManager.isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(storeManager.isPurchasing ? "Processing..." : "Start Free Trial")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedProduct != nil ? Color.accentColor : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedProduct == nil || storeManager.isPurchasing)
                    .padding(.horizontal)

                    // Terms
                    VStack(spacing: 8) {
                        Text("7-day free trial • Cancel anytime")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            Button("Restore Purchases") {
                                Task {
                                    await storeManager.restorePurchases()
                                }
                            }

                            Button("Privacy Policy") {
                                // Open privacy policy
                            }

                            Button("Terms of Use") {
                                // Open terms
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.accentColor)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pre-select yearly plan
            selectedProduct = storeManager.products.first { $0.id == StoreManager.yearlyID }
        }
        .alert("Purchase Error", isPresented: Binding<Bool>(
            get: { storeManager.errorMessage != nil },
            set: { _ in storeManager.errorMessage = nil }
        )) {
            Button("OK") {
                storeManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = storeManager.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func subscribeToPro() async {
        guard let product = selectedProduct else { return }

        let success = await storeManager.purchase(product)
        if success {
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void

    private var isYearly: Bool {
        product.id == StoreManager.yearlyID
    }

    private var savings: String? {
        guard isYearly else { return nil }
        // For yearly plans, show generic savings message
        return "Save 20%"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(isYearly ? "Annual" : "Monthly")
                                .font(.headline)

                            if isYearly {
                                Text("BEST VALUE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(product.displayPrice)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let savings = savings {
                            Text("Save \(savings)/year")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? .accentColor : .secondary)
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager())
}