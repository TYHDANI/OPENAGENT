import SwiftUI

struct DashboardView: View {
    @Environment(WearableAggregatorService.self) private var service
    @State private var showingSyncAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VDSpacing.xl) {
                    // MARK: - Health Score Ring
                    healthScoreSection

                    // MARK: - Key Metrics Grid
                    keyMetricsSection

                    // MARK: - Quick Stats Bar
                    quickStatsBar

                    // MARK: - Recent Insights Preview
                    if !service.insights.isEmpty {
                        recentInsightsSection
                    }

                    // MARK: - Active Studies Preview
                    if !service.studyMatches.isEmpty {
                        topStudySection
                    }
                }
                .padding(.horizontal, VDSpacing.lg)
                .padding(.bottom, VDSpacing.xxxl)
            }
            .background(VDColors.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await service.syncAll() }
                    } label: {
                        Group {
                            if service.isLoading {
                                ProgressView()
                                    .tint(VDColors.accentTeal)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                        }
                        .foregroundStyle(VDColors.accentTeal)
                    }
                }
            }
        }
    }

    // MARK: - Health Score Section

    @ViewBuilder
    private var healthScoreSection: some View {
        VStack(spacing: VDSpacing.md) {
            ZStack {
                VDRingProgressView(
                    progress: overallScore / 100.0,
                    lineWidth: 14,
                    gradient: scoreGradient
                )
                .frame(width: 140, height: 140)

                VStack(spacing: VDSpacing.xxs) {
                    Text("\(Int(overallScore))")
                        .font(VDTypography.metricLarge)
                        .foregroundStyle(VDColors.textPrimary)
                        .contentTransition(.numericText())

                    Text("Health Score")
                        .font(VDTypography.captionSmall)
                        .foregroundStyle(VDColors.textSecondary)
                }
            }
            .vdGlow(scoreColor, radius: 16)

            if let lastSync = service.lastSync {
                Text("Last sync \(lastSync, format: .relative(presentation: .named))")
                    .font(VDTypography.captionSmall)
                    .foregroundStyle(VDColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, VDSpacing.lg)
    }

    // MARK: - Key Metrics Section

    @ViewBuilder
    private var keyMetricsSection: some View {
        VStack(spacing: VDSpacing.md) {
            VDSectionHeader(title: "Key Metrics", icon: "chart.bar.fill")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: VDSpacing.md) {
                VDMetricBadge(
                    icon: MetricType.heartRate.icon,
                    label: "Resting HR",
                    value: formattedValue(for: .heartRate, suffix: ""),
                    color: MetricType.heartRate.color,
                    trend: service.trend(for: .heartRate)
                )

                VDMetricBadge(
                    icon: MetricType.hrv.icon,
                    label: "HRV",
                    value: formattedValue(for: .hrv, suffix: "ms"),
                    color: MetricType.hrv.color,
                    trend: service.trend(for: .hrv)
                )

                VDMetricBadge(
                    icon: MetricType.steps.icon,
                    label: "Steps",
                    value: formattedSteps,
                    color: MetricType.steps.color,
                    trend: service.trend(for: .steps)
                )
            }
            .vdCard()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: VDSpacing.md) {
                VDMetricBadge(
                    icon: MetricType.sleepDuration.icon,
                    label: "Sleep",
                    value: formattedValue(for: .sleepDuration, suffix: "h"),
                    color: MetricType.sleepDuration.color,
                    trend: service.trend(for: .sleepDuration)
                )

                VDMetricBadge(
                    icon: MetricType.spo2.icon,
                    label: "SpO2",
                    value: formattedValue(for: .spo2, suffix: "%"),
                    color: MetricType.spo2.color,
                    trend: service.trend(for: .spo2)
                )

                VDMetricBadge(
                    icon: MetricType.activeCalories.icon,
                    label: "Calories",
                    value: formattedValue(for: .activeCalories, suffix: ""),
                    color: .orange,
                    trend: service.trend(for: .activeCalories)
                )
            }
            .vdCard()
        }
    }

    // MARK: - Quick Stats Bar

    @ViewBuilder
    private var quickStatsBar: some View {
        HStack(spacing: VDSpacing.lg) {
            quickStat(
                icon: "antenna.radiowaves.left.and.right",
                label: "Devices",
                value: "\(service.connectedProviderCount)",
                color: VDColors.accentTeal
            )

            Divider()
                .frame(height: 32)
                .overlay(VDColors.divider)

            quickStat(
                icon: "chart.dots.scatter",
                label: "Data Points",
                value: abbreviatedCount(service.totalDataPoints),
                color: VDColors.accentPurple
            )

            Divider()
                .frame(height: 32)
                .overlay(VDColors.divider)

            quickStat(
                icon: "lightbulb.fill",
                label: "Insights",
                value: "\(service.unreadInsights)",
                color: VDColors.warningAmber
            )
        }
        .vdCard()
    }

    @ViewBuilder
    private func quickStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: VDSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)

            Text(value)
                .font(VDTypography.metricSmall)
                .foregroundStyle(VDColors.textPrimary)

            Text(label)
                .font(VDTypography.captionSmall)
                .foregroundStyle(VDColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recent Insights Section

    @ViewBuilder
    private var recentInsightsSection: some View {
        VStack(spacing: VDSpacing.md) {
            VDSectionHeader(title: "Recent Insights", icon: "lightbulb.fill", trailing: "See All")

            ForEach(service.insights.prefix(2)) { insight in
                InsightCardCompact(insight: insight)
            }
        }
    }

    // MARK: - Top Study Section

    @ViewBuilder
    private var topStudySection: some View {
        if let topStudy = service.studyMatches.sorted(by: { $0.matchScore > $1.matchScore }).first {
            VStack(spacing: VDSpacing.md) {
                VDSectionHeader(title: "Top Study Match", icon: "flask.fill")

                StudyCardCompact(study: topStudy)
            }
        }
    }

    // MARK: - Computed Properties

    private var overallScore: Double {
        var score: Double = 50
        if let hrv = service.latestValue(for: .hrv) {
            score += min(hrv / 100.0 * 20, 20)
        }
        if let sleep = service.latestValue(for: .sleepDuration) {
            score += min(sleep / 8.0 * 15, 15)
        }
        if let steps = service.latestValue(for: .steps) {
            score += min(steps / 10000.0 * 15, 15)
        }
        return min(score, 100)
    }

    private var scoreColor: Color {
        switch overallScore {
        case 80...100: VDColors.successGreen
        case 60..<80: VDColors.accentTeal
        case 40..<60: VDColors.warningAmber
        default: VDColors.heartRed
        }
    }

    private var scoreGradient: LinearGradient {
        switch overallScore {
        case 80...100: VDColors.gradientScore
        case 60..<80: VDColors.gradientTeal
        case 40..<60:
            LinearGradient(colors: [VDColors.warningAmber, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: VDColors.gradientHeart
        }
    }

    private func formattedValue(for metric: MetricType, suffix: String) -> String {
        guard let value = service.latestValue(for: metric) else { return "--" }
        return "\(Int(value))\(suffix)"
    }

    private var formattedSteps: String {
        guard let steps = service.latestValue(for: .steps) else { return "--" }
        if steps >= 1000 {
            return String(format: "%.1fK", steps / 1000.0)
        }
        return "\(Int(steps))"
    }

    private func abbreviatedCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}

// MARK: - Compact Insight Card (for Dashboard)

struct InsightCardCompact: View {
    let insight: HealthInsight

    var body: some View {
        HStack(spacing: VDSpacing.md) {
            Circle()
                .fill(insight.severity.color.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(insight.severity.color)
                )

            VStack(alignment: .leading, spacing: VDSpacing.xxs) {
                Text(insight.title)
                    .font(VDTypography.bodyBold)
                    .foregroundStyle(VDColors.textPrimary)
                    .lineLimit(1)

                Text(insight.description)
                    .font(VDTypography.captionSmall)
                    .foregroundStyle(VDColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            if !insight.isRead {
                Circle()
                    .fill(insight.severity.color)
                    .frame(width: 8, height: 8)
            }
        }
        .vdCard(padding: VDSpacing.md)
    }

    private var categoryIcon: String {
        switch insight.category {
        case .anomaly: "exclamationmark.triangle.fill"
        case .trend: "chart.line.uptrend.xyaxis"
        case .correlation: "point.3.connected.trianglepath.dotted"
        case .recommendation: "hand.thumbsup.fill"
        case .achievement: "star.fill"
        }
    }
}

// MARK: - Compact Study Card (for Dashboard)

struct StudyCardCompact: View {
    let study: StudyMatch

    var body: some View {
        HStack(spacing: VDSpacing.md) {
            ZStack {
                VDRingProgressView(
                    progress: study.matchScore,
                    lineWidth: 4,
                    gradient: VDColors.gradientScore
                )
                .frame(width: 44, height: 44)

                Text("\(Int(study.matchScore * 100))%")
                    .font(VDTypography.captionSmall)
                    .foregroundStyle(VDColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: VDSpacing.xxs) {
                Text(study.studyTitle)
                    .font(VDTypography.bodyBold)
                    .foregroundStyle(VDColors.textPrimary)
                    .lineLimit(1)

                Text(study.sponsor)
                    .font(VDTypography.captionSmall)
                    .foregroundStyle(VDColors.textSecondary)
            }

            Spacer(minLength: 0)

            Text(study.compensation)
                .font(VDTypography.bodyBold)
                .foregroundStyle(VDColors.successGreen)
        }
        .vdCard(padding: VDSpacing.md)
    }
}

#Preview {
    DashboardView()
        .environment(WearableAggregatorService())
        .preferredColorScheme(.dark)
}
