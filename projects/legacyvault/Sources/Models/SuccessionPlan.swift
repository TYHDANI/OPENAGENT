import Foundation

enum PlanStatus: String, Codable {
    case draft
    case active
    case triggered
    case executed
    case paused
}

enum TriggerType: String, Codable, CaseIterable, Identifiable {
    case dormancy
    case deadManSwitch
    case trustedContactVote

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dormancy: return "Dormancy Detection"
        case .deadManSwitch: return "Dead-Man Switch"
        case .trustedContactVote: return "Trusted Contact Vote"
        }
    }

    var description: String {
        switch self {
        case .dormancy:
            return "Triggers when no activity is detected across accounts for the configured period"
        case .deadManSwitch:
            return "Triggers when you miss check-in confirmations after the escalation sequence"
        case .trustedContactVote:
            return "Triggers when a threshold of trusted contacts confirm incapacity"
        }
    }
}

enum CheckInInterval: String, Codable, CaseIterable, Identifiable {
    case weekly
    case biweekly
    case monthly
    case quarterly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        }
    }

    var days: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .quarterly: return 90
        }
    }
}

struct TriggerCondition: Codable, Identifiable {
    let id: UUID
    var type: TriggerType
    var dormancyDays: Int
    var checkInInterval: CheckInInterval
    var trustedContactThreshold: Int
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        type: TriggerType,
        dormancyDays: Int = 90,
        checkInInterval: CheckInInterval = .monthly,
        trustedContactThreshold: Int = 2,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.type = type
        self.dormancyDays = dormancyDays
        self.checkInInterval = checkInInterval
        self.trustedContactThreshold = trustedContactThreshold
        self.isEnabled = isEnabled
    }
}

struct TrustedContact: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String
    var phone: String
    var hasConfirmed: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        email: String = "",
        phone: String = "",
        hasConfirmed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.hasConfirmed = hasConfirmed
    }
}

struct SuccessionPlan: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var status: PlanStatus
    var beneficiaryIDs: [UUID]
    var triggerConditions: [TriggerCondition]
    var trustedContacts: [TrustedContact]
    var lastCheckInDate: Date?
    var nextCheckInDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "My Succession Plan",
        status: PlanStatus = .draft,
        beneficiaryIDs: [UUID] = [],
        triggerConditions: [TriggerCondition] = [],
        trustedContacts: [TrustedContact] = [],
        lastCheckInDate: Date? = nil,
        nextCheckInDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.beneficiaryIDs = beneficiaryIDs
        self.triggerConditions = triggerConditions
        self.trustedContacts = trustedContacts
        self.lastCheckInDate = lastCheckInDate
        self.nextCheckInDate = nextCheckInDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: SuccessionPlan, rhs: SuccessionPlan) -> Bool {
        lhs.id == rhs.id
    }
}
