import Foundation

struct AppData: Codable {
    var entities: [LegalEntity]
    var accounts: [CustodialAccount]
    var transactions: [CryptoTransaction]
    var taxLots: [TaxLot]
    var washSaleAlerts: [WashSaleAlert]
    var users: [AppUser]
    var quarterlyEstimates: [QuarterlyEstimate]
    var auditLog: [AuditLogEntry]

    init() {
        self.entities = []
        self.accounts = []
        self.transactions = []
        self.taxLots = []
        self.washSaleAlerts = []
        self.users = []
        self.quarterlyEstimates = []
        self.auditLog = []
    }
}
