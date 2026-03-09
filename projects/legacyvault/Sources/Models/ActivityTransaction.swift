import Foundation

enum TransactionType: String, Codable {
    case buy
    case sell
    case transfer
    case deposit
    case withdrawal
    case stake
    case unstake
    case unknown
}

enum AnomalyLevel: String, Codable {
    case none
    case low
    case medium
    case high
}

struct ActivityTransaction: Codable, Identifiable {
    let id: UUID
    var accountID: UUID
    var platform: ExchangePlatform
    var type: TransactionType
    var asset: String
    var amount: Double
    var valueUSD: Double
    var date: Date
    var anomalyLevel: AnomalyLevel
    var anomalyReason: String?

    init(
        id: UUID = UUID(),
        accountID: UUID,
        platform: ExchangePlatform,
        type: TransactionType,
        asset: String,
        amount: Double,
        valueUSD: Double,
        date: Date = Date(),
        anomalyLevel: AnomalyLevel = .none,
        anomalyReason: String? = nil
    ) {
        self.id = id
        self.accountID = accountID
        self.platform = platform
        self.type = type
        self.asset = asset
        self.amount = amount
        self.valueUSD = valueUSD
        self.date = date
        self.anomalyLevel = anomalyLevel
        self.anomalyReason = anomalyReason
    }
}
