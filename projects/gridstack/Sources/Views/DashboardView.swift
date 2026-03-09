import SwiftUI
import Charts

struct DashboardView: View {
    @Environment(EnergyService.self) private var service
    @State private var selectedPeriod: TimePeriod = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    earningsHeroCard
                    periodPicker
                    usageChart
                    earningsBreakdownCard
                    quickStatsGrid
                    activeDRBanner
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .darkNavigationBar()
        }
    }

    // MARK: - Hero Card

    private var earningsHeroCard: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Total Earnings")
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textSecondary)

            Text(formattedCurrency(service.totalEarnings))
                .font(AppTypography.metric)
                .foregroundStyle(AppColors.accent)

            HStack(spacing: AppSpacing.lg) {
                earningsPill(label: "Today", value: service.todayEarnings)
                earningsPill(label: "This Week", value: service.weekEarnings)
                earningsPill(label: "This Month", value: service.monthEarnings)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .strokeBorder(AppColors.accent.opacity(0.2), lineWidth: 1)
        )
        .appShadow(AppShadow.md)
    }

    private func earningsPill(label: String, value: Double) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(label)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.textTertiary)
            Text(formattedCurrency(value))
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Usage Chart

    private var usageChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Energy Usage", systemImage: "bolt.fill")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            let data = service.dailyUsage(for: chartDays)

            Chart {
                ForEach(data, id: \.date) { entry in
                    BarMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("kWh", entry.kWh)
                    )
                    .foregroundStyle(AppGradient.accent(opacity: 0.8))
                    .cornerRadius(4)
                }
            }
            .chartYAxisLabel("kWh")
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(chartDays / 7, 1))) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(AppColors.divider)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(AppColors.divider)
                    AxisValueLabel()
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .frame(height: 200)

            HStack {
                let totalKWh = data.reduce(0) { $0 + $1.kWh }
                let totalCost = data.reduce(0) { $0 + $1.cost }
                Text("\(String(format: "%.1f", totalKWh)) kWh total")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text(formattedCurrency(totalCost) + " cost")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.error)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    // MARK: - Earnings Breakdown

    private var earningsBreakdownCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Earnings Breakdown", systemImage: "chart.pie.fill")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            let breakdown = service.earningsBySource(for: selectedPeriod)
            let total = breakdown.values.reduce(0, +)

            ForEach(EarningsRecord.EarningsSource.allCases, id: \.self) { source in
                let amount = breakdown[source] ?? 0
                if amount > 0 {
                    HStack {
                        Circle()
                            .fill(colorForSource(source))
                            .frame(width: 10, height: 10)
                        Text(source.rawValue)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Text(formattedCurrency(amount))
                            .font(AppTypography.captionBold)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(total > 0 ? "\(Int((amount / total) * 100))%" : "0%")
                            .font(AppTypography.caption2)
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }

            if total == 0 {
                Text("No earnings in this period")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    // MARK: - Quick Stats

    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
            statCard(
                icon: "arrow.triangle.2.circlepath",
                label: "DR Events",
                value: "\(service.completedDREvents.count)",
                color: AppColors.info
            )
            statCard(
                icon: "cpu",
                label: "Hash Rate",
                value: String(format: "%.1f TH/s", service.totalHashRateTHs),
                color: AppColors.accent
            )
            statCard(
                icon: "flame.fill",
                label: "Heat Reclaimed",
                value: formatBTU(service.totalHeatReclaimedBTU),
                color: AppColors.error
            )
            statCard(
                icon: "leaf.fill",
                label: "Heat Savings",
                value: formattedCurrency(service.totalHeatSavingsUSD),
                color: AppColors.success
            )
        }
    }

    private func statCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(AppTypography.metricSmall)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Active DR Banner

    @ViewBuilder
    private var activeDRBanner: some View {
        if let active = service.activeDREvents.first {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.success)
                    .symbolEffect(.pulse)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("DR Event Active")
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(active.programName) -- earning \(formattedCurrency(active.earningsUSD))")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Text("LIVE")
                    .font(AppTypography.badge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColors.success)
                    .clipShape(Capsule())
            }
            .padding(AppSpacing.md)
            .background(AppColors.success.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(AppColors.success.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private var chartDays: Int {
        switch selectedPeriod {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .year: return 30 // show last 30 for performance
        }
    }

    private func colorForSource(_ source: EarningsRecord.EarningsSource) -> Color {
        switch source {
        case .demandResponse: return AppColors.info
        case .mining: return AppColors.accent
        case .heatReclamation: return AppColors.error
        case .touSavings: return AppColors.success
        case .solarExport: return Color(hex: "8B5CF6")
        }
    }

    private func formattedCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private func formatBTU(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM BTU", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK BTU", value / 1_000)
        }
        return String(format: "%.0f BTU", value)
    }
}

#Preview {
    DashboardView()
        .environment(EnergyService())
        .environment(StoreManager())
        .preferredColorScheme(.dark)
}
