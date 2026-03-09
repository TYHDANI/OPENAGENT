import Foundation

/// Unified wearable data aggregator inspired by Open Wearables
/// Normalizes health data across Garmin, Whoop, Oura, Apple Health, etc.
@Observable
final class WearableAggregatorService {
    var connections: [WearableConnection] = []
    var dataPoints: [NormalizedDataPoint] = []
    var insights: [HealthInsight] = []
    var studyMatches: [StudyMatch] = []
    var isLoading = false
    var lastSync: Date?

    init() { loadSampleData() }

    // MARK: - Provider Management

    func connectProvider(_ provider: WearableProvider) async {
        if let idx = connections.firstIndex(where: { $0.provider == provider }) {
            connections[idx].status = .syncing
            // Simulate OAuth flow
            try? await Task.sleep(for: .seconds(1))
            connections[idx].status = .connected
            connections[idx].connectedAt = Date()
            await syncProvider(provider)
        } else {
            let conn = WearableConnection(provider: provider, status: .syncing)
            connections.append(conn)
            try? await Task.sleep(for: .seconds(1))
            if let idx = connections.firstIndex(where: { $0.provider == provider }) {
                connections[idx].status = .connected
                connections[idx].connectedAt = Date()
            }
            await syncProvider(provider)
        }
    }

    func disconnectProvider(_ provider: WearableProvider) {
        if let idx = connections.firstIndex(where: { $0.provider == provider }) {
            connections[idx].status = .disconnected
            connections[idx].accessToken = nil
            connections[idx].refreshToken = nil
            dataPoints.removeAll { $0.source == provider }
        }
    }

    // MARK: - Data Sync

    func syncAll() async {
        isLoading = true
        let connected = connections.filter { $0.status == .connected }
        await withTaskGroup(of: Void.self) { group in
            for conn in connected {
                group.addTask { await self.syncProvider(conn.provider) }
            }
        }
        generateInsights()
        generateStudyMatches()
        isLoading = false
        lastSync = Date()
    }

    func syncProvider(_ provider: WearableProvider) async {
        guard let idx = connections.firstIndex(where: { $0.provider == provider }) else { return }
        connections[idx].status = .syncing
        // Simulate API call to provider
        try? await Task.sleep(for: .milliseconds(500))
        let newPoints = generateDataForProvider(provider)
        dataPoints.append(contentsOf: newPoints)
        connections[idx].dataPointCount += newPoints.count
        connections[idx].lastSyncAt = Date()
        connections[idx].status = .connected
    }

    // MARK: - Aggregated Queries

    func latestValue(for metric: MetricType) -> Double? {
        dataPoints
            .filter { $0.metricType == metric }
            .sorted { $0.timestamp > $1.timestamp }
            .first?.value
    }

    func weeklyAverage(for metric: MetricType) -> Double? {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let points = dataPoints.filter { $0.metricType == metric && $0.timestamp >= weekAgo }
        guard !points.isEmpty else { return nil }
        return points.map(\.value).reduce(0, +) / Double(points.count)
    }

    func trend(for metric: MetricType) -> Double? {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let thisWeek = dataPoints.filter { $0.metricType == metric && $0.timestamp >= weekAgo }
        let lastWeek = dataPoints.filter { $0.metricType == metric && $0.timestamp >= twoWeeksAgo && $0.timestamp < weekAgo }
        guard !thisWeek.isEmpty, !lastWeek.isEmpty else { return nil }
        let thisAvg = thisWeek.map(\.value).reduce(0, +) / Double(thisWeek.count)
        let lastAvg = lastWeek.map(\.value).reduce(0, +) / Double(lastWeek.count)
        guard lastAvg > 0 else { return nil }
        return ((thisAvg - lastAvg) / lastAvg) * 100
    }

    var connectedProviderCount: Int { connections.filter { $0.status == .connected }.count }
    var totalDataPoints: Int { dataPoints.count }
    var unreadInsights: Int { insights.filter { !$0.isRead }.count }

    // MARK: - Insight Generation (AI-powered from Open Wearables automation)

    private func generateInsights() {
        var newInsights: [HealthInsight] = []

        // HRV anomaly detection
        if let hrv = latestValue(for: .hrv), let avg = weeklyAverage(for: .hrv) {
            if hrv < avg * 0.75 {
                newInsights.append(HealthInsight(
                    title: "HRV Below Normal",
                    description: "Your HRV (\(Int(hrv))ms) is 25%+ below your weekly average (\(Int(avg))ms). Consider lighter training today.",
                    category: .anomaly, severity: .warning,
                    relatedMetrics: [.hrv, .recoveryScore],
                    actionable: "Take a rest day or do light recovery work"
                ))
            }
        }

        // Sleep duration trend
        if let trend = trend(for: .sleepDuration), trend < -10 {
            newInsights.append(HealthInsight(
                title: "Sleep Duration Declining",
                description: "Your sleep duration has decreased \(String(format: "%.0f", abs(trend)))% this week compared to last week.",
                category: .trend, severity: .info,
                relatedMetrics: [.sleepDuration, .recoveryScore],
                actionable: "Try setting a consistent bedtime alarm"
            ))
        }

        // Heart rate + activity correlation
        if let rhr = latestValue(for: .heartRate), rhr > 75 {
            newInsights.append(HealthInsight(
                title: "Elevated Resting Heart Rate",
                description: "Your resting HR (\(Int(rhr)) bpm) is elevated. This may indicate stress, poor sleep, or illness.",
                category: .correlation, severity: .warning,
                relatedMetrics: [.heartRate, .stress, .sleepDuration],
                actionable: "Monitor for 2-3 days; consider resting if persistent"
            ))
        }

        // Step goal achievement
        if let steps = latestValue(for: .steps), steps >= 10000 {
            newInsights.append(HealthInsight(
                title: "Step Goal Reached!",
                description: "You hit \(Int(steps)) steps today. Keep up the momentum!",
                category: .achievement,
                relatedMetrics: [.steps, .activeCalories]
            ))
        }

        insights = newInsights + insights.suffix(20) // Keep last 20
    }

    // MARK: - Study Matching

    private func generateStudyMatches() {
        let connectedMetrics = Set(connections.filter { $0.status == .connected }.flatMap { $0.provider.supportedMetrics })

        studyMatches = [
            StudyMatch(studyTitle: "Impact of HRV-Guided Training on Athletic Performance",
                       sponsor: "Stanford Sports Medicine", compensation: "$500",
                       matchScore: connectedMetrics.contains(.hrv) ? 0.92 : 0.3,
                       requiredMetrics: [.hrv, .heartRate, .activeCalories],
                       durationWeeks: 12),
            StudyMatch(studyTitle: "Sleep Architecture and Cognitive Function",
                       sponsor: "Harvard Medical School", compensation: "$750",
                       matchScore: connectedMetrics.contains(.sleepStages) ? 0.88 : 0.2,
                       requiredMetrics: [.sleepDuration, .sleepStages, .hrv],
                       durationWeeks: 8),
            StudyMatch(studyTitle: "Continuous Glucose Monitoring in Non-Diabetic Adults",
                       sponsor: "Mayo Clinic", compensation: "$1,200",
                       matchScore: connectedMetrics.contains(.bloodGlucose) ? 0.95 : 0.1,
                       requiredMetrics: [.bloodGlucose, .activeCalories, .steps],
                       durationWeeks: 16),
            StudyMatch(studyTitle: "Wearable-Based Early Illness Detection",
                       sponsor: "Scripps Research", compensation: "$300",
                       matchScore: connectedMetrics.contains(.bodyTemperature) ? 0.85 : 0.4,
                       requiredMetrics: [.heartRate, .bodyTemperature, .spo2, .respiratoryRate],
                       durationWeeks: 24),
        ]
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        connections = WearableProvider.allCases.map { provider in
            var conn = WearableConnection(provider: provider)
            if [.appleHealth, .oura, .whoop].contains(provider) {
                conn.status = .connected
                conn.connectedAt = Calendar.current.date(byAdding: .day, value: -30, to: Date())
                conn.lastSyncAt = Calendar.current.date(byAdding: .hour, value: -2, to: Date())
                conn.dataPointCount = Int.random(in: 500...5000)
            }
            return conn
        }

        // Generate sample data for connected providers
        for conn in connections where conn.status == .connected {
            dataPoints.append(contentsOf: generateDataForProvider(conn.provider))
        }

        generateInsights()
        generateStudyMatches()
    }

    private func generateDataForProvider(_ provider: WearableProvider) -> [NormalizedDataPoint] {
        var points: [NormalizedDataPoint] = []
        let cal = Calendar.current

        for dayOffset in 0..<14 {
            let date = cal.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()

            for metric in provider.supportedMetrics {
                let value: Double
                switch metric {
                case .heartRate: value = Double.random(in: 52...72)
                case .hrv: value = Double.random(in: 35...75)
                case .steps: value = Double.random(in: 4000...14000)
                case .activeCalories: value = Double.random(in: 200...700)
                case .sleepDuration: value = Double.random(in: 5.5...8.5)
                case .sleepStages: continue
                case .vo2Max: value = Double.random(in: 40...55)
                case .spo2: value = Double.random(in: 95...99)
                case .respiratoryRate: value = Double.random(in: 13...17)
                case .bodyTemperature: value = Double.random(in: 97.5...98.8)
                case .bloodGlucose: value = Double.random(in: 80...120)
                case .strain: value = Double.random(in: 5...18)
                case .recoveryScore: value = Double.random(in: 40...95)
                case .readinessScore: value = Double.random(in: 50...95)
                case .bodyBattery: value = Double.random(in: 20...100)
                case .stress: value = Double.random(in: 15...65)
                }
                points.append(NormalizedDataPoint(metricType: metric, value: value, timestamp: date, source: provider))
            }
        }
        return points
    }
}
