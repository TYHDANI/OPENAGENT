import Foundation

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "Free"
    case analyst = "Analyst"
    case professional = "Professional"

    var maxProducts: Int {
        switch self {
        case .free: return 10
        case .analyst: return 500
        case .professional: return 500
        }
    }

    var maxAlerts: Int {
        switch self {
        case .free: return 0
        case .analyst: return 10
        case .professional: return 100
        }
    }

    var hasRealTimeData: Bool {
        self != .free
    }

    var dataDelay: String {
        switch self {
        case .free: return "24h delayed"
        case .analyst, .professional: return "Real-time"
        }
    }

    var hasSMSAlerts: Bool {
        self == .professional
    }

    var hasResearchReports: Bool {
        self == .professional
    }

    var hasAPIAccess: Bool {
        self == .professional
    }

    var displayPrice: String {
        switch self {
        case .free: return "Free"
        case .analyst: return "$14.99/mo"
        case .professional: return "$49.99/mo"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "Top 10 yield products",
                "24-hour delayed scores",
                "Basic risk overview",
                "No alerts"
            ]
        case .analyst:
            return [
                "All 500+ yield products",
                "Real-time Sentinel Scores",
                "Up to 10 custom alerts",
                "Full risk factor breakdown",
                "Portfolio tracker",
                "Historical score charts"
            ]
        case .professional:
            return [
                "Everything in Analyst",
                "Up to 100 alerts",
                "SMS & email alerts",
                "Research reports",
                "API access (100 calls/day)",
                "Priority support"
            ]
        }
    }
}
