import Foundation

@Observable
final class SuccessionPlanViewModel {
    var plans: [SuccessionPlan] = []
    var currentPlan: SuccessionPlan?
    var isLoading = false
    var errorMessage: String?

    // Builder state
    var builderStep = 0
    var planName = "My Succession Plan"
    var selectedBeneficiaryIDs: Set<UUID> = []
    var dormancyDays = 90
    var checkInInterval: CheckInInterval = .monthly
    var enableDormancy = true
    var enableDeadManSwitch = true
    var trustedContacts: [TrustedContact] = []

    private let persistence = PersistenceService.shared

    var totalBuilderSteps: Int { 4 }

    func loadPlans() async {
        isLoading = true
        defer { isLoading = false }

        do {
            plans = try await persistence.loadPlans()
            currentPlan = plans.first(where: { $0.status == .active }) ?? plans.first
        } catch {
            errorMessage = "Failed to load plans: \(error.localizedDescription)"
        }
    }

    func createPlan() async -> Bool {
        var triggers: [TriggerCondition] = []

        if enableDormancy {
            triggers.append(TriggerCondition(
                type: .dormancy,
                dormancyDays: dormancyDays,
                isEnabled: true
            ))
        }

        if enableDeadManSwitch {
            triggers.append(TriggerCondition(
                type: .deadManSwitch,
                checkInInterval: checkInInterval,
                isEnabled: true
            ))
        }

        if !trustedContacts.isEmpty {
            triggers.append(TriggerCondition(
                type: .trustedContactVote,
                trustedContactThreshold: max(1, trustedContacts.count - 1),
                isEnabled: true
            ))
        }

        let nextCheckIn = Calendar.current.date(
            byAdding: .day,
            value: checkInInterval.days,
            to: Date()
        )

        let plan = SuccessionPlan(
            name: planName,
            status: .active,
            beneficiaryIDs: Array(selectedBeneficiaryIDs),
            triggerConditions: triggers,
            trustedContacts: trustedContacts,
            lastCheckInDate: Date(),
            nextCheckInDate: nextCheckIn
        )

        plans.append(plan)
        currentPlan = plan

        do {
            try await persistence.savePlans(plans)
            resetBuilder()
            return true
        } catch {
            errorMessage = "Failed to save plan"
            plans.removeLast()
            return false
        }
    }

    func activatePlan(_ plan: SuccessionPlan) async {
        guard let index = plans.firstIndex(where: { $0.id == plan.id }) else { return }

        // Deactivate all other plans
        for i in plans.indices {
            if plans[i].status == .active {
                plans[i].status = .paused
            }
        }

        plans[index].status = .active
        plans[index].updatedAt = Date()
        currentPlan = plans[index]

        do {
            try await persistence.savePlans(plans)
        } catch {
            errorMessage = "Failed to activate plan"
        }
    }

    func deletePlan(_ plan: SuccessionPlan) async {
        plans.removeAll { $0.id == plan.id }
        if currentPlan?.id == plan.id {
            currentPlan = plans.first(where: { $0.status == .active }) ?? plans.first
        }

        do {
            try await persistence.savePlans(plans)
        } catch {
            errorMessage = "Failed to delete plan"
        }
    }

    func performCheckIn() async {
        guard var plan = currentPlan,
              let index = plans.firstIndex(where: { $0.id == plan.id }) else { return }

        plan.lastCheckInDate = Date()
        plan.nextCheckInDate = Calendar.current.date(
            byAdding: .day,
            value: plan.triggerConditions
                .first(where: { $0.type == .deadManSwitch })?.checkInInterval.days ?? 30,
            to: Date()
        )
        plan.updatedAt = Date()

        plans[index] = plan
        currentPlan = plan

        do {
            try await persistence.savePlans(plans)
            try await persistence.saveLastCheckIn(Date())
        } catch {
            errorMessage = "Failed to save check-in"
        }
    }

    private func resetBuilder() {
        builderStep = 0
        planName = "My Succession Plan"
        selectedBeneficiaryIDs = []
        dormancyDays = 90
        checkInInterval = .monthly
        enableDormancy = true
        enableDeadManSwitch = true
        trustedContacts = []
    }
}
