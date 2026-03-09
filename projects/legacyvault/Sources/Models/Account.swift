import Foundation

// MARK: - Platform Types

enum ExchangePlatform: String, Codable, CaseIterable, Identifiable {
    case coinbase
    case kraken
    case itrustcapital
    case gemini
    case blockchain
    case ethWallet
    case btcWallet
    case solWallet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coinbase: return "Coinbase"
        case .kraken: return "Kraken"
        case .itrustcapital: return "iTrustCapital"
        case .gemini: return "Gemini"
        case .blockchain: return "Blockchain.com"
        case .ethWallet: return "ETH Wallet"
        case .btcWallet: return "BTC Wallet"
        case .solWallet: return "SOL Wallet"
        }
    }

    var iconSystemName: String {
        switch self {
        case .coinbase, .kraken, .itrustcapital, .gemini, .blockchain:
            return "building.columns.fill"
        case .ethWallet, .btcWallet, .solWallet:
            return "wallet.pass.fill"
        }
    }

    var isExchange: Bool {
        switch self {
        case .ethWallet, .btcWallet, .solWallet: return false
        default: return true
        }
    }
}

enum AccountConnectionType: String, Codable {
    case apiKey
    case oauth
    case walletAddress
}

enum DormancyStatus: String, Codable {
    case active
    case warning
    case dormant
    case unknown
}

// MARK: - Account Model

struct Account: Codable, Identifiable, Equatable {
    let id: UUID
    var platform: ExchangePlatform
    var nickname: String
    var connectionType: AccountConnectionType
    var keychainReference: String
    var holdings: [Holding]
    var totalValueUSD: Double
    var lastActivityDate: Date?
    var lastSyncDate: Date?
    var dormancyStatus: DormancyStatus
    var dormancyDays: Int
    var isConnected: Bool
    var connectionError: String?

    init(
        id: UUID = UUID(),
        platform: ExchangePlatform,
        nickname: String = "",
        connectionType: AccountConnectionType,
        keychainReference: String = "",
        holdings: [Holding] = [],
        totalValueUSD: Double = 0,
        lastActivityDate: Date? = nil,
        lastSyncDate: Date? = nil,
        dormancyStatus: DormancyStatus = .unknown,
        dormancyDays: Int = 0,
        isConnected: Bool = false,
        connectionError: String? = nil
    ) {
        self.id = id
        self.platform = platform
        self.nickname = nickname.isEmpty ? platform.displayName : nickname
        self.connectionType = connectionType
        self.keychainReference = keychainReference
        self.holdings = holdings
        self.totalValueUSD = totalValueUSD
        self.lastActivityDate = lastActivityDate
        self.lastSyncDate = lastSyncDate
        self.dormancyStatus = dormancyStatus
        self.dormancyDays = dormancyDays
        self.isConnected = isConnected
        self.connectionError = connectionError
    }

    static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Holding

struct Holding: Codable, Identifiable {
    let id: UUID
    var symbol: String
    var name: String
    var quantity: Double
    var valueUSD: Double
    var priceUSD: Double
    var changePercent24h: Double

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        quantity: Double,
        valueUSD: Double,
        priceUSD: Double,
        changePercent24h: Double = 0
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.quantity = quantity
        self.valueUSD = valueUSD
        self.priceUSD = priceUSD
        self.changePercent24h = changePercent24h
    }
}
