import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTier: SubscriptionTier = .guardian
    @State private var billingCycle: BillingCycle = .yearly

    enum BillingCycle: String, CaseIterable {
        case monthly
        case yearly

        var label: String {
            switch self {
            case .monthly: return "Monthly"
            case .yearly: return "Yearly (Save 17%)"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                billingToggle
                tierCards
                featureComparison
                purchaseButton
                restoreButton
                legalFooter
            }
            .padding()
        }
        .navigationTitle("Choose Your Plan")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .init(
            get: { storeManager.errorMessage != nil },
            set: { if !$0 { storeManager.errorMessage = nil } }
        )) {
            Button("OK") { storeManager.errorMessage = nil }
        } message: {
            Text(storeManager.errorMessage ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Protect Your Legacy")
                .font(.title2.bold())

            Text("Upgrade to unlock advanced monitoring, more accounts, and automated succession planning.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Billing Toggle

    private var billingToggle: some View {
        Picker("Billing", selection: $billingCycle) {
            ForEach(BillingCycle.allCases, id: \.self) { cycle in
                Text(cycle.label).tag(cycle)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Billing cycle")
    }

    // MARK: - Tier Cards

    private var tierCards: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionTier.allCases.filter { $0 != .free }) { tier in
                tierCard(tier)
            }
        }
    }

    private func tierCard(_ tier: SubscriptionTier) -> some View {
        let isSelected = selectedTier == tier

        return Button {
            selectedTier = tier
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: tier.iconSystemName)
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .blue)

                    Text(tier.displayName)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)

                    Spacer()

                    Text(billingCycle == .monthly ? tier.monthlyPrice : tier.yearlyPrice)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : .primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(tier.features, id: \.self) { feature in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(isSelected ? .white.opacity(0.9) : .green)
                            Text(feature)
                                .font(.caption)
                                .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.separator), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tier.displayName) plan, \(billingCycle == .monthly ? tier.monthlyPrice : tier.yearlyPrice)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Feature Comparison

    private var featureComparison: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's included in \(selectedTier.displayName)")
                .font(.subheadline.weight(.semibold))

            ForEach(selectedTier.features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(feature)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                guard let product = matchingProduct else { return }
                let success = await storeManager.purchase(product)
                if success { dismiss() }
            }
        } label: {
            Group {
                if storeManager.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start 7-Day Free Trial")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
        }
        .disabled(storeManager.isPurchasing || matchingProduct == nil)
        .accessibilityLabel("Start free trial for \(selectedTier.displayName)")
    }

    private var matchingProduct: Product? {
        let targetID: String
        switch (selectedTier, billingCycle) {
        case (.guardian, .monthly): targetID = StoreManager.guardianMonthlyID
        case (.guardian, .yearly): targetID = StoreManager.guardianYearlyID
        case (.estate, .monthly): targetID = StoreManager.estateMonthlyID
        case (.estate, .yearly): targetID = StoreManager.estateYearlyID
        case (.familyOffice, .monthly): targetID = StoreManager.familyOfficeMonthlyID
        case (.familyOffice, .yearly): targetID = StoreManager.familyOfficeYearlyID
        default: return nil
        }
        return storeManager.products.first { $0.id == targetID }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await storeManager.restorePurchases() }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    // MARK: - Legal

    private var legalFooter: some View {
        VStack(spacing: 4) {
            Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Text("Payment will be charged to your Apple ID account. This app does not constitute legal or tax advice.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
}
