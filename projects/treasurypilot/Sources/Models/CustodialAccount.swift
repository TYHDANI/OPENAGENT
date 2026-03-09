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
        case .coinbase: return "c.circle.fill"
        case .kraken: return "k.circle.fill"
        case .gemini: return "g.circle.fill"
        case .iTrustCapital: return "i.circle.fill"
        case .manual: return "pencil.circle.fill"
        }
    }
}

enum ConnectionStatus: String, Codable {
    case connected = "Connected"
    case disconnected = "Disconnected"
    case error = "Error"
    case pending = "Pending"
}

struct CustodialAccount: Identifiable, Codable, Hashable {
    let id: UUID
    var entityID: UUID // Which legal entity owns this account
    var custodian: Custodian
    var accountName: String
    var accountIdentifier: String // Last 4 digits or masked ID
    var connectionStatus: ConnectionStatus
    var lastSyncDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        entityID: UUID,
        custodian: Custodian,
        accountName: String,
        accountIdentifier: String = "",
        connectionStatus: ConnectionStatus = .pending,
        lastSyncDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.entityID = entityID
        self.custodian = custodian
        self.accountName = accountName
        self.accountIdentifier = accountIdentifier
        self.connectionStatus = connectionStatus
        self.lastSyncDate = lastSyncDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
