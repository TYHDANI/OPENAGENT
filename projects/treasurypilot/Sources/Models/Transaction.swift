import Foundation

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case buy = "Buy"
    case sell = "Sell"
    case transfer = "Transfer"
    case income = "Income"
    case fee = "Fee"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .buy: return "arrow.down.circle.fill"
        case .sell: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .income: return "plus.circle.fill"
        case .fee: return "minus.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .buy: return "green"
        case .sell: return "red"
        case .transfer: return "blue"
        case .income: return "orange"
        case .fee: return "gray"
        }
    }
}

struct CryptoTransaction: Identifiable, Codable, Hashable {
    let id: UUID
    var accountID: UUID
    var entityID: UUID
    var transactionType: TransactionType
    var asset: String // e.g., "BTC", "ETH"
    var quantity: Double
    var pricePerUnit: Double // USD price at time of transaction
    var totalValue: Double // quantity * pricePerUnit
    var fee: Double
    var date: Date
    var externalID: String? // ID from the exchange
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        accountID: UUID,
        entityID: UUID,
        transactionType: TransactionType,
        asset: String,
        quantity: Double,
        pricePerUnit: Double,
        fee: Double = 0,
        date: Date = Date(),
        externalID: String? = nil,
        notes: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.accountID = accountID
        self.entityID = entityID
        self.transactionType = transactionType
        self.asset = asset
        self.quantity = quantity
        self.pricePerUnit = pricePerUnit
        self.totalValue = quantity * pricePerUnit
        self.fee = fee
        self.date = date
        self.externalID = externalID
        self.notes = notes
        self.createdAt = createdAt
    }
}
