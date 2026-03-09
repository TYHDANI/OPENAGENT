import Foundation

enum SubscriptionTier: String, Codable, CaseIterable, Identifiable {
    case free
    case guardian
    case estate
    case familyOffice

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .guardian: return "Guardian"
        case .estate: return "Estate"
        case .familyOffice: return "Family Office"
        }
    }

    var monthlyPrice: String {
        switch self {
        case .free: return "Free"
        case .guardian: return "$9.99/mo"
        case .estate: return "$29.99/mo"
        case .familyOffice: return "$99.99/mo"
        }
    }

    var yearlyPrice: String {
        switch self {
        case .free: return "Free"
        case .guardian: return "$99/yr"
        case .estate: return "$299/yr"
        case .familyOffice: return "$999/yr"
        }
    }

    var maxAccounts: Int {
        switch self {
        case .free: return 2
        case .guardian: return 10
        case .estate: return .max
        case .familyOffice: return .max
        }
    }

    var maxBeneficiaries: Int {
        switch self {
        case .free: return 1
        case .guardian: return 5
        case .estate: return .max
        case .familyOffice: return .max
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "2 connected accounts",
                "1 beneficiary",
                "Monthly check-in",
                "Basic dashboard"
            ]
        case .guardian:
            return [
                "10 connected accounts",
                "5 beneficiaries",
                "Weekly check-in",
                "Document vault",
                "Activity monitor"
            ]
        case .estate:
            return [
                "Unlimited accounts",
                "Unlimited beneficiaries",
                "Daily monitoring",
                "Trusted contacts",
                "Priority alerts",
                "Legal templates"
            ]
        case .familyOffice:
            return [
                "Everything in Estate",
                "Multi-user access",
                "Entity organization",
                "Attorney dashboard",
                "API access",
                "White-glove onboarding"
            ]
        }
    }

    var iconSystemName: String {
        switch self {
        case .free: return "shield"
        case .guardian: return "shield.checkered"
        case .estate: return "shield.lefthalf.filled"
        case .familyOffice: return "shield.fill"
        }
    }
}
