import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text("TreasuryPilot Pro")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Multi-entity crypto tax management")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // Tier Comparison
                VStack(spacing: 12) {
                    TierCard(
                        name: "Free",
                        price: "$0",
                        features: ["1 entity", "2 accounts", "Basic tracking"],
                        isActive: storeManager.currentTier == .free,
                        action: nil
                    )

                    ForEach(storeManager.products, id: \.id) { product in
                        let tier = tierName(for: product)
                        let features = tierFeatures(for: product)
                        TierCard(
                            name: tier,
                            price: product.displayPrice + "/mo",
                            features: features,
                            isActive: storeManager.activeSubscription?.id == product.id,
                            action: {
                                Task { await storeManager.purchase(product) }
                            }
                        )
                    }
                }
                .padding(.horizontal)

                // Restore
                Button {
                    Task { await storeManager.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let error = storeManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple ID account.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Upgrade")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tierName(for product: Product) -> String {
        switch product.id {
        case StoreManager.professionalMonthlyID: return "Professional"
        case StoreManager.familyOfficeMonthlyID: return "Family Office"
        case StoreManager.enterpriseMonthlyID: return "Enterprise"
        default: return product.displayName
        }
    }

    private func tierFeatures(for product: Product) -> [String] {
        switch product.id {
        case StoreManager.professionalMonthlyID:
            return ["3 entities", "10 accounts", "Quarterly estimates", "PDF reports"]
        case StoreManager.familyOfficeMonthlyID:
            return ["10 entities", "Unlimited accounts", "Wash sale detection", "Form 8949 export", "5 user seats"]
        case StoreManager.enterpriseMonthlyID:
            return ["Unlimited entities", "Unlimited accounts", "All reports", "API access", "Priority support"]
        default:
            return []
        }
    }
}

struct TierCard: View {
    let name: String
    let price: String
    let features: [String]
    let isActive: Bool
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.headline)
                Spacer()
                Text(price)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            ForEach(features, id: \.self) { feature in
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(feature)
                        .font(.subheadline)
                }
            }

            if isActive {
                Text("Current Plan")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let action {
                Button(action: action) {
                    Text("Subscribe")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}
