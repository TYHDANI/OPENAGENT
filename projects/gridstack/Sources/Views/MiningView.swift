import SwiftUI
import Charts

struct MiningView: View {
    @Environment(EnergyService.self) private var service
    @State private var showingSessionDetail: MiningSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    miningOverviewCard
                    heatReclamationCard
                    profitabilityChart
                    sessionsSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Mining")
            .darkNavigationBar()
            .sheet(item: $showingSessionDetail) { session in
                sessionDetailSheet(session)
            }
        }
    }

    // MARK: - Mining Overview

    private var miningOverviewCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Mining Operations")
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(service.activeMiningSessions.count) active session\(service.activeMiningSessions.count == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundStyle(service.activeMiningSessions.isEmpty ? AppColors.textTertiary : AppColors.success)
                }
                Spacer()
                Image(systemName: "cpu")
                    .font(.largeTitle)
                    .foregroundStyle(AppColors.accent)
            }

            Divider().overlay(AppColors.divider)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                miningMetric(
                    icon: "speedometer",
                    label: "Hash Rate",
                    value: String(format: "%.1f TH/s", service.totalHashRateTHs),
                    color: AppColors.accent
                )
                miningMetric(
                    icon: "dollarsign.circle",
                    label: "Revenue",
                    value: formattedCurrency(service.totalMiningRevenueUSD),
                    color: AppColors.success
                )
                miningMetric(
                    icon: "bolt.fill",
                    label: "Power Cost",
                    value: formattedCurrency(service.totalMiningCostUSD),
                    color: AppColors.error
                )
                miningMetric(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Net Profit",
                    value: formattedCurrency(service.miningNetProfitUSD),
                    color: service.miningNetProfitUSD >= 0 ? AppColors.success : AppColors.error
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .strokeBorder(AppColors.accent.opacity(0.2), lineWidth: 1)
        )
    }

    private func miningMetric(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(AppTypography.captionBold)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Heat Reclamation

    private var heatReclamationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Label("Heat Reclamation", systemImage: "flame.fill")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("ROI Tracker")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.accent)
            }

            let reclaimedSessions = service.miningSessions.filter { $0.heatReclaimed }
            let totalReclaimed = reclaimedSessions.count
            let totalSessions = service.miningSessions.count
            let reclaimRate = totalSessions > 0 ? Double(totalReclaimed) / Double(totalSessions) : 0

            HStack(spacing: AppSpacing.lg) {
                VStack(spacing: AppSpacing.xxs) {
                    Text(formatBTU(service.totalHeatReclaimedBTU))
                        .font(AppTypography.metricSmall)
                        .foregroundStyle(Color(hex: "EF4444"))
                    Text("Heat Reclaimed")
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: AppSpacing.xxs) {
                    Text(formattedCurrency(service.totalHeatSavingsUSD))
                        .font(AppTypography.metricSmall)
                        .foregroundStyle(AppColors.success)
                    Text("Heating Saved")
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }

            // Reclamation rate bar
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack {
                    Text("Reclamation Rate")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text("\(Int(reclaimRate * 100))%")
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.accent)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(AppColors.tertiaryBackground)
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(AppGradient.accent())
                            .frame(width: geo.size.width * reclaimRate)
                    }
                }
                .frame(height: 8)
            }

            Text("Mining waste heat offsets \(formattedCurrency(service.totalHeatSavingsUSD)) in heating costs at $1.20/therm")
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    // MARK: - Profitability Chart

    private var profitabilityChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Session Profitability", systemImage: "chart.bar.fill")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            let sessions = service.miningSessions
                .filter { $0.endTime != nil }
                .sorted { $0.startTime < $1.startTime }
                .suffix(10)

            if sessions.isEmpty {
                Text("No completed sessions yet")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                Chart {
                    ForEach(Array(sessions)) { session in
                        BarMark(
                            x: .value("Session", session.startTime, unit: .day),
                            y: .value("Profit", session.netProfitUSD)
                        )
                        .foregroundStyle(session.netProfitUSD >= 0 ? AppColors.success : AppColors.error)
                        .cornerRadius(4)
                    }

                    RuleMark(y: .value("Break Even", 0))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .chartYAxisLabel("USD")
                .chartXAxis {
                    AxisMarks { _ in
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
                .frame(height: 180)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    // MARK: - Sessions List

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Recent Sessions")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            ForEach(service.miningSessions.sorted(by: { $0.startTime > $1.startTime }).prefix(8)) { session in
                sessionRow(session)
                    .onTapGesture {
                        showingSessionDetail = session
                        AppHaptics.selection()
                    }
            }
        }
    }

    private func sessionRow(_ session: MiningSession) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(session.isActive ? AppColors.success : AppColors.textTertiary)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack {
                    Text(session.algorithm.rawValue)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    if session.isActive {
                        Text("LIVE")
                            .font(AppTypography.badge)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.success)
                            .clipShape(Capsule())
                    }
                }
                Text("\(String(format: "%.1f", session.hashRateTHs)) TH/s -- \(String(format: "%.0f", session.powerConsumptionW))W -- \(String(format: "%.1f", session.durationHours))h")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text(formattedCurrency(session.netProfitUSD))
                    .font(AppTypography.captionBold)
                    .foregroundStyle(session.netProfitUSD >= 0 ? AppColors.success : AppColors.error)
                if session.heatReclaimed {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "EF4444"))
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Session Detail Sheet

    private func sessionDetailSheet(_ session: MiningSession) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Status
                    HStack {
                        Text(session.isActive ? "Active Session" : "Completed Session")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        if session.isActive {
                            Text("LIVE")
                                .font(AppTypography.badge)
                                .foregroundStyle(.white)
                                .padding(.horizontal, AppSpacing.xs)
                                .padding(.vertical, AppSpacing.xxs)
                                .background(AppColors.success)
                                .clipShape(Capsule())
                        }
                    }

                    // Details grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                        detailItem("Algorithm", session.algorithm.rawValue)
                        detailItem("Hash Rate", String(format: "%.1f TH/s", session.hashRateTHs))
                        detailItem("Power", String(format: "%.0fW", session.powerConsumptionW))
                        detailItem("Duration", String(format: "%.1f hours", session.durationHours))
                        detailItem("BTC Earned", String(format: "%.8f", session.btcEarned))
                        detailItem("Revenue", formattedCurrency(session.btcEarned * 60_000))
                        detailItem("Electricity Cost", formattedCurrency(session.electricityCostUSD))
                        detailItem("Cost/kWh", formattedCurrency(session.electricityCostPerKWh))
                    }

                    Divider().overlay(AppColors.divider)

                    // Heat reclamation
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Label("Heat Reclamation", systemImage: "flame.fill")
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppColors.textPrimary)

                        HStack {
                            Text("Status")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            Text(session.heatReclaimed ? "Active" : "Not Reclaiming")
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(session.heatReclaimed ? AppColors.success : AppColors.textTertiary)
                        }
                        HStack {
                            Text("Heat Output")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            Text(formatBTU(session.heatOutputBTU))
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        HStack {
                            Text("Heating Cost Offset")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            Text(formattedCurrency(session.heatReclaimSavingsUSD))
                                .font(AppTypography.bodyBold)
                                .foregroundStyle(AppColors.success)
                        }
                    }

                    Divider().overlay(AppColors.divider)

                    // Net profit
                    HStack {
                        Text("Net Profit")
                            .font(AppTypography.sectionTitle)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Text(formattedCurrency(session.netProfitUSD))
                            .font(AppTypography.metricSmall)
                            .foregroundStyle(session.netProfitUSD >= 0 ? AppColors.success : AppColors.error)
                    }

                    HStack {
                        Text("ROI")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text(String(format: "%.1f%%", session.roiPercent))
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(session.roiPercent >= 0 ? AppColors.success : AppColors.error)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Session Details")
            .inlineTitleDisplayMode()
            .darkNavigationBar()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingSessionDetail = nil
                    }
                    .foregroundStyle(AppColors.accent)
                }
            }
        }
        .sheetDetents()
    }

    private func detailItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(label)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.textTertiary)
            Text(value)
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

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
    MiningView()
        .environment(EnergyService())
        .environment(StoreManager())
        .preferredColorScheme(.dark)
}
