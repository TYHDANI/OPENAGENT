import Foundation

// MARK: - Entity Types

enum EntityType: String, Codable, CaseIterable, Identifiable {
    case trust = "Trust"
    case llc = "LLC"
    case sCorp = "S-Corp"
    case individual = "Individual"
    case ira = "IRA"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .trust: return "building.columns"
        case .llc: return "building.2"
        case .sCorp: return "building"
        case .individual: return "person"
        case .ira: return "banknote"
        }
    }
}

enum CostBasisMethod: String, Codable, CaseIterable, Identifiable {
    case fifo = "FIFO"
    case lifo = "LIFO"
    case specificId = "Specific ID"
    case hifo = "HIFO"

    var id: String { rawValue }
}

enum TaxTreatment: String, Codable, CaseIterable, Identifiable {
    case taxable = "Taxable"
    case taxDeferred = "Tax-Deferred"
    case taxExempt = "Tax-Exempt"
    case passThrough = "Pass-Through"

    var id: String { rawValue }
}

enum FiscalYearEnd: String, Codable, CaseIterable, Identifiable {
    case december = "December 31"
    case march = "March 31"
    case june = "June 30"
    case september = "September 30"

    var id: String { rawValue }

    var month: Int {
        switch self {
        case .december: return 12
        case .march: return 3
        case .june: return 6
        case .september: return 9
        }
    }
}

// MARK: - Legal Entity

struct LegalEntity: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var entityType: EntityType
    var taxTreatment: TaxTreatment
    var costBasisMethod: CostBasisMethod
    var fiscalYearEnd: FiscalYearEnd
    var ein: String // Employer Identification Number (or SSN for individual)
    var notes: String
    var parentEntityID: UUID? // For entity hierarchy (e.g., trust owns LLC)
    var ownershipPercentage: Double? // Percentage owned by parent
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        entityType: EntityType,
        taxTreatment: TaxTreatment = .taxable,
        costBasisMethod: CostBasisMethod = .fifo,
        fiscalYearEnd: FiscalYearEnd = .december,
        ein: String = "",
        notes: String = "",
        parentEntityID: UUID? = nil,
        ownershipPercentage: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.entityType = entityType
        self.taxTreatment = taxTreatment
        self.costBasisMethod = costBasisMethod
        self.fiscalYearEnd = fiscalYearEnd
        self.ein = ein
        self.notes = notes
        self.parentEntityID = parentEntityID
        self.ownershipPercentage = ownershipPercentage
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
