import SwiftUI

struct RoomsView: View {
    @Environment(AirQualityService.self) private var airService
    @State private var selectedPropertyIndex = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if airService.properties.count > 1 {
                    Picker("Property", selection: $selectedPropertyIndex) {
                        ForEach(airService.properties.indices, id: \.self) { i in
                            Text(airService.properties[i].name).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }

                ScrollView {
                    if selectedPropertyIndex < airService.properties.count {
                        let property = airService.properties[selectedPropertyIndex]
                        LazyVStack(spacing: 12) {
                            ForEach(property.rooms) { room in
                                NavigationLink(value: room.id) {
                                    RoomDetailCard(room: room)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(AppColors.background)
            .navigationTitle("Rooms")
            .navigationDestination(for: UUID.self) { roomID in
                if let property = airService.properties[safe: selectedPropertyIndex],
                   let room = property.rooms.first(where: { $0.id == roomID }) {
                    RoomDetailView(room: room, readings: airService.readings.filter { $0.roomID == roomID })
                }
            }
        }
    }
}

struct RoomDetailCard: View {
    let room: Room

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: room.type.icon)
                    .font(.title2)
                    .foregroundStyle(AppColors.accent)
                VStack(alignment: .leading) {
                    Text(room.name).font(.headline)
                    Text(room.type.label).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if let reading = room.latestReading {
                    VStack {
                        Text("\(reading.aqi)")
                            .font(.title2.bold())
                            .foregroundStyle(reading.level.color)
                        Text(reading.level.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let reading = room.latestReading {
                HStack(spacing: 16) {
                    MetricPill(icon: "aqi.medium", label: "PM2.5", value: String(format: "%.1f", reading.pm25), unit: "µg/m³")
                    MetricPill(icon: "carbon.dioxide.cloud", label: "CO2", value: "\(Int(reading.co2))", unit: "ppm")
                    MetricPill(icon: "humidity", label: "Humidity", value: "\(Int(reading.humidity))", unit: "%")
                    MetricPill(icon: "thermometer.medium", label: "Temp", value: "\(Int(reading.temperature))", unit: "°F")
                }
            }

            if room.hasFilter {
                HStack {
                    Image(systemName: "air.purifier")
                        .foregroundStyle(room.needsFilterChange ? AppColors.danger : AppColors.success)
                    Text(room.needsFilterChange ? "Filter needs replacing" : "\(room.filterDaysRemaining ?? 0) days remaining")
                        .font(.caption)
                        .foregroundStyle(room.needsFilterChange ? AppColors.danger : .secondary)
                }
            }
        }
        .padding()
        .glassCard()
    }
}

struct MetricPill: View {
    let icon: String
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.caption2).foregroundStyle(AppColors.accent)
            Text(value).font(.caption.bold())
            Text(unit).font(.system(size: 8)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RoomDetailView: View {
    let room: Room
    let readings: [AirReading]

    var sortedReadings: [AirReading] {
        readings.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current reading
                if let latest = room.latestReading {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(latest.level.color.opacity(0.3), lineWidth: 6)
                                .frame(width: 100, height: 100)
                            VStack {
                                Text("\(latest.aqi)")
                                    .font(.system(size: 36, weight: .bold))
                                Text(latest.level.label)
                                    .font(.caption)
                                    .foregroundStyle(latest.level.color)
                            }
                        }

                        // Detailed metrics
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            DetailMetric(label: "PM2.5", value: String(format: "%.1f", latest.pm25), unit: "µg/m³",
                                         status: latest.pm25 < 12 ? .good : latest.pm25 < 35 ? .moderate : .bad)
                            DetailMetric(label: "PM10", value: String(format: "%.1f", latest.pm10), unit: "µg/m³",
                                         status: latest.pm10 < 54 ? .good : latest.pm10 < 154 ? .moderate : .bad)
                            DetailMetric(label: "CO2", value: "\(Int(latest.co2))", unit: "ppm",
                                         status: latest.co2 < 800 ? .good : latest.co2 < 1200 ? .moderate : .bad)
                            DetailMetric(label: "VOC", value: "\(Int(latest.voc))", unit: "ppb",
                                         status: latest.voc < 300 ? .good : latest.voc < 500 ? .moderate : .bad)
                            DetailMetric(label: "Temp", value: "\(Int(latest.temperature))", unit: "°F",
                                         status: latest.temperature > 65 && latest.temperature < 78 ? .good : .moderate)
                            DetailMetric(label: "Humidity", value: "\(Int(latest.humidity))", unit: "%",
                                         status: latest.humidity > 30 && latest.humidity < 60 ? .good : .moderate)
                        }
                    }
                    .padding()
                    .glassCard()
                }

                // Reading history
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Readings").font(.headline)
                    ForEach(sortedReadings.prefix(12)) { reading in
                        HStack {
                            Text(reading.timestamp, style: .time).font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text("AQI \(reading.aqi)").font(.caption.bold()).foregroundStyle(reading.level.color)
                            Text("PM \(String(format: "%.0f", reading.pm25))").font(.caption)
                            Text("CO2 \(Int(reading.co2))").font(.caption)
                        }
                    }
                }
                .padding()
                .glassCard()
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle(room.name)
    }
}

enum MetricStatus { case good, moderate, bad }

struct DetailMetric: View {
    let label: String
    let value: String
    let unit: String
    let status: MetricStatus

    var statusColor: Color {
        switch status {
        case .good: AppColors.success
        case .moderate: AppColors.warning
        case .bad: AppColors.danger
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).foregroundStyle(statusColor)
            Text(unit).font(.caption2).foregroundStyle(.secondary)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
