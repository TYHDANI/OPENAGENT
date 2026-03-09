import SwiftUI

struct RiskFactorsView: View {
    let productName: String
    let factors: [RiskFactor]

    var body: some View {
        List {
            // Summary header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("15 Weighted Risk Signals")
                        .font(.headline)
                    Text("Each factor is weighted by its importance to overall protocol health. Combined weights produce the Sentinel Score.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Factor breakdown grouped by status
            Section("Danger / Warning") {
                let riskFactors = factors.filter { $0.status == .danger || $0.status == .warning }
                if riskFactors.isEmpty {
                    Text("No risk factors flagged")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(riskFactors) { factor in
                        RiskFactorDetailRow(factor: factor)
                    }
                }
            }

            Section("Fair") {
                let fairFactors = factors.filter { $0.status == .fair }
                ForEach(fairFactors) { factor in
                    RiskFactorDetailRow(factor: factor)
                }
            }

            Section("Good") {
                let goodFactors = factors.filter { $0.status == .good }
                ForEach(goodFactors) { factor in
                    RiskFactorDetailRow(factor: factor)
                }
            }

            // Weight distribution
            Section("Weight Distribution") {
                ForEach(factors.sorted { $0.weight > $1.weight }) { factor in
                    HStack {
                        Text(factor.name)
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.0f%%", factor.weight * 100))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        GeometryReader { geo in
                            Rectangle()
                                .fill(factorStatusColor(factor.status))
                                .frame(width: geo.size.width * factor.weight / 0.12, height: 8)
                                .clipShape(Capsule())
                        }
                        .frame(width: 60, height: 8)
                    }
                }
            }
        }
        .navigationTitle("Risk Factors")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Factor Detail Row

private struct RiskFactorDetailRow: View {
    let factor: RiskFactor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: factor.type.systemImage)
                    .foregroundStyle(factorStatusColor(factor.status))
                    .frame(width: 24)

                Text(factor.name)
                    .font(.subheadline.bold())

                Spacer()

                // Score badge
                Text("\(Int(factor.rawValue))/100")
                    .font(.caption.bold().monospaced())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(factorStatusColor(factor.status).opacity(0.15))
                    .foregroundStyle(factorStatusColor(factor.status))
                    .clipShape(Capsule())
            }

            Text(factor.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text("Weight: \(String(format: "%.0f%%", factor.weight * 100))")
                Spacer()
                Text("Weighted: \(String(format: "%.1f", factor.weightedScore))")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(factor.name), score \(Int(factor.rawValue)) out of 100, \(factor.status.rawValue)")
    }
}

// MARK: - Compact Row (for other views)

struct RiskFactorRow: View {
    let factor: RiskFactor

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: factor.type.systemImage)
                .foregroundStyle(factorStatusColor(factor.status))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(factor.name)
                    .font(.subheadline)
                Text(factor.status.rawValue)
                    .font(.caption)
                    .foregroundStyle(factorStatusColor(factor.status))
            }

            Spacer()

            Text("\(Int(factor.rawValue))")
                .font(.subheadline.bold().monospaced())
                .foregroundStyle(factorStatusColor(factor.status))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(factor.name), \(factor.status.rawValue), score \(Int(factor.rawValue))")
    }
}

// MARK: - Helpers

func factorStatusColor(_ status: FactorStatus) -> Color {
    switch status {
    case .good: return .green
    case .fair: return .yellow
    case .warning: return .orange
    case .danger: return .red
    }
}
