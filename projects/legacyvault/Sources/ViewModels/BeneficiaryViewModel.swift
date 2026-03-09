import Foundation

@Observable
final class BeneficiaryViewModel {
    var beneficiaries: [Beneficiary] = []
    var isLoading = false
    var errorMessage: String?

    // Edit form state
    var editingBeneficiary: Beneficiary?
    var name = ""
    var email = ""
    var phone = ""
    var relationship: Relationship = .spouse
    var notes = ""

    private let persistence = PersistenceService.shared

    func loadBeneficiaries() async {
        isLoading = true
        defer { isLoading = false }

        do {
            beneficiaries = try await persistence.loadBeneficiaries()
        } catch {
            errorMessage = "Failed to load beneficiaries: \(error.localizedDescription)"
        }
    }

    func saveBeneficiary() async -> Bool {
        guard !name.isEmpty else {
            errorMessage = "Name is required"
            return false
        }
        guard !email.isEmpty else {
            errorMessage = "Email is required"
            return false
        }

        if let editing = editingBeneficiary,
           let index = beneficiaries.firstIndex(where: { $0.id == editing.id }) {
            beneficiaries[index].name = name
            beneficiaries[index].email = email
            beneficiaries[index].phone = phone
            beneficiaries[index].relationship = relationship
            beneficiaries[index].notes = notes
            beneficiaries[index].updatedAt = Date()
        } else {
            let beneficiary = Beneficiary(
                name: name,
                email: email,
                phone: phone,
                relationship: relationship,
                notes: notes
            )
            beneficiaries.append(beneficiary)
        }

        do {
            try await persistence.saveBeneficiaries(beneficiaries)
            resetForm()
            return true
        } catch {
            errorMessage = "Failed to save beneficiary"
            return false
        }
    }

    func deleteBeneficiary(_ beneficiary: Beneficiary) async {
        beneficiaries.removeAll { $0.id == beneficiary.id }

        do {
            try await persistence.saveBeneficiaries(beneficiaries)
        } catch {
            errorMessage = "Failed to delete beneficiary"
        }
    }

    func startEditing(_ beneficiary: Beneficiary) {
        editingBeneficiary = beneficiary
        name = beneficiary.name
        email = beneficiary.email
        phone = beneficiary.phone
        relationship = beneficiary.relationship
        notes = beneficiary.notes
    }

    func resetForm() {
        editingBeneficiary = nil
        name = ""
        email = ""
        phone = ""
        relationship = .spouse
        notes = ""
    }

    var totalAllocationPercentage: Double {
        beneficiaries.reduce(0) { total, beneficiary in
            total + beneficiary.allocations.reduce(0) { $0 + $1.percentage }
        }
    }
}
