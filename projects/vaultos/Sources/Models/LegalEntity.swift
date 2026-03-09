import Foundation

enum EntityType: String, Codable, CaseIterable, Identifiable {
    case trust = "Trust"
    case llc = "LLC"
    case sCorp = "S-Corp"
    case individual = "Individual"
    case ira = "IRA"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .trust: "building.columns.fill"
        case .llc: "building.2.fill"
        case .sCorp: "briefcase.fill"
        case .individual: "person.fill"
        case .ira: "banknote.fill"
        }
    }
}

enum TaxTreatment: String, Codable, CaseIterable { case taxable, taxDeferred, taxExempt, passThrough }
enum CostBasisMethod: String, Codable, CaseIterable { case fifo = "FIFO", lifo = "LIFO", hifo = "HIFO", specificId = "Specific ID" }
enum FiscalYearEnd: String, Codable, CaseIterable { case dec31 = "Dec 31", mar31 = "Mar 31", jun30 = "Jun 30", sep30 = "Sep 30" }

struct LegalEntity: Identifiable, Codable {
    let id: UUID
    var name: String
    var entityType: EntityType
    var taxTreatment: TaxTreatment
    var costBasisMethod: CostBasisMethod
    var fiscalYearEnd: FiscalYearEnd
    var ein: String
    var notes: String
    var parentEntityID: UUID?
    var ownershipPercentage: Double?
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), name: String, entityType: EntityType, taxTreatment: TaxTreatment = .taxable,
         costBasisMethod: CostBasisMethod = .fifo, fiscalYearEnd: FiscalYearEnd = .dec31,
         ein: String = "", notes: String = "", parentEntityID: UUID? = nil, ownershipPercentage: Double? = nil) {
        self.id = id; self.name = name; self.entityType = entityType; self.taxTreatment = taxTreatment
        self.costBasisMethod = costBasisMethod; self.fiscalYearEnd = fiscalYearEnd; self.ein = ein
        self.notes = notes; self.parentEntityID = parentEntityID; self.ownershipPercentage = ownershipPercentage
        self.createdAt = Date(); self.updatedAt = Date()
    }
}
