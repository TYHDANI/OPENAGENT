import Foundation

/// Represents a dental patient with HIPAA-compliant data handling
struct Patient: Codable, Identifiable, Equatable {
    let id: UUID
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var email: String?
    var phone: String?
    var address: Address?

    /// Medical history notes (encrypted at rest)
    var medicalHistory: String

    /// Dental insurance information
    var insurance: InsuranceInfo?

    /// Preferred financing options
    var preferredFinancing: [FinancingType]

    /// Last visit date
    var lastVisit: Date?

    /// Created and updated timestamps
    let createdAt: Date
    var updatedAt: Date

    /// HIPAA consent status
    var hipaaConsent: Bool
    var hipaaConsentDate: Date?

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        dateOfBirth: Date,
        email: String? = nil,
        phone: String? = nil,
        address: Address? = nil,
        medicalHistory: String = "",
        insurance: InsuranceInfo? = nil,
        preferredFinancing: [FinancingType] = [],
        lastVisit: Date? = nil,
        hipaaConsent: Bool = false,
        hipaaConsentDate: Date? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.email = email
        self.phone = phone
        self.address = address
        self.medicalHistory = medicalHistory
        self.insurance = insurance
        self.preferredFinancing = preferredFinancing
        self.lastVisit = lastVisit
        self.createdAt = Date()
        self.updatedAt = Date()
        self.hipaaConsent = hipaaConsent
        self.hipaaConsentDate = hipaaConsentDate
    }

    /// Full name for display
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    /// Age calculated from date of birth
    var age: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return components.year ?? 0
    }
}

/// Patient address information
struct Address: Codable, Equatable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var country: String = "USA"
}

/// Dental insurance information
struct InsuranceInfo: Codable, Equatable {
    var provider: String
    var policyNumber: String
    var groupNumber: String?
    var subscriberName: String
    var subscriberDateOfBirth: Date
    var annualMaximum: Decimal?
    var deductible: Decimal?
    var deductibleMet: Decimal?
}

/// Supported financing types
enum FinancingType: String, Codable, CaseIterable {
    case careCredit = "CareCredit"
    case sunbit = "Sunbit"
    case inHouse = "In-House Payment Plan"
    case insurance = "Insurance Only"
    case cash = "Cash/Credit Card"
}