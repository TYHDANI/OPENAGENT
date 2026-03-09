import Foundation

enum SubscriptionTier: String, Codable, CaseIterable {
    case free, pro, fleet

    var label: String {
        switch self {
        case .free: "Free"
        case .pro: "Pro"
        case .fleet: "Fleet"
        }
    }

    var monthlyPrice: String {
        switch self {
        case .free: "$0"
        case .pro: "$9.99"
        case .fleet: "$29.99"
        }
    }

    var productID: String {
        switch self {
        case .free: ""
        case .pro: "com.airscore.pro.monthly"
        case .fleet: "com.airscore.fleet.monthly"
        }
    }

    var maxProperties: Int {
        switch self { case .free: 1; case .pro: 3; case .fleet: 50 }
    }

    var maxRooms: Int {
        switch self { case .free: 3; case .pro: 15; case .fleet: 500 }
    }

    var hasFleetDashboard: Bool { self == .fleet }
    var hasTrends: Bool { self != .free }
    var hasAlerts: Bool { self != .free }
    var hasExport: Bool { self != .free }
}
