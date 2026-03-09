import Foundation

enum VerificationStatus: String, Codable {
    case unverified
    case pending
    case verified
}

enum Relationship: String, Codable, CaseIterable, Identifiable {
    case spouse
    case child
    case parent
    case sibling
    case partner
    case attorney
    case trustee
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spouse: return "Spouse"
        case .child: return "Child"
        case .parent: return "Parent"
        case .sibling: return "Sibling"
        case .partner: return "Partner"
        case .attorney: return "Attorney"
        case .trustee: return "Trustee"
        case .other: return "Other"
        }
    }
}

struct BeneficiaryAllocation: Codable, Identifiable {
    let id: UUID
    var accountID: UUID?
    var assetSymbol: String?
    var percentage: Double

    init(
        id: UUID = UUID(),
        accountID: UUID? = nil,
        assetSymbol: String? = nil,
        percentage: Double = 0
    ) {
        self.id = id
        self.accountID = accountID
        self.assetSymbol = assetSymbol
        self.percentage = percentage
    }
}

struct Beneficiary: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var email: String
    var phone: String
    var relationship: Relationship
    var verificationStatus: VerificationStatus
    var allocations: [BeneficiaryAllocation]
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        email: String = "",
        phone: String = "",
        relationship: Relationship = .other,
        verificationStatus: VerificationStatus = .unverified,
        allocations: [BeneficiaryAllocation] = [],
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.relationship = relationship
        self.verificationStatus = verificationStatus
        self.allocations = allocations
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: Beneficiary, rhs: Beneficiary) -> Bool {
        lhs.id == rhs.id
    }
}
