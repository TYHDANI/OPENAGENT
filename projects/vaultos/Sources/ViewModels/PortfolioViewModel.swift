import Foundation

@Observable
final class PortfolioViewModel {
    var entities: [LegalEntity] = []
    var accounts: [CustodialAccount] = []
    var selectedEntityID: UUID?

    var selectedEntity: LegalEntity? {
        entities.first { $0.id == selectedEntityID }
    }

    var filteredAccounts: [CustodialAccount] {
        guard let eid = selectedEntityID else { return accounts }
        return accounts.filter { $0.entityID == eid }
    }

    var totalPortfolioValue: Double {
        filteredAccounts.reduce(0) { $0 + $1.totalValue }
    }

    var holdingsByAsset: [(asset: String, quantity: Double, value: Double)] {
        var map: [String: (qty: Double, val: Double)] = [:]
        for acct in filteredAccounts {
            for h in acct.holdings {
                let existing = map[h.asset, default: (0, 0)]
                map[h.asset] = (existing.qty + h.quantity, existing.val + h.totalValue)
            }
        }
        return map.map { (asset: $0.key, quantity: $0.value.qty, value: $0.value.val) }
            .sorted { $0.value > $1.value }
    }

    func load(from persistence: PersistenceService) {
        entities = persistence.entities
        accounts = persistence.accounts
        if selectedEntityID == nil { selectedEntityID = entities.first?.id }
    }
}
