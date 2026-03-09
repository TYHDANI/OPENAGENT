import Foundation
import SwiftUI

@Observable
@MainActor
final class EntityViewModel {
    var entities: [LegalEntity] = []
    var accounts: [CustodialAccount] = []
    var errorMessage: String?
    var isLoading = false

    private let persistence = PersistenceService.shared

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            entities = try await persistence.loadEntities()
            accounts = try await persistence.loadAccounts()
        } catch {
            errorMessage = "Failed to load entities: \(error.localizedDescription)"
        }
    }

    func addEntity(_ entity: LegalEntity) async {
        entities.append(entity)
        await saveEntities()
    }

    func updateEntity(_ entity: LegalEntity) async {
        if let index = entities.firstIndex(where: { $0.id == entity.id }) {
            var updated = entity
            updated.updatedAt = Date()
            entities[index] = updated
            await saveEntities()
        }
    }

    func deleteEntity(_ entity: LegalEntity) async {
        entities.removeAll { $0.id == entity.id }
        accounts.removeAll { $0.entityID == entity.id }
        await saveEntities()
        await saveAccounts()
    }

    func addAccount(_ account: CustodialAccount) async {
        accounts.append(account)
        await saveAccounts()
    }

    func deleteAccount(_ account: CustodialAccount) async {
        accounts.removeAll { $0.id == account.id }
        await saveAccounts()
    }

    func accounts(for entityID: UUID) -> [CustodialAccount] {
        accounts.filter { $0.entityID == entityID }
    }

    func childEntities(of entityID: UUID) -> [LegalEntity] {
        entities.filter { $0.parentEntityID == entityID }
    }

    func parentEntity(of entity: LegalEntity) -> LegalEntity? {
        guard let parentID = entity.parentEntityID else { return nil }
        return entities.first { $0.id == parentID }
    }

    private func saveEntities() async {
        do {
            try await persistence.saveEntities(entities)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func saveAccounts() async {
        do {
            try await persistence.saveAccounts(accounts)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
