import Foundation

@Observable
final class LegacyViewModel {
    var plans: [SuccessionPlan] = []
    var beneficiaries: [Beneficiary] = []
    var selectedEntityID: UUID?

    var filteredPlans: [SuccessionPlan] {
        guard let eid = selectedEntityID else { return plans }
        return plans.filter { $0.entityID == eid }
    }

    var filteredBeneficiaries: [Beneficiary] {
        guard let eid = selectedEntityID else { return beneficiaries }
        return beneficiaries.filter { $0.entityID == eid }
    }

    var nextCheckinDate: Date? {
        plans.filter { $0.status == .active }
            .map { Calendar.current.date(byAdding: .day, value: $0.inactivityDays, to: $0.lastCheckinDate) ?? Date() }
            .min()
    }

    func load(from persistence: PersistenceService) {
        plans = persistence.plans
        beneficiaries = persistence.beneficiaries
    }

    func checkin(plan: SuccessionPlan) {
        guard let idx = plans.firstIndex(where: { $0.id == plan.id }) else { return }
        plans[idx].lastCheckinDate = Date()
        plans[idx].updatedAt = Date()
    }

    func addPlan(entityID: UUID, name: String) {
        let plan = SuccessionPlan(entityID: entityID, name: name)
        plans.append(plan)
    }

    func addBeneficiary(entityID: UUID, name: String, relation: BeneficiaryRelation, allocation: Double) {
        let b = Beneficiary(entityID: entityID, name: name, relation: relation, allocationPercent: allocation)
        beneficiaries.append(b)
    }
}
