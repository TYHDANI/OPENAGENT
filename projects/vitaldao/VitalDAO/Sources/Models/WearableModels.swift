import Foundation
import SwiftUI

// MARK: - Wearable Provider (inspired by Open Wearables unified API)

enum WearableProvider: String, Codable, CaseIterable, Identifiable {
    case appleHealth = "Apple Health"
    case oura = "Oura"
    case whoop = "Whoop"
    case garmin = "Garmin"
    case fitbit = "Fitbit"
    case polar = "Polar"
    case suunto = "Suunto"
    case samsung = "Samsung Health"
    case googleHealth = "Google Health Connect"
    case dexcom = "Dexcom CGM"
    case eightSleep = "Eight Sleep"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .appleHealth: "heart.fill"
        case .oura: "circle.dotted.and.circle"
        case .whoop: "waveform.path.ecg"
        case .garmin: "figure.run"
        case .fitbit: "figure.walk"
        case .polar: "heart.text.square"
        case .suunto: "location.north.circle"
        case .samsung: "stethoscope"
        case .googleHealth: "cross.case"
        case .dexcom: "drop.fill"
        case .eightSleep: "bed.double.fill"
        }
    }

    var color: Color {
        switch self {
        case .appleHealth: VDColors.heartRed
        case .oura: VDColors.accentPurple
        case .whoop: .yellow
        case .garmin: VDColors.accentTeal
        case .fitbit: VDColors.sleepBlue
        case .polar: VDColors.heartRed
        case .suunto: .orange
        case .samsung: VDColors.sleepBlue
        case .googleHealth: VDColors.successGreen
        case .dexcom: VDColors.glucoseOrange
        case .eightSleep: VDColors.sleepBlue
        }
    }

    var authType: AuthType {
        switch self {
        case .appleHealth, .samsung, .googleHealth: .sdk
        default: .oauth
        }
    }

    var supportedMetrics: [MetricType] {
        switch self {
        case .appleHealth:
            return MetricType.allCases
        case .oura:
            return [.heartRate, .hrv, .sleepDuration, .sleepStages, .steps, .readinessScore, .bodyTemperature, .spo2, .respiratoryRate]
        case .whoop:
            return [.heartRate, .hrv, .sleepDuration, .sleepStages, .strain, .recoveryScore, .respiratoryRate, .spo2]
        case .garmin:
            return [.heartRate, .steps, .activeCalories, .sleepDuration, .vo2Max, .bodyBattery, .stress, .spo2]
        case .fitbit:
            return [.heartRate, .steps, .sleepDuration, .sleepStages, .activeCalories, .spo2]
        case .polar:
            return [.heartRate, .hrv, .sleepDuration, .vo2Max, .steps]
        case .suunto:
            return [.heartRate, .steps, .activeCalories, .vo2Max]
        case .samsung:
            return [.heartRate, .steps, .sleepDuration, .activeCalories, .spo2, .stress]
        case .googleHealth:
            return [.heartRate, .steps, .sleepDuration, .activeCalories]
        case .dexcom:
            return [.bloodGlucose]
        case .eightSleep:
            return [.sleepDuration, .sleepStages, .heartRate, .hrv, .bodyTemperature, .respiratoryRate]
        }
    }

    enum AuthType: String, Codable {
        case oauth  // Cloud-based OAuth 2.0 flow
        case sdk    // On-device SDK integration
    }
}

// MARK: - Wearable Connection

struct WearableConnection: Identifiable, Codable {
    let id: UUID
    var provider: WearableProvider
    var status: ConnectionStatus
    var connectedAt: Date?
    var lastSyncAt: Date?
    var dataPointCount: Int
    var accessToken: String?
    var refreshToken: String?

    enum ConnectionStatus: String, Codable {
        case connected, disconnected, syncing, error, expired

        var label: String { rawValue.capitalized }
        var color: Color {
            switch self {
            case .connected: VDColors.successGreen
            case .disconnected: VDColors.textTertiary
            case .syncing: VDColors.sleepBlue
            case .error: VDColors.heartRed
            case .expired: VDColors.warningAmber
            }
        }
    }

    init(id: UUID = UUID(), provider: WearableProvider, status: ConnectionStatus = .disconnected) {
        self.id = id; self.provider = provider; self.status = status
        self.connectedAt = nil; self.lastSyncAt = nil; self.dataPointCount = 0
        self.accessToken = nil; self.refreshToken = nil
    }
}

// MARK: - Normalized Metric Types (unified across providers)

enum MetricType: String, Codable, CaseIterable, Identifiable {
    case heartRate = "Heart Rate"
    case hrv = "HRV"
    case steps = "Steps"
    case activeCalories = "Active Calories"
    case sleepDuration = "Sleep Duration"
    case sleepStages = "Sleep Stages"
    case vo2Max = "VO2 Max"
    case spo2 = "SpO2"
    case respiratoryRate = "Respiratory Rate"
    case bodyTemperature = "Body Temperature"
    case bloodGlucose = "Blood Glucose"
    case strain = "Strain"
    case recoveryScore = "Recovery Score"
    case readinessScore = "Readiness"
    case bodyBattery = "Body Battery"
    case stress = "Stress"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .heartRate: "heart.fill"
        case .hrv: "waveform.path.ecg"
        case .steps: "figure.walk"
        case .activeCalories: "flame.fill"
        case .sleepDuration: "moon.fill"
        case .sleepStages: "bed.double.fill"
        case .vo2Max: "lungs.fill"
        case .spo2: "drop.fill"
        case .respiratoryRate: "wind"
        case .bodyTemperature: "thermometer.medium"
        case .bloodGlucose: "drop.triangle.fill"
        case .strain: "bolt.heart.fill"
        case .recoveryScore: "arrow.counterclockwise.heart"
        case .readinessScore: "gauge.open.with.lines.needle.33percent"
        case .bodyBattery: "battery.75percent"
        case .stress: "brain.head.profile"
        }
    }

    var unit: String {
        switch self {
        case .heartRate: "bpm"
        case .hrv: "ms"
        case .steps: "steps"
        case .activeCalories: "kcal"
        case .sleepDuration: "hours"
        case .sleepStages: ""
        case .vo2Max: "ml/kg/min"
        case .spo2: "%"
        case .respiratoryRate: "brpm"
        case .bodyTemperature: "°F"
        case .bloodGlucose: "mg/dL"
        case .strain, .recoveryScore, .readinessScore, .bodyBattery, .stress: ""
        }
    }

    var color: Color {
        switch self {
        case .heartRate: VDColors.heartRed
        case .hrv: VDColors.accentPurple
        case .steps: VDColors.accentTeal
        case .activeCalories: .orange
        case .sleepDuration, .sleepStages: VDColors.sleepBlue
        case .vo2Max: VDColors.successGreen
        case .spo2: VDColors.oxygenCyan
        case .respiratoryRate: VDColors.sleepBlue
        case .bodyTemperature: VDColors.warningAmber
        case .bloodGlucose: VDColors.glucoseOrange
        case .strain: VDColors.heartRed
        case .recoveryScore: VDColors.successGreen
        case .readinessScore: VDColors.accentTeal
        case .bodyBattery: VDColors.successGreen
        case .stress: VDColors.warningAmber
        }
    }
}

// MARK: - Normalized Data Point (time-series entry)

struct NormalizedDataPoint: Identifiable, Codable, Sendable {
    let id: UUID
    var metricType: MetricType
    var value: Double
    var timestamp: Date
    var source: WearableProvider
    var confidence: Double  // 0-1

    init(id: UUID = UUID(), metricType: MetricType, value: Double,
         timestamp: Date = Date(), source: WearableProvider, confidence: Double = 1.0) {
        self.id = id; self.metricType = metricType; self.value = value
        self.timestamp = timestamp; self.source = source; self.confidence = confidence
    }
}

// MARK: - Health Insight (AI-generated from Open Wearables automation pattern)

struct HealthInsight: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var category: InsightCategory
    var severity: InsightSeverity
    var relatedMetrics: [MetricType]
    var actionable: String
    var generatedAt: Date
    var isRead: Bool

    enum InsightCategory: String, Codable, CaseIterable {
        case anomaly = "Anomaly"
        case trend = "Trend"
        case correlation = "Correlation"
        case recommendation = "Recommendation"
        case achievement = "Achievement"
    }

    enum InsightSeverity: String, Codable {
        case info, warning, alert
        var color: Color {
            switch self {
            case .info: VDColors.sleepBlue
            case .warning: VDColors.warningAmber
            case .alert: VDColors.heartRed
            }
        }
    }

    init(id: UUID = UUID(), title: String, description: String,
         category: InsightCategory, severity: InsightSeverity = .info,
         relatedMetrics: [MetricType] = [], actionable: String = "") {
        self.id = id; self.title = title; self.description = description
        self.category = category; self.severity = severity
        self.relatedMetrics = relatedMetrics; self.actionable = actionable
        self.generatedAt = Date(); self.isRead = false
    }
}

// MARK: - Study Match (from VitalDAO's research matching)

struct StudyMatch: Identifiable, Codable {
    let id: UUID
    var studyTitle: String
    var sponsor: String
    var compensation: String
    var matchScore: Double  // 0-1
    var requiredMetrics: [MetricType]
    var durationWeeks: Int
    var status: MatchStatus

    enum MatchStatus: String, Codable {
        case available, applied, enrolled, completed, declined
    }

    init(id: UUID = UUID(), studyTitle: String, sponsor: String,
         compensation: String, matchScore: Double, requiredMetrics: [MetricType],
         durationWeeks: Int, status: MatchStatus = .available) {
        self.id = id; self.studyTitle = studyTitle; self.sponsor = sponsor
        self.compensation = compensation; self.matchScore = matchScore
        self.requiredMetrics = requiredMetrics; self.durationWeeks = durationWeeks
        self.status = status
    }
}
