import SwiftUI

struct ProductCardView: View {
    let product: YieldProduct
    let isWatchlisted: Bool
    let onToggleWatchlist: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Score circle
            ScoreGaugeView(score: product.sentinelScore, size: 44)

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.name)
                        .font(.headline)
                        .lineLimit(1)

                    if product.riskLevel == .critical {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    Label(product.chain, systemImage: "link.circle")
                    Label(product.category.rawValue, systemImage: product.category.systemImage)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            // Right side: APY + TVL
            VStack(alignment: .trailing, spacing: 4) {
                Text(product.formattedAPY)
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)

                Text(product.formattedTVL)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Score change indicator
                if let change = product.previousScore.map({ product.sentinelScore - $0 }), change != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: change > 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(abs(change))")
                    }
                    .font(.caption2)
                    .foregroundStyle(change > 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button {
                onToggleWatchlist()
            } label: {
                Label(
                    isWatchlisted ? "Remove" : "Watch",
                    systemImage: isWatchlisted ? "star.slash" : "star"
                )
            }
            .tint(isWatchlisted ? .red : .yellow)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.name), Sentinel Score \(product.sentinelScore), \(product.riskLevel.rawValue) risk, APY \(product.formattedAPY)")
    }
}
