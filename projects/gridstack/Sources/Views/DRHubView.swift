import SwiftUI

struct DRHubView: View {
    @Environment(EnergyService.self) private var service
    @State private var selectedFilter: DRFilter = .all

    enum DRFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case upcoming = "Upcoming"
        case completed = "Completed"
    }

    var filteredEvents: [DemandResponseEvent] {
        switch selectedFilter {
        case .all: return service.demandResponseEvents.sorted { $0.eventDate > $1.eventDate }
        case .active: return service.activeDREvents
        case .upcoming: return service.upcomingDREvents.sorted { $0.eventDate < $1.eventDate }
        case .completed: return service.completedDREvents.sorted { $0.eventDate > $1.eventDate }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    drSummaryCard
                    filterPicker
                    eventsList
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("DR Hub")
            .darkNavigationBar()
        }
    }

    // MARK: - Summary Card

    private var drSummaryCard: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Demand Response")
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Earn by reducing energy during peak demand")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.largeTitle)
                    .foregroundStyle(AppColors.info)
            }

            Divider().overlay(AppColors.divider)

            HStack(spacing: AppSpacing.lg) {
                summaryMetric(
                    value: formattedCurrency(service.totalDREarnings),
                    label: "Total Earned",
                    color: AppColors.success
                )
                summaryMetric(
                    value: "\(service.completedDREvents.count)",
                    label: "Events Done",
                    color: AppColors.info
                )
                summaryMetric(
                    value: "\(service.upcomingDREvents.count)",
                    label: "Upcoming",
                    color: AppColors.warning
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .strokeBorder(AppColors.info.opacity(0.2), lineWidth: 1)
        )
    }

    private func summaryMetric(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(value)
                .font(AppTypography.metricSmall)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filter

    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(DRFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Events List

    private var eventsList: some View {
        LazyVStack(spacing: AppSpacing.sm) {
            if filteredEvents.isEmpty {
                emptyState
            } else {
                ForEach(filteredEvents) { event in
                    eventCard(event)
                }
            }
        }
    }

    private func eventCard(_ event: DemandResponseEvent) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                statusBadge(event.status)
                Spacer()
                Text(event.eventType.rawValue)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.textTertiary)
            }

            Text(event.programName)
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: AppSpacing.md) {
                iconDetail(icon: "calendar", text: formatDate(event.eventDate))
                iconDetail(icon: "clock", text: "\(event.durationMinutes) min")
            }

            Divider().overlay(AppColors.divider)

            HStack {
                if event.status == .completed || event.status == .active {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(AppColors.info)
                        Text(String(format: "%.1f kWh reduced", event.kWhReduced))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Spacer()
                Text(formattedCurrency(event.earningsUSD))
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(event.status == .completed ? AppColors.success : AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(borderColor(for: event.status), lineWidth: 1)
        )
    }

    private func statusBadge(_ status: DemandResponseEvent.DREventStatus) -> some View {
        Text(status.rawValue.uppercased())
            .font(AppTypography.badge)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background(statusColor(status))
            .clipShape(Capsule())
    }

    private func iconDetail(icon: String, text: String) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(AppColors.textTertiary)
            Text(text)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.textTertiary)
            Text("No \(selectedFilter.rawValue.lowercased()) events")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }

    // MARK: - Helpers

    private func statusColor(_ status: DemandResponseEvent.DREventStatus) -> Color {
        switch status {
        case .upcoming: return AppColors.warning
        case .active: return AppColors.success
        case .completed: return AppColors.info
        case .missed: return AppColors.error
        }
    }

    private func borderColor(for status: DemandResponseEvent.DREventStatus) -> Color {
        switch status {
        case .active: return AppColors.success.opacity(0.3)
        case .upcoming: return AppColors.warning.opacity(0.2)
        default: return AppColors.divider
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func formattedCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

#Preview {
    DRHubView()
        .environment(EnergyService())
        .environment(StoreManager())
        .preferredColorScheme(.dark)
}
