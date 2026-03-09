import Foundation

enum SubscriptionTier: String, Codable, CaseIterable {
    case free, pro, family

    var label: String {
        switch self {
        case .free: "Free"
        case .pro: "Pro"
        case .family: "Family"
        }
    }

    var monthlyPrice: String {
        switch self {
        case .free: "$0"
        case .pro: "$14.99"
        case .family: "$24.99"
        }
    }

    var productID: String {
        switch self {
        case .free: ""
        case .pro: "com.vaultos.pro.monthly"
        case .family: "com.vaultos.family.monthly"
        }
    }

    var maxEntities: Int {
        switch self { case .free: 1; case .pro: 5; case .family: 10 }
    }

    var maxBeneficiaries: Int {
        switch self { case .free: 1; case .pro: 10; case .family: 25 }
    }

    var hasWashSaleDetection: Bool { self != .free }
    var hasForm8949Export: Bool { self != .free }
    var hasSuccessionPlanning: Bool { self != .free }
    var hasRiskScanner: Bool { true }
}
