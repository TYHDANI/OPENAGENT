import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedProduct: Product?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Upgrade to Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Unlock powerful features to enhance your habit journey")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    ProFeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Advanced Analytics",
                        description: "Detailed insights, trends, and patterns"
                    )

                    ProFeatureRow(
                        icon: "paintbrush.fill",
                        title: "Custom Themes",
                        description: "Personalize with beautiful themes"
                    )

                    ProFeatureRow(
                        icon: "square.and.arrow.up",
                        title: "Export Data",
                        description: "Download your progress as CSV"
                    )

                    ProFeatureRow(
                        icon: "clock.arrow.2.circlepath",
                        title: "Habit History",
                        description: "Complete activity timeline"
                    )

                    ProFeatureRow(
                        icon: "sparkles",
                        title: "All Future Features",
                        description: "Get new Pro features as we add them"
                    )
                }
                .padding(.horizontal)

                // Products
                if storeManager.products.isEmpty {
                    ProgressView()
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(storeManager.products.sorted(by: { $0.price < $1.price })) { product in
                            ProductCard(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                onTap: {
                                    selectedProduct = product
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // Purchase Button
                Button {
                    if let product = selectedProduct {
                        Task {
                            let success = await storeManager.purchase(product)
                            if success {
                                dismiss()
                            }
                        }
                    }
                } label: {
                    HStack {
                        if storeManager.isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedProduct != nil ? Color.accentColor : Color.gray)
                    )
                    .foregroundStyle(.white)
                }
                .disabled(selectedProduct == nil || storeManager.isPurchasing)
                .padding(.horizontal)

                // Restore & Terms
                VStack(spacing: 12) {
                    Button("Restore Purchases") {
                        Task {
                            await storeManager.restorePurchases()
                            if storeManager.isSubscribed {
                                dismiss()
                            }
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.accent)

                    HStack(spacing: 16) {
                        Link("Privacy Policy", destination: URL(string: "https://streamflow.app/privacy")!)
                        Link("Terms of Service", destination: URL(string: "https://streamflow.app/terms")!)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("StreamFlow Pro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .task {
            if storeManager.products.isEmpty {
                await storeManager.loadProducts()
            }
            // Auto-select best value (yearly)
            if let yearlyProduct = storeManager.products.first(where: { $0.id.contains("yearly") }) {
                selectedProduct = yearlyProduct
            } else {
                selectedProduct = storeManager.products.first
            }
        }
        .alert("Purchase Failed", isPresented: Binding(
            get: { storeManager.errorMessage != nil },
            set: { if !$0 { storeManager.errorMessage = nil } }
        )) {
            Button("OK") {
                storeManager.errorMessage = nil
            }
        } message: {
            if let error = storeManager.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Pro Feature Row

struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void

    private var savings: String? {
        if product.id.contains("yearly") {
            // Calculate savings vs monthly
            let monthlyPrice = 2.99
            let yearlyTotal = monthlyPrice * 12
            let actualPrice = NSDecimalNumber(decimal: product.price).doubleValue
            let savedAmount = yearlyTotal - actualPrice
            let savedPercentage = Int((savedAmount / yearlyTotal) * 100)
            return "Save \(savedPercentage)%"
        }
        return nil
    }

    private var trialText: String? {
        if product.id.contains("yearly"), let period = product.subscription?.introductoryOffer?.period {
            switch period.unit {
            case .day:
                return "\(period.value) day free trial"
            case .week:
                return "\(period.value) week free trial"
            default:
                return nil
            }
        }
        return nil
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.displayName)
                            .font(.headline)

                        Text(product.displayPrice)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let savings = savings {
                        Text(savings)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? .accent : .secondary)
                }

                if let trialText = trialText {
                    Text(trialText)
                        .font(.caption)
                        .foregroundStyle(.accent)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        PaywallView()
            .environment(StoreManager())
    }
}