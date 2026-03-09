import Foundation

enum HoldingPeriod: String, Codable {
    case shortTerm = "Short-Term"
    case longTerm = "Long-Term"
}

struct TaxLot: Identifiable, Codable, Hashable {
    let id: UUID
    var entityID: UUID
    var accountID: UUID
    var asset: String
    var quantity: Double // Remaining quantity (decreases as lots are sold)
    var originalQuantity: Double
    var costBasisPerUnit: Double
    var totalCostBasis: Double
    var acquisitionDate: Date
    var acquisitionTransactionID: UUID
    var disposalDate: Date? // Set when lot is fully or partially sold
    var disposalTransactionID: UUID?
    var proceeds: Double? // Sale price if disposed
    var gainLoss: Double? // proceeds - totalCostBasis (for disposed portion)
    var holdingPeriod: HoldingPeriod
    var isDisposed: Bool

    init(
        id: UUID = UUID(),
        entityID: UUID,
        accountID: UUID,
        asset: String,
        quantity: Double,
        costBasisPerUnit: Double,
        acquisitionDate: Date,
        acquisitionTransactionID: UUID
    ) {
        self.id = id
        self.entityID = entityID
        self.accountID = accountID
        self.asset = asset
        self.quantity = quantity
        self.originalQuantity = quantity
        self.costBasisPerUnit = costBasisPerUnit
        self.totalCostBasis = quantity * costBasisPerUnit
        self.acquisitionDate = acquisitionDate
        self.acquisitionTransactionID = acquisitionTransactionID
        self.disposalDate = nil
        self.disposalTransactionID = nil
        self.proceeds = nil
        self.gainLoss = nil
        self.isDisposed = false

        // Holding period: > 1 year = long-term
        let oneYearLater = Calendar.current.date(byAdding: .year, value: 1, to: acquisitionDate) ?? acquisitionDate
        self.holdingPeriod = Date() >= oneYearLater ? .longTerm : .shortTerm
    }

    var currentValue: Double {
        quantity * costBasisPerUnit // Placeholder — real value needs live pricing
    }

    var unrealizedGainLoss: Double {
        0 // Requires live price feed; computed in ViewModel
    }
}
