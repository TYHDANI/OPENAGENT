import Foundation

@Observable
final class PersistenceService {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var entities: [LegalEntity] = []
    var accounts: [CustodialAccount] = []
    var transactions: [CryptoTransaction] = []
    var taxLots: [TaxLot] = []
    var products: [YieldProduct] = []
    var alerts: [AlertItem] = []
    var beneficiaries: [Beneficiary] = []
    var plans: [SuccessionPlan] = []

    init() { load() }

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func save() {
        write(entities, to: "entities.json")
        write(accounts, to: "accounts.json")
        write(transactions, to: "transactions.json")
        write(taxLots, to: "taxLots.json")
        write(products, to: "products.json")
        write(alerts, to: "alerts.json")
        write(beneficiaries, to: "beneficiaries.json")
        write(plans, to: "plans.json")
    }

    func load() {
        entities = read("entities.json") ?? SampleData.entities
        accounts = read("accounts.json") ?? SampleData.accounts
        transactions = read("transactions.json") ?? []
        taxLots = read("taxLots.json") ?? []
        products = read("products.json") ?? SampleData.products
        alerts = read("alerts.json") ?? []
        beneficiaries = read("beneficiaries.json") ?? []
        plans = read("plans.json") ?? []
    }

    private func write<T: Encodable>(_ value: T, to filename: String) {
        let url = documentsURL.appendingPathComponent(filename)
        try? encoder.encode(value).write(to: url)
    }

    private func read<T: Decodable>(_ filename: String) -> T? {
        let url = documentsURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
}
