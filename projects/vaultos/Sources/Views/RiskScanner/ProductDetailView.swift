import SwiftUI

struct ProductDetailView: View {
    let product: YieldProduct

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Score hero
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(product.riskLevel.color, lineWidth: 4)
                            .frame(width: 100, height: 100)
                        VStack {
                            Text("\(product.sentinelScore)")
                                .font(.system(size: 36, weight: .bold))
                            Text("Sentinel")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(product.riskLevel.label)
                        .font(.headline)
                        .foregroundStyle(product.riskLevel.color)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .glassCard()

                // Key metrics
                VStack(spacing: 12) {
                    MetricRow(label: "APY", value: String(format: "%.2f%%", product.apy))
                    MetricRow(label: "TVL", value: formatTVL(product.tvl))
                    MetricRow(label: "7d Change", value: String(format: "%+.1f%%", product.tvlChange7d),
                              color: product.tvlChange7d >= 0 ? AppColors.success : AppColors.danger)
                    MetricRow(label: "30d Change", value: String(format: "%+.1f%%", product.tvlChange30d),
                              color: product.tvlChange30d >= 0 ? AppColors.success : AppColors.danger)
                    MetricRow(label: "Collateral", value: String(format: "%.0f%%", product.collateralRatio * 100))
                    MetricRow(label: "Chain", value: product.chain)
                    MetricRow(label: "Category", value: product.category.rawValue)
                }
                .padding()
                .glassCard()

                // Risk factors
                if !product.riskFactors.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Risk Factors").font(.headline)
                        ForEach(product.riskFactors) { factor in
                            RiskFactorRow(factor: factor)
                        }
                    }
                    .padding()
                    .glassCard()
                }
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle(product.name)
    }

    private func formatTVL(_ tvl: Double) -> String {
        if tvl >= 1_000_000_000 { return String(format: "$%.1fB", tvl / 1_000_000_000) }
        if tvl >= 1_000_000 { return String(format: "$%.0fM", tvl / 1_000_000) }
        return String(format: "$%.0fK", tvl / 1_000)
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).bold().foregroundStyle(color)
        }
    }
}

struct RiskFactorRow: View {
    let factor: RiskFactor

    var body: some View {
        HStack {
            Text(factor.type.label)
                .font(.subheadline)
            Spacer()
            ProgressView(value: Double(factor.score), total: 100)
                .tint(scoreColor)
                .frame(width: 80)
            Text("\(factor.score)")
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(scoreColor)
                .frame(width: 30)
        }
    }

    private var scoreColor: Color {
        if factor.score >= 75 { return AppColors.success }
        if factor.score >= 50 { return .yellow }
        if factor.score >= 25 { return .orange }
        return AppColors.danger
    }
}
