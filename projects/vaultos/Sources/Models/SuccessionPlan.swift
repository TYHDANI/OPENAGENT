import Foundation

enum PlanStatus: String, Codable { case draft, active, executed, revoked }
enum TriggerType: String, Codable { case inactivity, deadManSwitch, manualRelease, courtOrder }

struct SuccessionPlan: Identifiable, Codable {
    let id: UUID
    var entityID: UUID
    var name: String
    var status: PlanStatus
    var triggerType: TriggerType
    var inactivityDays: Int
    var beneficiaries: [Beneficiary]
    var lastCheckinDate: Date
    var createdAt: Date
    var updatedAt: Date
    var notes: String

    init(id: UUID = UUID(), entityID: UUID, name: String, status: PlanStatus = .draft,
         triggerType: TriggerType = .inactivity, inactivityDays: Int = 90,
         beneficiaries: [Beneficiary] = [], notes: String = "") {
        self.id = id; self.entityID = entityID; self.name = name; self.status = status
        self.triggerType = triggerType; self.inactivityDays = inactivityDays
        self.beneficiaries = beneficiaries; self.lastCheckinDate = Date()
        self.createdAt = Date(); self.updatedAt = Date(); self.notes = notes
    }

    var totalAllocation: Double { beneficiaries.reduce(0) { $0 + $1.allocationPercent } }
    var isValid: Bool { abs(totalAllocation - 100.0) < 0.01 && !beneficiaries.isEmpty }
}
