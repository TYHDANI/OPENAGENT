import Foundation

struct WashSaleAlert: Identifiable, Codable {
    let id: UUID
    var saleTransactionID: UUID
    var buyTransactionID: UUID
    var saleEntityID: UUID
    var buyEntityID: UUID
    var asset: String
    var saleDate: Date
    var buyDate: Date
    var disallowedLoss: Double
    var daysApart: Int
    var isResolved: Bool
    var notes: String

    init(id: UUID = UUID(), saleTransactionID: UUID, buyTransactionID: UUID, saleEntityID: UUID,
         buyEntityID: UUID, asset: String, saleDate: Date, buyDate: Date, disallowedLoss: Double,
         daysApart: Int, isResolved: Bool = false, notes: String = "") {
        self.id = id; self.saleTransactionID = saleTransactionID; self.buyTransactionID = buyTransactionID
        self.saleEntityID = saleEntityID; self.buyEntityID = buyEntityID; self.asset = asset
        self.saleDate = saleDate; self.buyDate = buyDate; self.disallowedLoss = disallowedLoss
        self.daysApart = daysApart; self.isResolved = isResolved; self.notes = notes
    }
}
