import SwiftUI

struct SettingsView: View {
    @Environment(StoreManager.self) private var store
    @Environment(AirQualityService.self) private var airService

    var body: some View {
        NavigationStack {
            List {
                Section("Subscription") {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(AppColors.accent)
                        VStack(alignment: .leading) {
                            Text(store.currentTier.label).font(.headline)
                            Text(store.currentTier.monthlyPrice + "/mo").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if store.currentTier == .free {
                            Button("Upgrade") { }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColors.accent)
                        }
                    }
                    LabeledContent("Properties", value: "\(airService.properties.count)/\(store.currentTier.maxProperties)")
                    LabeledContent("Rooms", value: "\(airService.properties.flatMap(\.rooms).count)/\(store.currentTier.maxRooms)")
                }

                Section("Properties") {
                    ForEach(airService.properties) { property in
                        HStack {
                            Image(systemName: property.type.icon)
                                .foregroundStyle(AppColors.accent)
                            VStack(alignment: .leading) {
                                Text(property.name).font(.subheadline.bold())
                                Text("\(property.rooms.count) rooms").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if property.isFleetProperty {
                                Text("Fleet").font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(AppColors.accent.opacity(0.2))
                                    .foregroundStyle(AppColors.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Section("Alerts") {
                    Toggle("AQI Spike Alerts", isOn: .constant(true))
                    Toggle("CO2 Alerts", isOn: .constant(true))
                    Toggle("Filter Reminders", isOn: .constant(true))
                    Toggle("Humidity Alerts", isOn: .constant(true))
                }

                Section("Data") {
                    Button {
                        airService.save()
                    } label: {
                        Label("Save Data", systemImage: "arrow.down.doc")
                    }
                    Button {
                        airService.load()
                    } label: {
                        Label("Reload Data", systemImage: "arrow.clockwise")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("App", value: "AirScore")
                    Button("Restore Purchases") {
                        Task { await store.restore() }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
