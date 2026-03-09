import SwiftUI

struct ProductCard: View {
    let product: YieldProduct

    var body: some View {
        HStack(spacing: 12) {
            // Score badge
            ZStack {
                Circle()
                    .fill(product.riskLevel.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Text("\(product.sentinelScore)")
                    .font(.headline.bold())
                    .foregroundStyle(product.riskLevel.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.name).font(.headline)
                    Spacer()
                    Text(product.category.rawValue)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppColors.accent.opacity(0.15))
                        .foregroundStyle(AppColors.accent)
                        .clipShape(Capsule())
                }

                HStack {
                    Text(product.chain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("\(product.apy, specifier: "%.1f")%", systemImage: "percent")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.accent)
                }

                HStack {
                    Text("TVL: \(formatTVL(product.tvl))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 2) {
                        Image(systemName: product.tvlChange30d >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(abs(product.tvlChange30d), specifier: "%.1f")%")
                    }
                    .font(.caption)
                    .foregroundStyle(product.tvlChange30d >= 0 ? AppColors.success : AppColors.danger)
                }
            }
        }
        .padding()
        .glassCard()
    }

    private func formatTVL(_ tvl: Double) -> String {
        if tvl >= 1_000_000_000 { return String(format: "$%.1fB", tvl / 1_000_000_000) }
        if tvl >= 1_000_000 { return String(format: "$%.0fM", tvl / 1_000_000) }
        return String(format: "$%.0fK", tvl / 1_000)
    }
}
