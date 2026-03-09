import Foundation

enum BeneficiaryRelation: String, Codable, CaseIterable {
    case spouse, child, sibling, parent, trust, charity, other
    var label: String { rawValue.capitalized }
}

struct Beneficiary: Identifiable, Codable {
    let id: UUID
    var entityID: UUID
    var name: String
    var relation: BeneficiaryRelation
    var allocationPercent: Double
    var walletAddress: String
    var email: String
    var isVerified: Bool
    var notes: String

    init(id: UUID = UUID(), entityID: UUID, name: String, relation: BeneficiaryRelation,
         allocationPercent: Double, walletAddress: String = "", email: String = "",
         isVerified: Bool = false, notes: String = "") {
        self.id = id; self.entityID = entityID; self.name = name; self.relation = relation
        self.allocationPercent = allocationPercent; self.walletAddress = walletAddress
        self.email = email; self.isVerified = isVerified; self.notes = notes
    }
}
