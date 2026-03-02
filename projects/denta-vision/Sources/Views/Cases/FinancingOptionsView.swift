import SwiftUI

struct FinancingOptionsView: View {
    @Environment(\.dismiss) private var dismiss

    let amount: Decimal
    let patient: Patient
    @Binding var selectedOptions: [FinancingOption]

    @State private var financingService = FinancingService()
    @State private var allOptions: [FinancingOption] = []
    @State private var selectedIds = Set<UUID>()
    @State private var isLoadingEligibility = false
    @State private var eligibility: FinancingEligibility? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Eligibility Status
            if let eligibility = eligibility {
                eligibilityView(eligibility)
            }

            // Options List
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(allOptions) { option in
                        FinancingOptionDetailCard(
                            option: option,
                            isSelected: selectedIds.contains(option.id),
                            isEligible: isEligible(for: option)
                        ) {
                            toggleOption(option)
                        }
                    }
                }
                .padding()
            }

            // Bottom Bar
            bottomBar
        }
        .navigationTitle("Financing Options")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    saveSelections()
                }
            }
        }
        .task {
            await loadOptions()
        }
    }

    // MARK: - Views

    private var headerView: some View {
        VStack(spacing: 8) {
            Text("Out of Pocket Amount")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(amount.formatted(.currency(code: "USD")))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Select financing options to present to patient")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private func eligibilityView(_ eligibility: FinancingEligibility) -> some View {
        GroupBox {
            HStack {
                Image(systemName: eligibility.isPreApproved ? "checkmark.shield.fill" : "xmark.shield")
                    .foregroundStyle(eligibility.isPreApproved ? .green : .red)

                VStack(alignment: .leading, spacing: 4) {
                    Text(eligibility.isPreApproved ? "Pre-Approved" : "Not Pre-Approved")
                        .font(.headline)

                    if eligibility.isPreApproved {
                        Text("Available credit: \(eligibility.availableCredit.formatted(.currency(code: "USD")))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal)
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(selectedIds.count) options selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if !selectedIds.isEmpty {
                    Button("Clear All") {
                        selectedIds.removeAll()
                    }
                    .font(.caption)
                }
            }

            if !isLoadingEligibility && eligibility == nil && patient.preferredFinancing.contains(.careCredit) {
                Button {
                    checkEligibility()
                } label: {
                    Label("Check CareCredit Eligibility", systemImage: "creditcard.and.123")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 5, y: -2)
    }

    // MARK: - Helpers

    private func toggleOption(_ option: FinancingOption) {
        if selectedIds.contains(option.id) {
            selectedIds.remove(option.id)
        } else {
            selectedIds.insert(option.id)
        }
    }

    private func isEligible(for option: FinancingOption) -> Bool {
        guard let eligibility = eligibility else { return true }

        if option.provider != .careCredit { return true }

        return eligibility.isPreApproved && amount <= eligibility.availableCredit
    }

    private func loadOptions() async {
        let options = financingService.generateFinancingOptions(for: amount)
        await MainActor.run {
            allOptions = options

            // Pre-select options that were already selected
            for option in selectedOptions {
                if let match = options.first(where: { $0.id == option.id }) {
                    selectedIds.insert(match.id)
                }
            }
        }
    }

    private func checkEligibility() {
        Task {
            isLoadingEligibility = true
            let result = await financingService.checkEligibility(for: patient)
            await MainActor.run {
                eligibility = result
                isLoadingEligibility = false
            }
        }
    }

    private func saveSelections() {
        selectedOptions = allOptions.filter { selectedIds.contains($0.id) }
        dismiss()
    }
}

// MARK: - Financing Option Detail Card

struct FinancingOptionDetailCard: View {
    let option: FinancingOption
    let isSelected: Bool
    let isEligible: Bool
    let action: () -> Void

    private var totalFinanceCharge: Decimal {
        option.totalCost - (option.totalCost / (1 + option.interestRate))
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.provider.rawValue)
                            .font(.headline)

                        if option.isPromotional {
                            Text("PROMOTIONAL OFFER")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        }
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    } else {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Main Details
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Monthly Payment")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(option.monthlyPayment.formatted(.currency(code: "USD")))
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Term")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(option.termMonths) months")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("APR")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(option.interestRate > 0 ? "\(NSDecimalNumber(decimal: option.interestRate * 100).intValue)%" : "0%")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(option.interestRate > 0 ? Color.primary : Color.green)
                        }
                    }

                    if option.downPayment > 0 {
                        HStack {
                            Text("Down Payment")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(option.downPayment.formatted(.currency(code: "USD")))
                                .fontWeight(.medium)
                        }
                    }

                    if option.interestRate > 0 {
                        HStack {
                            Text("Total Cost")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(option.totalCost.formatted(.currency(code: "USD")))
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Finance Charge")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(totalFinanceCharge.formatted(.currency(code: "USD")))
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                // Promo Details
                if let promoDetails = option.promoDetails {
                    Text(promoDetails)
                        .font(.caption)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemYellow).opacity(0.15))
                        .cornerRadius(8)
                }

                // Eligibility Warning
                if !isEligible {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Patient may not qualify for this option")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        FinancingOptionsView(
            amount: 3500,
            patient: Patient(
                firstName: "John",
                lastName: "Doe",
                dateOfBirth: Date(),
                preferredFinancing: [.careCredit]
            ),
            selectedOptions: .constant([])
        )
    }
}