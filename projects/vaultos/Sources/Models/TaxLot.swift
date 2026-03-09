import Foundation

enum HoldingPeriod: String, Codable { case shortTerm = "Short-Term", longTerm = "Long-Term" }

struct TaxLot: Identifiable, Codable {
    let id: UUID
    var entityID: UUID
    var accountID: UUID
    var asset: String
    var quantity: Double
    var originalQuantity: Double
    var costBasisPerUnit: Double
    var totalCostBasis: Double
    var acquisitionDate: Date
    var disposalDate: Date?
    var proceeds: Double?
    var gainLoss: Double?
    var isDisposed: Bool

    var holdingPeriod: HoldingPeriod {
        let endDate = disposalDate ?? Date()
        let days = Calendar.current.dateComponents([.day], from: acquisitionDate, to: endDate).day ?? 0
        return days > 365 ? .longTerm : .shortTerm
    }

    init(id: UUID = UUID(), entityID: UUID, accountID: UUID, asset: String, quantity: Double,
         costBasisPerUnit: Double, acquisitionDate: Date = Date()) {
        self.id = id; self.entityID = entityID; self.accountID = accountID; self.asset = asset
        self.quantity = quantity; self.originalQuantity = quantity; self.costBasisPerUnit = costBasisPerUnit
        self.totalCostBasis = quantity * costBasisPerUnit; self.acquisitionDate = acquisitionDate
        self.disposalDate = nil; self.proceeds = nil; self.gainLoss = nil; self.isDisposed = false
    }
}
