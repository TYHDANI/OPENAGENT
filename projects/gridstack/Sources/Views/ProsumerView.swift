import SwiftUI
import Charts

struct ProsumerView: View {
    @Environment(EnergyService.self) private var service
    @State private var selectedEarningsPeriod: TimePeriod = .month

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    profileHeader
                    certificationCard
                    earningsHistoryCard
                    homeSetupCard
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Prosumer")
            .darkNavigationBar()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppGradient.accent(opacity: 0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.accent)
            }

            Text(service.prosumerProfile.displayName)
                .font(AppTypography.pageTitle)
                .foregroundStyle(AppColors.textPrimary)

            // Prosumer level
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "shield.checkered")
                    .foregroundStyle(AppColors.accent)
                Text(prosumerLevel)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.accent)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.accentLight)
            .clipShape(Capsule())

            // Progress
            VStack(spacing: AppSpacing.xxs) {
                HStack {
                    Text("Certification Progress")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text("\(completedCerts)/\(totalCerts)")
                        .font(AppTypography.captionBold)
                        .foregroundStyle(AppColors.accent)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(AppColors.tertiaryBackground)
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(AppGradient.accent())
                            .frame(width: geo.size.width * service.certificationProgress)
                    }
                }
                .frame(height: 8)
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

    // MARK: - Certifications

    private var certificationCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Certifications", systemImage: "checkmark.seal.fill")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            ForEach(service.prosumerProfile.certifications) { cert in
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: cert.icon)
                        .font(.title3)
                        .foregroundStyle(cert.isCompleted ? AppColors.accent : AppColors.textTertiary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(cert.name)
                            .font(AppTypography.bodyBold)
                            .foregroundStyle(cert.isCompleted ? AppColors.textPrimary : AppColors.textSecondary)
                        Text(cert.description)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: cert.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(cert.isCompleted ? AppColors.success : AppColors.textTertiary)
                }
                .padding(.vertical, AppSpacing.xs)

                if cert.id != service.prosumerProfile.certifications.last?.id {
                    Divider().overlay(AppColors.divider)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    // MARK: - Earnings History

    private var earningsHistoryCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Label("Earnings History", systemImage: "chart.line.uptrend.xyaxis")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Picker("Period", selection: $selectedEarningsPeriod) {
                    Text("7d").tag(TimePeriod.week)
                    Text("30d").tag(TimePeriod.month)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }

            let days = selectedEarningsPeriod == .week ? 7 : 30
            let data = service.dailyEarnings(for: days)

            Chart {
                ForEach(data, id: \.date) { entry in
                    LineMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Earnings", entry.amount)
                    )
                    .foregroundStyle(AppColors.accent)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", entry.date, unit: .day),
                        y: .value("Earnings", entry.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.accent.opacity(0.3), AppColors.accent.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxisLabel("USD")
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(days / 7, 1))) { _ in
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

            let total = data.reduce(0) { $0 + $1.amount }
            let avgDaily = data.isEmpty ? 0 : total / Double(data.count)

            HStack {
                VStack(alignment: .leading) {
                    Text("Total")
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.textTertiary)
                    Text(formattedCurrency(total))
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.success)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Daily Avg")
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.textTertiary)
                    Text(formattedCurrency(avgDaily))
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    // MARK: - Home Setup

    private var homeSetupCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Home Setup", systemImage: "house.fill")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            let profile = service.prosumerProfile

            setupRow(icon: "ruler", label: "Home Size", value: profile.homeSize.rawValue)
            setupRow(icon: "fan.fill", label: "HVAC Type", value: profile.hvacType.rawValue)
            setupRow(icon: "thermometer", label: "Thermostat", value: profile.smartThermostat?.rawValue ?? "None")
            setupRow(icon: "building.columns", label: "Utility", value: profile.utilityProvider)
            setupRow(icon: "dollarsign.circle", label: "Rate", value: String(format: "$%.2f/kWh", profile.electricityRatePerKWh))
            setupRow(icon: "mappin.circle", label: "State", value: profile.state)

            Divider().overlay(AppColors.divider)

            HStack(spacing: AppSpacing.lg) {
                equipmentBadge(icon: "sun.max.fill", label: "Solar", active: profile.hasSolar)
                equipmentBadge(icon: "battery.100.bolt", label: "Battery", active: profile.hasBattery)
                equipmentBadge(icon: "cpu", label: "Miner", active: profile.hasMiningRig)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private func setupRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: 24)
            Text(label)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.vertical, AppSpacing.xxs)
    }

    private func equipmentBadge(icon: String, label: String, active: Bool) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(active ? AppColors.accent : AppColors.textTertiary)
            Text(label)
                .font(AppTypography.caption2)
                .foregroundStyle(active ? AppColors.textPrimary : AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(active ? AppColors.accentLight : AppColors.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Helpers

    private var completedCerts: Int {
        service.prosumerProfile.certifications.filter { $0.isCompleted }.count
    }

    private var totalCerts: Int {
        service.prosumerProfile.certifications.count
    }

    private var prosumerLevel: String {
        let progress = service.certificationProgress
        if progress >= 0.75 { return "Grid Guardian" }
        if progress >= 0.50 { return "Power Producer" }
        if progress >= 0.25 { return "Energy Explorer" }
        return "Grid Rookie"
    }

    private func formattedCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}

#Preview {
    ProsumerView()
        .environment(EnergyService())
        .environment(StoreManager())
        .preferredColorScheme(.dark)
}
