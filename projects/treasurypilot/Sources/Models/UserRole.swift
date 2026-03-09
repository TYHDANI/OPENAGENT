import Foundation

typealias UserRole = AccessRole

enum AccessRole: String, Codable, CaseIterable, Identifiable {
    case owner = "Owner"
    case admin = "Admin"
    case readOnly = "Read-Only"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .admin: return "person.badge.key.fill"
        case .readOnly: return "eye.fill"
        }
    }

    var canEdit: Bool {
        switch self {
        case .owner, .admin: return true
        case .readOnly: return false
        }
    }

    var canDelete: Bool {
        self == .owner
    }

    var canInvite: Bool {
        self == .owner || self == .admin
    }
}

struct AppUser: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var email: String
    var role: AccessRole
    var entityAccess: [UUID]
    var invitedBy: UUID?
    var joinedAt: Date
    var lastActiveAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        role: AccessRole = .readOnly,
        entityAccess: [UUID] = [],
        invitedBy: UUID? = nil,
        joinedAt: Date = Date(),
        lastActiveAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.entityAccess = entityAccess
        self.invitedBy = invitedBy
        self.joinedAt = joinedAt
        self.lastActiveAt = lastActiveAt
    }
}

struct AuditLogEntry: Identifiable, Codable {
    let id: UUID
    var userID: UUID
    var action: String
    var detail: String
    var timestamp: Date

    init(
        id: UUID = UUID(),
        userID: UUID,
        action: String,
        detail: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.action = action
        self.detail = detail
        self.timestamp = timestamp
    }
}
