import Foundation
import SwiftUI

@Observable
@MainActor
final class UserViewModel {
    var users: [AppUser] = []
    var auditLog: [AuditLogEntry] = []
    var currentUser: AppUser?
    var errorMessage: String?

    private let persistence = PersistenceService.shared

    func load() async {
        do {
            users = try await persistence.loadUsers()
            auditLog = try await persistence.loadAuditLog()

            // Create default owner if no users exist
            if users.isEmpty {
                let owner = AppUser(
                    name: "Owner",
                    email: "",
                    role: .owner
                )
                users.append(owner)
                currentUser = owner
                try await persistence.saveUsers(users)
            } else {
                currentUser = users.first { $0.role == .owner } ?? users.first
            }
        } catch {
            errorMessage = "Failed to load users: \(error.localizedDescription)"
        }
    }

    func inviteUser(name: String, email: String, role: AccessRole, entityAccess: [UUID]) async {
        guard let current = currentUser, current.role.canInvite else {
            errorMessage = "You do not have permission to invite users."
            return
        }

        let newUser = AppUser(
            name: name,
            email: email,
            role: role,
            entityAccess: entityAccess,
            invitedBy: current.id
        )
        users.append(newUser)

        await logAction(action: "invite_user", detail: "Invited \(name) (\(email)) as \(role.rawValue)")
        await saveAll()
    }

    func removeUser(_ user: AppUser) async {
        guard user.role != .owner else {
            errorMessage = "Cannot remove the owner."
            return
        }
        users.removeAll { $0.id == user.id }
        await logAction(action: "remove_user", detail: "Removed \(user.name) (\(user.email))")
        await saveAll()
    }

    func updateUserRole(_ user: AppUser, newRole: AccessRole) async {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else { return }
        users[index].role = newRole
        await logAction(action: "update_role", detail: "Changed \(user.name) role to \(newRole.rawValue)")
        await saveAll()
    }

    private func logAction(action: String, detail: String) async {
        guard let userID = currentUser?.id else { return }
        let entry = AuditLogEntry(userID: userID, action: action, detail: detail)
        auditLog.append(entry)
    }

    private func saveAll() async {
        do {
            try await persistence.saveUsers(users)
            try await persistence.saveAuditLog(auditLog)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
