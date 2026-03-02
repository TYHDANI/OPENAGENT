import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header
                    VStack(spacing: 16) {
                        Image(systemName: "rhombus.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Unlock GEM OS Pro")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Professional gemstone synthesis tools")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // MARK: - Features
                    FeaturesSection()

                    // MARK: - Subscription Options
                    VStack(spacing: 16) {
                        ForEach(storeManager.products.sorted(by: { $0.price < $1.price }), id: \.id) { product in
                            SubscriptionOption(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                onSelect: {
                                    selectedProduct = product
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Purchase Button
                    VStack(spacing: 12) {
                        Button(action: purchaseSelected) {
                            HStack {
                                if storeManager.isPurchasing || isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Subscribe Now")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedProduct != nil ? Color.accentColor : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(selectedProduct == nil || storeManager.isPurchasing || isPurchasing)

                        Button("Restore Purchases") {
                            Task {
                                await storeManager.restorePurchases()
                                if storeManager.isSubscribed {
                                    dismiss()
                                }
                            }
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)

                    // MARK: - Terms
                    TermsSection()
                        .padding(.horizontal)

                    // MARK: - Error Message
                    if let error = storeManager.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Pre-select professional tier by default
            if selectedProduct == nil {
                selectedProduct = storeManager.products.first { $0.id == StoreManager.professionalMonthlyID }
            }
        }
    }

    // MARK: - Purchase

    private func purchaseSelected() {
        guard let product = selectedProduct else { return }

        Task {
            isPurchasing = true
            let success = await storeManager.purchase(product)
            isPurchasing = false

            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Features Section

struct FeaturesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                FeatureRow(
                    icon: "chart.scatter",
                    title: "Advanced Monte Carlo",
                    description: "Up to 100,000 iterations"
                )
                FeatureRow(
                    icon: "sparkles",
                    title: "AI Optimization",
                    description: "Parameter recommendations"
                )
                FeatureRow(
                    icon: "book.pages",
                    title: "Recipe Management",
                    description: "Create and edit custom recipes"
                )
                FeatureRow(
                    icon: "square.and.arrow.up",
                    title: "Export Results",
                    description: "PDF and CSV export"
                )
                FeatureRow(
                    icon: "waveform.badge.plus",
                    title: "Real-time Monitoring",
                    description: "Digital twin visualization"
                )
                FeatureRow(
                    icon: "icloud.and.arrow.up",
                    title: "Cloud Sync",
                    description: "Sync across all devices"
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Subscription Option

struct SubscriptionOption: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscriptionTitle(for: product))
                        .font(.headline)
                    Text(product.displayPrice)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let subtitle = subscriptionSubtitle(for: product) {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isBestValue(product) {
                    Text("BEST VALUE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.secondaryGroupedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func subscriptionTitle(for product: Product) -> String {
        switch product.id {
        case StoreManager.basicMonthlyID:
            return "Basic Plan"
        case StoreManager.professionalMonthlyID:
            return "Professional Plan"
        default:
            return product.displayName
        }
    }

    private func subscriptionSubtitle(for product: Product) -> String? {
        switch product.id {
        case StoreManager.basicMonthlyID:
            return "Essential synthesis tools"
        case StoreManager.professionalMonthlyID:
            return "All features + priority support"
        default:
            return nil
        }
    }

    private func isBestValue(_ product: Product) -> Bool {
        product.id == StoreManager.professionalMonthlyID
    }
}

// MARK: - Terms Section

struct TermsSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Subscriptions will automatically renew unless canceled within 24-hours before the end of the current period. You can cancel anytime in your Account Settings.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
            }
            .font(.caption2)
        }
        .padding(.top, 20)
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager())
}