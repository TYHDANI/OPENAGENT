import Foundation

enum Custodian: String, Codable, CaseIterable, Identifiable {
    case coinbase = "Coinbase"
    case kraken = "Kraken"
    case gemini = "Gemini"
    case iTrustCapital = "iTrustCapital"
    case manual = "Manual Entry"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .coinbase: "c.circle.fill"
        case .kraken: "k.circle.fill"
        case .gemini: "g.circle.fill"
        case .iTrustCapital: "i.circle.fill"
        case .manual: "pencil.circle.fill"
        }
    }
}

enum ConnectionStatus: String, Codable { case connected, disconnected, error, pending }

struct Holding: Identifiable, Codable {
    let id: UUID
    var symbol: String
    var quantity: Double
    var usdValue: Double
    var priceChange24h: Double
    init(id: UUID = UUID(), symbol: String, quantity: Double, usdValue: Double, priceChange24h: Double = 0) {
        self.id = id; self.symbol = symbol; self.quantity = quantity; self.usdValue = usdValue; self.priceChange24h = priceChange24h
    }
}

struct CustodialAccount: Identifiable, Codable {
    let id: UUID
    var entityID: UUID
    var custodian: Custodian
    var accountName: String
    var accountIdentifier: String
    var connectionStatus: ConnectionStatus
    var holdings: [Holding]
    var lastSyncDate: Date?
    var createdAt: Date

    init(id: UUID = UUID(), entityID: UUID, custodian: Custodian, accountName: String,
         accountIdentifier: String = "", connectionStatus: ConnectionStatus = .connected,
         holdings: [Holding] = [], lastSyncDate: Date? = Date()) {
        self.id = id; self.entityID = entityID; self.custodian = custodian; self.accountName = accountName
        self.accountIdentifier = accountIdentifier; self.connectionStatus = connectionStatus
        self.holdings = holdings; self.lastSyncDate = lastSyncDate; self.createdAt = Date()
    }

    var totalValue: Double { holdings.reduce(0) { $0 + $1.usdValue } }
}
