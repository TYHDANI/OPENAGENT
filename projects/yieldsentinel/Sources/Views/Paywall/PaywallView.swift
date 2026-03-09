import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: SubscriptionTier = .analyst

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    Text("Upgrade YieldSentinel")
                        .font(.title2.bold())

                    Text("Get real-time risk intelligence for every yield product")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Tier selection
                VStack(spacing: 12) {
                    TierCard(tier: .analyst, isSelected: selectedTier == .analyst) {
                        selectedTier = .analyst
                    }

                    TierCard(tier: .professional, isSelected: selectedTier == .professional) {
                        selectedTier = .professional
                    }
                }
                .padding(.horizontal)

                // Feature comparison
                VStack(alignment: .leading, spacing: 12) {
                    Text("What's included")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(selectedTier.features, id: \.self) { feature in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(feature)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                    }
                }

                // Subscribe button
                VStack(spacing: 12) {
                    let matchingProduct = storeManager.products.first { product in
                        switch selectedTier {
                        case .analyst:
                            return product.id == StoreManager.analystMonthlyID
                        case .professional:
                            return product.id == StoreManager.professionalMonthlyID
                        default:
                            return false
                        }
                    }

                    Button {
                        Task {
                            if let product = matchingProduct {
                                await storeManager.purchase(product)
                            }
                        }
                    } label: {
                        Group {
                            if storeManager.isPurchasing {
                                ProgressView()
                            } else {
                                Text("Subscribe for \(selectedTier.displayPrice)")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(storeManager.isPurchasing)
                    .padding(.horizontal)

                    // Restore purchases
                    Button("Restore Purchases") {
                        Task { await storeManager.restorePurchases() }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let error = storeManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                // Legal
                VStack(spacing: 4) {
                    Text("Subscriptions auto-renew. Cancel anytime in Settings.")
                    Text("This is an analysis tool, not investment advice.")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Upgrade")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Tier Card

private struct TierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tier.rawValue)
                            .font(.headline)

                        if tier == .analyst {
                            Text("Popular")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }

                    Text(tier.displayPrice)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
