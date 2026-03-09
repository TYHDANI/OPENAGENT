import SwiftUI

struct StudiesView: View {
    @Environment(WearableAggregatorService.self) private var service
    @State private var selectedStudy: StudyMatch?
    @State private var sortByScore = true

    private var sortedStudies: [StudyMatch] {
        if sortByScore {
            return service.studyMatches.sorted { $0.matchScore > $1.matchScore }
        } else {
            return service.studyMatches
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: VDSpacing.xl) {
                    // MARK: - Earnings Summary
                    earningsSummary

                    // MARK: - Sort Controls
                    sortControls

                    // MARK: - Study Cards
                    if sortedStudies.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: VDSpacing.md) {
                            ForEach(sortedStudies) { study in
                                StudyCard(study: study)
                                    .onTapGesture { selectedStudy = study }
                            }
                        }
                    }
                }
                .padding(.horizontal, VDSpacing.lg)
                .padding(.bottom, VDSpacing.xxxl)
            }
            .background(VDColors.background.ignoresSafeArea())
            .navigationTitle("Studies")
            .sheet(item: $selectedStudy) { study in
                StudyDetailSheet(study: study)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Earnings Summary

    @ViewBuilder
    private var earningsSummary: some View {
        VStack(spacing: VDSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: VDSpacing.xxs) {
                    Text("Potential Earnings")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColors.textSecondary)

                    Text(totalCompensation)
                        .font(VDTypography.metricMedium)
                        .foregroundStyle(VDColors.successGreen)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: VDSpacing.xxs) {
                    Text("Available Studies")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColors.textSecondary)

                    Text("\(service.studyMatches.count)")
                        .font(VDTypography.metricMedium)
                        .foregroundStyle(VDColors.textPrimary)
                }
            }

            // Match quality bar
            HStack(spacing: VDSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(VDColors.accentPurple)

                Text("Avg. Match Score: \(Int(averageMatchScore * 100))%")
                    .font(VDTypography.caption)
                    .foregroundStyle(VDColors.textSecondary)

                Spacer()

                Text("\(highMatchCount) high-quality matches")
                    .font(VDTypography.captionSmall)
                    .foregroundStyle(VDColors.accentTeal)
            }
        }
        .vdCard()
        .overlay(
            RoundedRectangle(cornerRadius: VDRadius.lg, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [VDColors.successGreen.opacity(0.3), VDColors.accentTeal.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Sort Controls

    @ViewBuilder
    private var sortControls: some View {
        HStack {
            Text("Sort by")
                .font(VDTypography.caption)
                .foregroundStyle(VDColors.textTertiary)

            sortChip(title: "Match Score", isSelected: sortByScore) {
                withAnimation(VDAnimation.springBounce) { sortByScore = true }
            }

            sortChip(title: "Default", isSelected: !sortByScore) {
                withAnimation(VDAnimation.springBounce) { sortByScore = false }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func sortChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(VDTypography.captionSmall)
                .foregroundStyle(isSelected ? VDColors.textInverse : VDColors.textSecondary)
                .padding(.horizontal, VDSpacing.md)
                .padding(.vertical, VDSpacing.xs)
                .background(isSelected ? VDColors.accentTeal : VDColors.surfaceTertiary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: VDSpacing.lg) {
            Image(systemName: "flask")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(VDColors.textTertiary)

            Text("No studies available")
                .font(VDTypography.cardTitle)
                .foregroundStyle(VDColors.textSecondary)

            Text("Connect more wearables to improve your match scores and unlock research opportunities.")
                .font(VDTypography.body)
                .foregroundStyle(VDColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, VDSpacing.xxxl)
    }

    // MARK: - Computed Properties

    private var totalCompensation: String {
        // Parse dollar amounts from compensation strings
        let total = service.studyMatches.compactMap { study -> Int? in
            let cleaned = study.compensation
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
            return Int(cleaned)
        }.reduce(0, +)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "$0"
    }

    private var averageMatchScore: Double {
        guard !service.studyMatches.isEmpty else { return 0 }
        return service.studyMatches.map(\.matchScore).reduce(0, +) / Double(service.studyMatches.count)
    }

    private var highMatchCount: Int {
        service.studyMatches.filter { $0.matchScore >= 0.7 }.count
    }
}

// MARK: - Study Card

struct StudyCard: View {
    let study: StudyMatch

    var body: some View {
        VStack(alignment: .leading, spacing: VDSpacing.md) {
            // Header: Match Score + Status
            HStack(alignment: .top) {
                // Match Score Ring
                ZStack {
                    VDRingProgressView(
                        progress: study.matchScore,
                        lineWidth: 5,
                        gradient: matchGradient
                    )
                    .frame(width: 52, height: 52)

                    Text("\(Int(study.matchScore * 100))%")
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: VDSpacing.xxs) {
                    Text(study.studyTitle)
                        .font(VDTypography.cardTitle)
                        .foregroundStyle(VDColors.textPrimary)
                        .lineLimit(2)

                    Text(study.sponsor)
                        .font(VDTypography.caption)
                        .foregroundStyle(VDColors.textSecondary)
                }

                Spacer(minLength: 0)

                // Compensation
                VStack(alignment: .trailing, spacing: VDSpacing.xxs) {
                    Text(study.compensation)
                        .font(VDTypography.metricSmall)
                        .foregroundStyle(VDColors.successGreen)

                    Text("\(study.durationWeeks) weeks")
                        .font(VDTypography.captionSmall)
                        .foregroundStyle(VDColors.textTertiary)
                }
            }

            Divider().overlay(VDColors.divider)

            // Required Metrics
            VStack(alignment: .leading, spacing: VDSpacing.sm) {
                Text("Required Data")
                    .font(VDTypography.captionSmall)
                    .foregroundStyle(VDColors.textTertiary)

                FlowLayout(spacing: VDSpacing.sm) {
                    ForEach(study.requiredMetrics) { metric in
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

            // Match Quality Indicator
            HStack(spacing: VDSpacing.sm) {
                Image(systemName: matchIcon)
                    .font(.system(size: 12, weight: .medium))

                Text(matchLabel)
                    .font(VDTypography.caption)

                Spacer()

                statusBadge
            }
            .foregroundStyle(matchColor)
        }
        .vdCard()
        .vdGlow(study.matchScore >= 0.85 ? VDColors.successGreen : .clear, radius: 8)
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(study.status.rawValue.capitalized)
            .font(VDTypography.captionSmall)
            .foregroundStyle(statusColor)
            .padding(.horizontal, VDSpacing.sm)
            .padding(.vertical, VDSpacing.xxs)
            .background(statusColor.opacity(0.12))
            .clipShape(Capsule())
    }

    private var matchGradient: LinearGradient {
        switch study.matchScore {
        case 0.8...1.0: VDColors.gradientScore
        case 0.5..<0.8: VDColors.gradientTeal
        default:
            LinearGradient(
                colors: [VDColors.textTertiary, VDColors.textTertiary],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var matchIcon: String {
        switch study.matchScore {
        case 0.8...1.0: "checkmark.seal.fill"
        case 0.5..<0.8: "seal.fill"
        default: "xmark.seal"
        }
    }

    private var matchLabel: String {
        switch study.matchScore {
        case 0.8...1.0: "Excellent match"
        case 0.5..<0.8: "Good match"
        case 0.3..<0.5: "Partial match"
        default: "Low match — connect more devices"
        }
    }

    private var matchColor: Color {
        switch study.matchScore {
        case 0.8...1.0: VDColors.successGreen
        case 0.5..<0.8: VDColors.accentTeal
        case 0.3..<0.5: VDColors.warningAmber
        default: VDColors.textTertiary
        }
    }

    private var statusColor: Color {
        switch study.status {
        case .available: VDColors.accentTeal
        case .applied: VDColors.sleepBlue
        case .enrolled: VDColors.successGreen
        case .completed: VDColors.accentPurple
        case .declined: VDColors.textTertiary
        }
    }
}

// MARK: - Study Detail Sheet

struct StudyDetailSheet: View {
    let study: StudyMatch
    @Environment(\.dismiss) private var dismiss
    @State private var showApplyConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: VDSpacing.xl) {
                    // Match Score Hero
                    matchScoreHero

                    // Study Details
                    studyDetails

                    // Required Metrics
                    requiredMetricsSection

                    // Compensation Breakdown
                    compensationSection

                    // Apply Button
                    if study.status == .available {
                        applyButton
                    }
                }
                .padding(VDSpacing.lg)
            }
            .background(VDColors.background.ignoresSafeArea())
            .navigationTitle("Study Details")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(VDColors.accentTeal)
                }
            }
            .alert("Apply to Study?", isPresented: $showApplyConfirmation) {
                Button("Apply", role: .none) { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your anonymized health data will be shared with \(study.sponsor) for eligibility screening.")
            }
        }
    }

    @ViewBuilder
    private var matchScoreHero: some View {
        HStack {
            Spacer()

            VStack(spacing: VDSpacing.md) {
                ZStack {
                    VDRingProgressView(
                        progress: study.matchScore,
                        lineWidth: 10,
                        gradient: VDColors.gradientScore
                    )
                    .frame(width: 100, height: 100)

                    VStack(spacing: 0) {
                        Text("\(Int(study.matchScore * 100))%")
                            .font(VDTypography.metricMedium)
                            .foregroundStyle(VDColors.textPrimary)
                        Text("match")
                            .font(VDTypography.captionSmall)
                            .foregroundStyle(VDColors.textTertiary)
                    }
                }
                .vdGlow(VDColors.accentTeal, radius: 12)

                Text(study.studyTitle)
                    .font(VDTypography.sectionTitle)
                    .foregroundStyle(VDColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(study.sponsor)
                    .font(VDTypography.body)
                    .foregroundStyle(VDColors.textSecondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var studyDetails: some View {
        VStack(spacing: VDSpacing.md) {
            detailRow(icon: "clock", label: "Duration", value: "\(study.durationWeeks) weeks")
            detailRow(icon: "building.2", label: "Sponsor", value: study.sponsor)
            detailRow(icon: "tag", label: "Status", value: study.status.rawValue.capitalized)
        }
        .vdCard()
    }

    @ViewBuilder
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(VDColors.accentTeal)
                .frame(width: 24)

            Text(label)
                .font(VDTypography.body)
                .foregroundStyle(VDColors.textSecondary)

            Spacer()

            Text(value)
                .font(VDTypography.bodyBold)
                .foregroundStyle(VDColors.textPrimary)
        }
    }

    @ViewBuilder
    private var requiredMetricsSection: some View {
        VStack(alignment: .leading, spacing: VDSpacing.sm) {
            Text("Required Data Types")
                .font(VDTypography.cardTitle)
                .foregroundStyle(VDColors.textPrimary)

            ForEach(study.requiredMetrics) { metric in
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

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(VDColors.successGreen)
                }
            }
        }
        .vdCard()
    }

    @ViewBuilder
    private var compensationSection: some View {
        VStack(spacing: VDSpacing.md) {
            HStack {
                Text("Compensation")
                    .font(VDTypography.cardTitle)
                    .foregroundStyle(VDColors.textPrimary)

                Spacer()

                Text(study.compensation)
                    .font(VDTypography.metricMedium)
                    .foregroundStyle(VDColors.successGreen)
            }

            HStack(spacing: VDSpacing.sm) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(VDColors.accentPurple)

                Text("Payments held in smart contract escrow. Released on milestone completion.")
                    .font(VDTypography.captionSmall)
                    .foregroundStyle(VDColors.textTertiary)
            }
        }
        .vdCard()
    }

    @ViewBuilder
    private var applyButton: some View {
        Button {
            showApplyConfirmation = true
        } label: {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("Apply to Study")
            }
            .font(VDTypography.bodyBold)
            .foregroundStyle(VDColors.textInverse)
            .frame(maxWidth: .infinity)
            .padding(VDSpacing.lg)
            .background(VDColors.gradientTeal)
            .clipShape(RoundedRectangle(cornerRadius: VDRadius.lg, style: .continuous))
            .vdGlow(VDColors.accentTeal, radius: 8)
        }
    }
}

#Preview {
    StudiesView()
        .environment(WearableAggregatorService())
        .preferredColorScheme(.dark)
}
