import Foundation
import SwiftUI

enum TransactionType: String, Codable, CaseIterable {
    case buy, sell, transfer, income, fee
    var color: Color {
        switch self {
        case .buy: .green
        case .sell: .red
        case .transfer: .blue
        case .income: .orange
        case .fee: .gray
        }
    }
    var icon: String {
        switch self {
        case .buy: "arrow.down.circle.fill"
        case .sell: "arrow.up.circle.fill"
        case .transfer: "arrow.left.arrow.right.circle.fill"
        case .income: "dollarsign.circle.fill"
        case .fee: "minus.circle.fill"
        }
    }
}

struct CryptoTransaction: Identifiable, Codable {
    let id: UUID
    var accountID: UUID
    var entityID: UUID
    var transactionType: TransactionType
    var asset: String
    var quantity: Double
    var pricePerUnit: Double
    var totalValue: Double
    var fee: Double
    var date: Date
    var notes: String

    init(id: UUID = UUID(), accountID: UUID, entityID: UUID, transactionType: TransactionType,
         asset: String, quantity: Double, pricePerUnit: Double, fee: Double = 0, date: Date = Date(), notes: String = "") {
        self.id = id; self.accountID = accountID; self.entityID = entityID
        self.transactionType = transactionType; self.asset = asset; self.quantity = quantity
        self.pricePerUnit = pricePerUnit; self.totalValue = quantity * pricePerUnit
        self.fee = fee; self.date = date; self.notes = notes
    }
}
