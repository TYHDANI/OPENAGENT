import Foundation

actor PersistenceService {
    static let shared = PersistenceService()

    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func fileURL(for filename: String) -> URL {
        documentsDirectory.appendingPathComponent(filename)
    }

    // MARK: - Accounts

    func saveAccounts(_ accounts: [Account]) throws {
        let data = try JSONEncoder.app.encode(accounts)
        try data.write(to: fileURL(for: "accounts.json"), options: .atomic)
    }

    func loadAccounts() throws -> [Account] {
        let url = fileURL(for: "accounts.json")
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder.app.decode([Account].self, from: data)
    }

    // MARK: - Beneficiaries

    func saveBeneficiaries(_ beneficiaries: [Beneficiary]) throws {
        let data = try JSONEncoder.app.encode(beneficiaries)
        try data.write(to: fileURL(for: "beneficiaries.json"), options: .atomic)
    }

    func loadBeneficiaries() throws -> [Beneficiary] {
        let url = fileURL(for: "beneficiaries.json")
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder.app.decode([Beneficiary].self, from: data)
    }

    // MARK: - Succession Plans

    func savePlans(_ plans: [SuccessionPlan]) throws {
        let data = try JSONEncoder.app.encode(plans)
        try data.write(to: fileURL(for: "succession_plans.json"), options: .atomic)
    }

    func loadPlans() throws -> [SuccessionPlan] {
        let url = fileURL(for: "succession_plans.json")
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder.app.decode([SuccessionPlan].self, from: data)
    }

    // MARK: - Transactions

    func saveTransactions(_ transactions: [ActivityTransaction]) throws {
        let data = try JSONEncoder.app.encode(transactions)
        try data.write(to: fileURL(for: "transactions.json"), options: .atomic)
    }

    func loadTransactions() throws -> [ActivityTransaction] {
        let url = fileURL(for: "transactions.json")
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try JSONDecoder.app.decode([ActivityTransaction].self, from: data)
    }

    // MARK: - Dead-Man Switch State

    func saveLastCheckIn(_ date: Date) throws {
        let data = try JSONEncoder.app.encode(date)
        try data.write(to: fileURL(for: "last_checkin.json"), options: .atomic)
    }

    func loadLastCheckIn() throws -> Date? {
        let url = fileURL(for: "last_checkin.json")
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder.app.decode(Date.self, from: data)
    }
}

// MARK: - Coder Extensions

extension JSONEncoder {
    static let app: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

extension JSONDecoder {
    static let app: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
