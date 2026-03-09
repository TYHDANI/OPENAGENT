import Foundation

enum SubscriptionTier: String, Codable, Comparable, CaseIterable {
    case free = "Free"
    case professional = "Professional"
    case familyOffice = "Family Office"
    case enterprise = "Enterprise"

    var entityLimit: Int? {
        switch self {
        case .free: 1
        case .professional: 3
        case .familyOffice: 10
        case .enterprise: nil
        }
    }

    var accountLimit: Int? {
        switch self {
        case .free: 2
        case .professional: 10
        case .familyOffice: nil
        case .enterprise: nil
        }
    }

    var userSeatLimit: Int? {
        switch self {
        case .free: 1
        case .professional: 2
        case .familyOffice: 5
        case .enterprise: nil
        }
    }

    var includesWashSaleDetection: Bool {
        switch self {
        case .free, .professional: false
        case .familyOffice, .enterprise: true
        }
    }

    var includesForm8949Export: Bool {
        switch self {
        case .free: false
        case .professional, .familyOffice, .enterprise: true
        }
    }

    var includesPDFReports: Bool {
        switch self {
        case .free: false
        case .professional, .familyOffice, .enterprise: true
        }
    }

    var monthlyPrice: Decimal {
        switch self {
        case .free: 0
        case .professional: 29.99
        case .familyOffice: 79.99
        case .enterprise: 199.99
        }
    }

    var displayFeatures: [String] {
        switch self {
        case .free:
            ["1 entity", "2 accounts", "Basic tax tracking"]
        case .professional:
            ["3 entities", "10 accounts", "Quarterly estimates", "PDF reports", "Form 8949 CSV"]
        case .familyOffice:
            ["10 entities", "Unlimited accounts", "Wash-sale detection", "5 user seats", "Priority support"]
        case .enterprise:
            ["Unlimited entities", "Unlimited accounts", "Unlimited users", "API access", "White-glove onboarding"]
        }
    }

    private var sortOrder: Int {
        switch self {
        case .free: 0
        case .professional: 1
        case .familyOffice: 2
        case .enterprise: 3
        }
    }

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    // MARK: - Compatibility

    var maxEntities: Int { entityLimit ?? .max }
    var maxAccounts: Int { accountLimit ?? .max }
    var canExport: Bool { includesForm8949Export }
    var hasWashSaleDetection: Bool { includesWashSaleDetection }
}
