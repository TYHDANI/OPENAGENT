import SwiftUI

struct FleetView: View {
    @Environment(AirQualityService.self) private var airService
    @Environment(StoreManager.self) private var store

    var body: some View {
        NavigationStack {
            if store.currentTier == .fleet {
                fleetDashboard
            } else {
                upgradePrompt
            }
        }
    }

    private var fleetDashboard: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Fleet overview
                HStack(spacing: 12) {
                    FleetStatCard(title: "Properties", value: "\(airService.fleetProperties.count)", icon: "building.2.fill")
                    FleetStatCard(title: "Avg AQI", value: "\(airService.overallAQI(fleetOnly: true))", icon: "gauge.open.with.lines.needle.33percent")
                    FleetStatCard(title: "Alerts", value: "\(airService.unreadAlerts.count)", icon: "bell.badge")
                }

                // Fleet properties
                ForEach(airService.fleetProperties) { property in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: property.type.icon)
                                .foregroundStyle(AppColors.accent)
                            VStack(alignment: .leading) {
                                Text(property.name).font(.headline)
                                Text(property.address).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(property.overallAQI) AQI")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(property.overallLevel.color)
                                Text("\(property.rooms.count) zones")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }

                        // Room status grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(property.rooms) { room in
                                VStack(spacing: 4) {
                                    Text(room.name)
                                        .font(.caption2)
                                        .lineLimit(1)
                                    if let r = room.latestReading {
                                        Text("\(r.aqi)")
                                            .font(.headline)
                                            .foregroundStyle(r.level.color)
                                    } else {
                                        Text("—").font(.headline).foregroundStyle(.secondary)
                                    }
                                }
                                .padding(6)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        if property.filtersNeedingChange > 0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppColors.warning)
                                Text("\(property.filtersNeedingChange) filters need replacing")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .glassCard()
                }
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle("Fleet")
    }

    private var upgradePrompt: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.accent)
            Text("Fleet Management")
                .font(.title.bold())
            Text("Monitor air quality across multiple properties with the Fleet plan.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            VStack(alignment: .leading, spacing: 8) {
                FeatureCheckItem(text: "Up to 50 properties")
                FeatureCheckItem(text: "500 room monitoring zones")
                FeatureCheckItem(text: "Fleet-wide AQI dashboard")
                FeatureCheckItem(text: "Maintenance scheduling")
                FeatureCheckItem(text: "CSV export & reporting")
            }
            .padding()
            Button {
                // Trigger subscription flow
            } label: {
                Text("Upgrade to Fleet — $29.99/mo")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.accent)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            Spacer()
        }
        .background(AppColors.background)
        .navigationTitle("Fleet")
    }
}

struct FleetStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title3).foregroundStyle(AppColors.accent)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard()
    }
}

struct FeatureCheckItem: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(AppColors.accent)
            Text(text)
        }
    }
}
