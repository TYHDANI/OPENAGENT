import SwiftUI

struct InsightsView: View {
    @Environment(WearableAggregatorService.self) private var service
    @State private var selectedCategory: HealthInsight.InsightCategory?
    @State private var selectedInsight: HealthInsight?

    private var filteredInsights: [HealthInsight] {
        guard let category = selectedCategory else { return service.insights }
        return service.insights.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VDSpacing.xl) {
                    // MARK: - Stats Bar
                    insightStatsBar

                    // MARK: - Category Filter
                    categoryFilter

                    // MARK: - Insight Cards
                    if filteredInsights.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: VDSpacing.md) {
                            ForEach(filteredInsights) { insight in
                                InsightCard(insight: insight)
                                    .onTapGesture { selectedInsight = insight }
                            }
                        }
                    }
                }
                .padding(.horizontal, VDSpacing.lg)
                .padding(.bottom, VDSpacing.xxxl)
            }
            .background(VDColors.background.ignoresSafeArea())
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await service.syncAll() }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(VDColors.accentTeal)
                    }
                }
            }
            .sheet(item: $selectedInsight) { insight in
                InsightDetailSheet(insight: insight)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Stats Bar

    @ViewBuilder
    private var insightStatsBar: some View {
        HStack(spacing: VDSpacing.lg) {
            statItem(
                icon: "lightbulb.fill",
                value: "\(service.insights.count)",
                label: "Total",
                color: VDColors.accentTeal
            )

            Divider().frame(height: 32).overlay(VDColors.divider)

            statItem(
                icon: "circle.fill",
                value: "\(service.unreadInsights)",
                label: "Unread",
                color: VDColors.warningAmber
            )

            Divider().frame(height: 32).overlay(VDColors.divider)

            statItem(
                icon: "exclamationmark.triangle.fill",
                value: "\(service.insights.filter { $0.severity == .alert }.count)",
                label: "Alerts",
                color: VDColors.heartRed
            )
        }
        .vdCard()
    }

    @ViewBuilder
    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: VDSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
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

    // MARK: - Category Filter

    @ViewBuilder
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: VDSpacing.sm) {
                categoryChip(title: "All", category: nil)

                ForEach(HealthInsight.InsightCategory.allCases, id: \.rawValue) { category in
                    categoryChip(title: category.rawValue, category: category)
                }
            }
        }
    }

    @ViewBuilder
    private func categoryChip(title: String, category: HealthInsight.InsightCategory?) -> some View {
        let isSelected = selectedCategory == category
        Button {
            withAnimation(VDAnimation.springBounce) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: VDSpacing.xs) {
                if let category {
                    Image(systemName: iconForCategory(category))
                        .font(.system(size: 10, weight: .bold))
                }
                Text(title)
                    .font(VDTypography.caption)
            }
            .foregroundStyle(isSelected ? VDColors.textInverse : VDColors.textSecondary)
            .padding(.horizontal, VDSpacing.md)
            .padding(.vertical, VDSpacing.sm)
            .background(isSelected ? VDColors.accentTeal : VDColors.surfaceTertiary)
            .clipShape(Capsule())
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: VDSpacing.lg) {
            Image(systemName: "lightbulb.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(VDColors.textTertiary)

            Text("No insights yet")
                .font(VDTypography.cardTitle)
                .foregroundStyle(VDColors.textSecondary)

            Text("Connect more devices and sync data to generate health insights.")
                .font(VDTypography.body)
                .foregroundStyle(VDColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, VDSpacing.xxxl)
    }

    private func iconForCategory(_ category: HealthInsight.InsightCategory) -> String {
        switch category {
        case .anomaly: "exclamationmark.triangle.fill"
        case .trend: "chart.line.uptrend.xyaxis"
        case .correlation: "point.3.connected.trianglepath.dotted"
        case .recommendation: "hand.thumbsup.fill"
        case .achievement: "star.fill"
        }
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: HealthInsight

    var body: some View {
        VStack(alignment: .leading, spacing: VDSpacing.md) {
            // Header row
            HStack(spacing: VDSpacing.md) {
                // Severity indicator
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(insight.severity.color)
                    .frame(width: 4, height: 40)

                VStack(alignment: .leading, spacing: VDSpacing.xxs) {
                    HStack {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(categoryColor)

                        Text(insight.category.rawValue.uppercased())
                            .font(VDTypography.captionSmall)
                            .foregroundStyle(categoryColor)

                        Spacer()

                        if !insight.isRead {
                            Text("NEW")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(VDColors.textInverse)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(insight.severity.color)
                                .clipShape(Capsule())
                        }

                        Text(insight.generatedAt, format: .relative(presentation: .named))
                            .font(VDTypography.captionSmall)
                            .foregroundStyle(VDColors.textTertiary)
                    }

                    Text(insight.title)
                        .font(VDTypography.cardTitle)
                        .foregroundStyle(VDColors.textPrimary)
                }
            }

            // Description
            Text(insight.description)
                .font(VDTypography.body)
                .foregroundStyle(VDColors.textSecondary)
                .lineLimit(3)

            // Related Metrics
            if !insight.relatedMetrics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: VDSpacing.sm) {
                        ForEach(insight.relatedMetrics) { metric in
                            HStack(spacing: VDSpacing.xs) {
                                Image(systemName: metric.icon)
                                    .font(.system(size: 10, weight: .medium))
                                Text(metric.rawValue)
                                    .font(VDTypography.captionSmall)
                            }
                            .foregroundStyle(metric.color)
                            .padding(.horizontal, VDSpacing.sm)
                            .padding(.vertical, VDSpacing.xs)
                            .background(metric.color.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            // Actionable advice
            if !insight.actionable.isEmpty {
                HStack(spacing: VDSpacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(VDColors.accentTeal)

                    Text(insight.actionable)
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColors.accentTeal)
                }
                .padding(VDSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(VDColors.accentTeal.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: VDRadius.sm, style: .continuous))
            }
        }
        .vdCard()
        .overlay(
            RoundedRectangle(cornerRadius: VDRadius.lg, style: .continuous)
                .strokeBorder(
                    insight.severity == .alert ? insight.severity.color.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
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

    private var categoryColor: Color {
        switch insight.category {
        case .anomaly: VDColors.warningAmber
        case .trend: VDColors.sleepBlue
        case .correlation: VDColors.accentPurple
        case .recommendation: VDColors.accentTeal
        case .achievement: VDColors.successGreen
        }
    }
}

// MARK: - Insight Detail Sheet

struct InsightDetailSheet: View {
    let insight: HealthInsight
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VDSpacing.xl) {
                    // Severity Banner
                    HStack(spacing: VDSpacing.sm) {
                        Image(systemName: severityIcon)
                            .font(.system(size: 20, weight: .semibold))
                        Text(insight.severity.rawValue.uppercased())
                            .font(VDTypography.bodyBold)
                    }
                    .foregroundStyle(insight.severity.color)
                    .frame(maxWidth: .infinity)
                    .padding(VDSpacing.md)
                    .background(insight.severity.color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: VDRadius.md, style: .continuous))

                    // Title & Description
                    VStack(alignment: .leading, spacing: VDSpacing.sm) {
                        Text(insight.title)
                            .font(VDTypography.sectionTitle)
                            .foregroundStyle(VDColors.textPrimary)

                        Text(insight.description)
                            .font(VDTypography.body)
                            .foregroundStyle(VDColors.textSecondary)
                    }

                    // Related Metrics
                    if !insight.relatedMetrics.isEmpty {
                        VStack(alignment: .leading, spacing: VDSpacing.sm) {
                            Text("Related Metrics")
                                .font(VDTypography.bodyBold)
                                .foregroundStyle(VDColors.textPrimary)

                            ForEach(insight.relatedMetrics) { metric in
                                HStack(spacing: VDSpacing.md) {
                                    Image(systemName: metric.icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(metric.color)
                                        .frame(width: 32, height: 32)
                                        .background(metric.color.opacity(0.12))
                                        .clipShape(Circle())

                                    Text(metric.rawValue)
                                        .font(VDTypography.body)
                                        .foregroundStyle(VDColors.textPrimary)

                                    Spacer()

                                    if !metric.unit.isEmpty {
                                        Text(metric.unit)
                                            .font(VDTypography.caption)
                                            .foregroundStyle(VDColors.textTertiary)
                                    }
                                }
                            }
                        }
                        .vdCard()
                    }

                    // Actionable Advice
                    if !insight.actionable.isEmpty {
                        VStack(alignment: .leading, spacing: VDSpacing.sm) {
                            Text("Recommended Action")
                                .font(VDTypography.bodyBold)
                                .foregroundStyle(VDColors.textPrimary)

                            HStack(alignment: .top, spacing: VDSpacing.md) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(VDColors.accentTeal)

                                Text(insight.actionable)
                                    .font(VDTypography.body)
                                    .foregroundStyle(VDColors.textSecondary)
                            }
                        }
                        .vdCard()
                    }

                    // Timestamp
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text("Generated \(insight.generatedAt, format: .dateTime)")
                            .font(VDTypography.captionSmall)
                    }
                    .foregroundStyle(VDColors.textTertiary)
                }
                .padding(VDSpacing.lg)
            }
            .background(VDColors.background.ignoresSafeArea())
            .navigationTitle("Insight Detail")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(VDColors.accentTeal)
                }
            }
        }
    }

    private var severityIcon: String {
        switch insight.severity {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .alert: "exclamationmark.octagon.fill"
        }
    }
}

#Preview {
    InsightsView()
        .environment(WearableAggregatorService())
        .preferredColorScheme(.dark)
}
