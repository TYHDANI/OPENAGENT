import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager

    @State private var selectedProduct: Product? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Features List
                    featuresSection

                    // Subscription Options
                    subscriptionOptions

                    // Restore Purchases
                    restoreButton

                    // Terms
                    termsSection
                }
                .padding()
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow.gradient)

            Text("Unlock DentiMatch Pro")
                .font(.title2)
                .fontWeight(.bold)

            Text("Streamline your dental practice with advanced features")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "mic.fill", title: "Voice Charting", description: "Hands-free dental charting with clinical terminology")
            FeatureRow(icon: "creditcard.fill", title: "CareCredit Integration", description: "Instant financing options for patients")
            FeatureRow(icon: "doc.text.fill", title: "Case Presentations", description: "Professional treatment plans with cost breakdowns")
            FeatureRow(icon: "lock.shield.fill", title: "HIPAA Compliance", description: "Encrypted storage and audit logging")
            FeatureRow(icon: "chart.bar.fill", title: "Practice Analytics", description: "Track case acceptance and revenue")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var subscriptionOptions: some View {
        VStack(spacing: 12) {
            if storeManager.products.isEmpty {
                // Show placeholder pricing when products haven't loaded
                SubscriptionCard(
                    title: "B2B Lite",
                    price: "$299/mo",
                    description: "Voice charting + basic case presentations",
                    isSelected: false
                ) { }

                SubscriptionCard(
                    title: "B2B Pro",
                    price: "$499/mo",
                    description: "All Lite features + financing bridge + analytics",
                    isSelected: false,
                    isRecommended: true
                ) { }
            } else {
                ForEach(storeManager.products, id: \.id) { product in
                    SubscriptionCard(
                        title: product.displayName,
                        price: product.displayPrice,
                        description: product.description,
                        isSelected: selectedProduct?.id == product.id,
                        isRecommended: product.id == StoreManager.b2bProMonthly
                    ) {
                        selectedProduct = product
                        purchaseProduct(product)
                    }
                }
            }
        }
    }

    private var restoreButton: some View {
        Button {
            Task {
                await storeManager.restorePurchases()
                if storeManager.isSubscribed {
                    dismiss()
                }
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
    }

    private var termsSection: some View {
        VStack(spacing: 4) {
            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("30-day free trial for new B2B subscribers")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func purchaseProduct(_ product: Product) {
        Task {
            let success = await storeManager.purchase(product)
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Subscription Card

private struct SubscriptionCard: View {
    let title: String
    let price: String
    let description: String
    let isSelected: Bool
    var isRecommended: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(title)
                                .font(.headline)

                            if isRecommended {
                                Text("RECOMMENDED")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }

                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : (isRecommended ? Color.blue.opacity(0.3) : Color.clear), lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager())
}
