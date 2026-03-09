import SwiftUI
import Charts

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel

    init(product: YieldProduct) {
        _viewModel = State(initialValue: ProductDetailViewModel(product: product))
    }

    var body: some View {
        List {
            // MARK: - Score Header
            Section {
                VStack(spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.product.name)
                                .font(.title2.bold())

                            HStack(spacing: 8) {
                                Label(viewModel.product.chain, systemImage: "link.circle")
                                Label(viewModel.product.category.rawValue, systemImage: viewModel.product.category.systemImage)
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        ScoreGaugeView(score: viewModel.product.sentinelScore, size: 80)
                    }

                    // Risk level badge
                    HStack {
                        RiskBadge(level: viewModel.product.riskLevel)
                        Spacer()
                        Text("Last updated: \(viewModel.product.lastUpdated, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Key Metrics
            Section("Key Metrics") {
                MetricRow(label: "Current APY", value: viewModel.product.formattedAPY, color: .green)
                MetricRow(label: "TVL", value: viewModel.product.formattedTVL)
                MetricRow(
                    label: "TVL 7d",
                    value: String(format: "%+.1f%%", viewModel.product.tvl7dChange),
                    color: viewModel.product.tvl7dChange >= 0 ? .green : .red
                )
                MetricRow(
                    label: "TVL 30d",
                    value: String(format: "%+.1f%%", viewModel.product.tvl30dChange),
                    color: viewModel.product.tvl30dChange >= 0 ? .green : .red
                )

                if let collateral = viewModel.collateralInfo {
                    MetricRow(label: "Collateral Ratio", value: collateral)
                }

                if let insurance = viewModel.insuranceInfo {
                    MetricRow(label: "Insurance Coverage", value: insurance)
                }
            }

            // MARK: - Historical Score Chart
            if !viewModel.product.historicalScores.isEmpty {
                Section("Score History") {
                    Chart(viewModel.product.historicalScores) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Score", dataPoint.score)
                        )
                        .foregroundStyle(colorForScore(dataPoint.score))

                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Score", dataPoint.score)
                        )
                        .foregroundStyle(
                            .linearGradient(
                                colors: [colorForScore(dataPoint.score).opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis {
                        AxisMarks(values: [0, 25, 50, 75, 100])
                    }
                    .frame(height: 200)
                }
            }

            // MARK: - Risk Factors Summary
            Section {
                NavigationLink {
                    RiskFactorsView(
                        productName: viewModel.product.name,
                        factors: viewModel.riskFactors
                    )
                } label: {
                    HStack {
                        Image(systemName: "shield.checkered")
                        Text("Risk Factor Breakdown")
                        Spacer()
                        Text("\(viewModel.riskFactors.count) factors")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Analysis")
            }

            // Top Risks
            if !viewModel.topRisks.isEmpty {
                Section("Top Risks") {
                    ForEach(viewModel.topRisks.prefix(3)) { factor in
                        RiskFactorRow(factor: factor)
                    }
                }
            }

            // Strengths
            if !viewModel.strengths.isEmpty {
                Section("Strengths") {
                    ForEach(viewModel.strengths.prefix(3)) { factor in
                        RiskFactorRow(factor: factor)
                    }
                }
            }

            // MARK: - Protocol Details
            Section("Protocol Details") {
                LabeledContent("Audit Status", value: viewModel.product.auditStatus.rawValue)
                LabeledContent("Team", value: viewModel.product.teamTransparency.rawValue)
                LabeledContent("Regulatory", value: viewModel.product.regulatoryStatus.rawValue)
                LabeledContent("Withdrawal", value: viewModel.product.withdrawalTime.rawValue)
                LabeledContent("Bridge Risk", value: viewModel.product.bridgeDependency.rawValue)
                LabeledContent("Liquidity", value: viewModel.product.liquidityDepth.rawValue)
                LabeledContent("Whale Conc.", value: String(format: "%.0f%%", viewModel.product.whaleConcentration * 100))
                LabeledContent("Contract Age", value: "\(viewModel.product.contractAge) days")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refresh()
        }
    }
}

// MARK: - Supporting Views

private struct MetricRow: View {
    let label: String
    let value: String
    var color: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(color)
        }
    }
}

struct RiskBadge: View {
    let level: RiskLevel

    var body: some View {
        Text(level.rawValue.uppercased())
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(colorForRiskLevel(level).opacity(0.15))
            .foregroundStyle(colorForRiskLevel(level))
            .clipShape(Capsule())
    }
}
