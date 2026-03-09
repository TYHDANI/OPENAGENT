import SwiftUI

struct DashboardView: View {
    @Environment(AirQualityService.self) private var airService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Overall AQI
                    overallScoreCard
                    // Alerts banner
                    if !airService.unreadAlerts.isEmpty {
                        alertsBanner
                    }
                    // Filter maintenance
                    if airService.filtersNeedingChange > 0 {
                        filterBanner
                    }
                    // Properties
                    ForEach(airService.homeProperties) { property in
                        PropertyCard(property: property)
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("AirScore")
        }
    }

    private var overallScoreCard: some View {
        let aqi = airService.overallAQI()
        let level = AQILevel.from(aqi: aqi)
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(level.color.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                Circle()
                    .trim(from: 0, to: min(1, Double(aqi) / 300))
                    .stroke(level.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("\(aqi)")
                        .font(AppTypography.score)
                    Text("AQI")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(level.label)
                .font(.headline)
                .foregroundStyle(level.color)
            Text("Home Air Quality")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .accentGlassCard()
    }

    private var alertsBanner: some View {
        HStack {
            Image(systemName: "bell.badge.fill")
                .foregroundStyle(AppColors.warning)
            Text("\(airService.unreadAlerts.count) unread alerts")
                .font(.subheadline)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassCard()
    }

    private var filterBanner: some View {
        HStack {
            Image(systemName: "air.purifier.fill")
                .foregroundStyle(AppColors.danger)
            Text("\(airService.filtersNeedingChange) filters need replacing")
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .glassCard()
    }
}

struct PropertyCard: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: property.type.icon)
                    .foregroundStyle(AppColors.accent)
                Text(property.name).font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(property.overallLevel.color)
                        .frame(width: 10, height: 10)
                    Text("\(property.overallAQI) AQI")
                        .font(.subheadline.bold())
                        .foregroundStyle(property.overallLevel.color)
                }
            }

            ForEach(property.rooms) { room in
                RoomRow(room: room)
            }
        }
        .padding()
        .glassCard()
    }
}

struct RoomRow: View {
    let room: Room

    var body: some View {
        HStack {
            Image(systemName: room.type.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(room.name).font(.subheadline)
            Spacer()
            if let reading = room.latestReading {
                HStack(spacing: 8) {
                    Label("\(Int(reading.pm25))", systemImage: "aqi.medium")
                        .font(.caption)
                    Label("\(Int(reading.co2))", systemImage: "carbon.dioxide.cloud")
                        .font(.caption)
                    Text("\(reading.aqi)")
                        .font(.caption.bold())
                        .foregroundStyle(reading.level.color)
                }
            } else {
                Text("No data").font(.caption).foregroundStyle(.secondary)
            }
            if room.needsFilterChange {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(AppColors.danger)
            }
        }
    }
}
