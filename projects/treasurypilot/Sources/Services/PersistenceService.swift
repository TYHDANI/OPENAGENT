import Foundation

actor PersistenceService {
    static let shared = PersistenceService()

    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func fileURL(for filename: String) -> URL {
        documentsURL.appendingPathComponent(filename)
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Generic CRUD

    func load<T: Codable>(_ type: [T].Type, from filename: String) throws -> [T] {
        let url = fileURL(for: filename)
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try decoder.decode([T].self, from: data)
    }

    func save<T: Codable>(_ items: [T], to filename: String) throws {
        let url = fileURL(for: filename)
        let data = try encoder.encode(items)
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Convenience accessors

    func loadEntities() throws -> [LegalEntity] {
        try load([LegalEntity].self, from: "entities.json")
    }

    func saveEntities(_ entities: [LegalEntity]) throws {
        try save(entities, to: "entities.json")
    }

    func loadAccounts() throws -> [CustodialAccount] {
        try load([CustodialAccount].self, from: "accounts.json")
    }

    func saveAccounts(_ accounts: [CustodialAccount]) throws {
        try save(accounts, to: "accounts.json")
    }

    func loadTransactions() throws -> [CryptoTransaction] {
        try load([CryptoTransaction].self, from: "transactions.json")
    }

    func saveTransactions(_ transactions: [CryptoTransaction]) throws {
        try save(transactions, to: "transactions.json")
    }

    func loadTaxLots() throws -> [TaxLot] {
        try load([TaxLot].self, from: "taxlots.json")
    }

    func saveTaxLots(_ lots: [TaxLot]) throws {
        try save(lots, to: "taxlots.json")
    }

    func loadWashSaleAlerts() throws -> [WashSaleAlert] {
        try load([WashSaleAlert].self, from: "washsale_alerts.json")
    }

    func saveWashSaleAlerts(_ alerts: [WashSaleAlert]) throws {
        try save(alerts, to: "washsale_alerts.json")
    }

    func loadQuarterlyEstimates() throws -> [QuarterlyEstimate] {
        try load([QuarterlyEstimate].self, from: "quarterly_estimates.json")
    }

    func saveQuarterlyEstimates(_ estimates: [QuarterlyEstimate]) throws {
        try save(estimates, to: "quarterly_estimates.json")
    }

    func loadUsers() throws -> [AppUser] {
        try load([AppUser].self, from: "users.json")
    }

    func saveUsers(_ users: [AppUser]) throws {
        try save(users, to: "users.json")
    }

    func loadAuditLog() throws -> [AuditLogEntry] {
        try load([AuditLogEntry].self, from: "audit_log.json")
    }

    func saveAuditLog(_ entries: [AuditLogEntry]) throws {
        try save(entries, to: "audit_log.json")
    }
}
