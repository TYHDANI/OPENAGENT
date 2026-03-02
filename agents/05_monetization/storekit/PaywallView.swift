import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product? = nil
    @State private var showingError: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                featureComparisonSection
                pricingSection
                ctaSection
                footerSection
            }
        }
        .background(backgroundGradient)
        .alert("Something went wrong", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(storeManager.errorMessage ?? "Please try again later.")
        }
        .onChange(of: storeManager.errorMessage) { _, newValue in
            if newValue != nil { showingError = true }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.blue.opacity(0.08),
                Color.purple.opacity(0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .accessibilityHidden(true)

            Text("Unlock Premium")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Get the most out of {{APP_NAME}}")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
        .padding(.bottom, 32)
    }

    // MARK: - Feature Comparison

    private var featureComparisonSection: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack {
                Text("Features")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
                Text("Pro")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                    .frame(width: 50)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // Feature rows
            featureRow("Basic Features", free: true, pro: true)
            featureRow("Unlimited Access", free: false, pro: true)
            featureRow("Cloud Sync", free: false, pro: true)
            featureRow("Priority Support", free: false, pro: true)
            featureRow("No Ads", free: false, pro: true)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func featureRow(_ name: String, free: Bool, pro: Bool) -> some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            featureCheckmark(free)
                .frame(width: 50)

            featureCheckmark(pro)
                .frame(width: 50)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name): \(free ? "included" : "not included") in Free, \(pro ? "included" : "not included") in Pro")
    }

    private func featureCheckmark(_ included: Bool) -> some View {
        Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
            .foregroundStyle(included ? .green : .secondary.opacity(0.4))
            .imageScale(.medium)
            .accessibilityHidden(true)
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: 12) {
            ForEach(storeManager.products, id: \.id) { product in
                PricingCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    isBestValue: product.id == StoreManager.yearlyID
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedProduct = product
                    }
                }
            }
        }
        .padding()
        .onAppear {
            // Default to yearly as pre-selected.
            if selectedProduct == nil {
                selectedProduct = storeManager.products.first {
                    $0.id == StoreManager.yearlyID
                }
            }
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            // Free trial callout
            if let selected = selectedProduct, selected.subscription != nil {
                Text("Start your free trial")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Purchase button
            Button {
                Task { await purchaseSelected() }
            } label: {
                Group {
                    if storeManager.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(purchaseButtonTitle)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .tint(.blue)
            .disabled(selectedProduct == nil || storeManager.isPurchasing)
            .accessibilityLabel(purchaseButtonTitle)

            // Restore purchases
            Button("Restore Purchases") {
                Task { await storeManager.restorePurchases() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Restore previously purchased subscriptions")
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var purchaseButtonTitle: String {
        guard let product = selectedProduct else { return "Select a Plan" }

        if product.id == StoreManager.lifetimeID {
            return "Buy for \(product.displayPrice)"
        }
        return "Try Free & Subscribe — \(product.displayPrice)"
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://{{DOMAIN}}/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://{{DOMAIN}}/privacy")!)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Actions

    private func purchaseSelected() async {
        guard let product = selectedProduct else { return }
        let success = await storeManager.purchase(product)
        if success { dismiss() }
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue, in: Capsule())
                        }
                    }

                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    if let period = product.subscription?.subscriptionPeriod {
                        Text(periodLabel(period))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(product.displayName), \(product.displayPrice)\(isBestValue ? ", best value" : "")")
    }

    private func periodLabel(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:   return "per day"
        case .week:  return "per week"
        case .month: return "per month"
        case .year:  return "per year"
        @unknown default: return ""
        }
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager())
}
