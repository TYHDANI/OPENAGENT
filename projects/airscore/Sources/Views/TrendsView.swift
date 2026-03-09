import SwiftUI

struct TrendsView: View {
    @Environment(AirQualityService.self) private var airService
    @State private var selectedMetric: TrendMetric = .aqi
    @State private var selectedTimeRange: TimeRange = .day

    enum TrendMetric: String, CaseIterable {
        case aqi = "AQI", pm25 = "PM2.5", co2 = "CO2", humidity = "Humidity"
    }
    enum TimeRange: String, CaseIterable { case day = "24h", week = "7d", month = "30d" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(TrendMetric.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Picker("Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    // Simple bar chart
                    chartView

                    // Stats
                    statsView
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Trends")
        }
    }

    private var filteredReadings: [AirReading] {
        let cutoff: Date
        switch selectedTimeRange {
        case .day: cutoff = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        case .week: cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month: cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        }
        return airService.readings.filter { $0.timestamp >= cutoff }
    }

    private func metricValue(_ reading: AirReading) -> Double {
        switch selectedMetric {
        case .aqi: Double(reading.aqi)
        case .pm25: reading.pm25
        case .co2: reading.co2
        case .humidity: reading.humidity
        }
    }

    private var chartView: some View {
        let values = filteredReadings.map { metricValue($0) }
        let maxVal = values.max() ?? 1
        let bucketCount = 24
        let bucketSize = max(1, values.count / bucketCount)
        var buckets: [Double] = []
        for i in stride(from: 0, to: values.count, by: bucketSize) {
            let end = min(i + bucketSize, values.count)
            let avg = values[i..<end].reduce(0, +) / Double(end - i)
            buckets.append(avg)
        }

        return VStack(alignment: .leading, spacing: 8) {
            Text(selectedMetric.rawValue).font(.headline)
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(buckets.indices, id: \.self) { i in
                    let normalized = maxVal > 0 ? buckets[i] / maxVal : 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(value: buckets[i]))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(4, CGFloat(normalized) * 120))
                }
            }
            .frame(height: 120)
        }
        .padding()
        .glassCard()
    }

    private func barColor(value: Double) -> Color {
        switch selectedMetric {
        case .aqi:
            if value <= 50 { return AppColors.success }
            if value <= 100 { return .yellow }
            if value <= 150 { return .orange }
            return AppColors.danger
        case .pm25:
            return value < 12 ? AppColors.success : value < 35 ? .yellow : AppColors.danger
        case .co2:
            return value < 800 ? AppColors.success : value < 1200 ? AppColors.warning : AppColors.danger
        case .humidity:
            return (value > 30 && value < 60) ? AppColors.success : AppColors.warning
        }
    }

    private var statsView: some View {
        let values = filteredReadings.map { metricValue($0) }
        let avg = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0

        return HStack(spacing: 12) {
            StatPill(label: "Avg", value: String(format: "%.0f", avg))
            StatPill(label: "Min", value: String(format: "%.0f", minV))
            StatPill(label: "Max", value: String(format: "%.0f", maxV))
            StatPill(label: "Readings", value: "\(values.count)")
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .glassCard()
    }
}
