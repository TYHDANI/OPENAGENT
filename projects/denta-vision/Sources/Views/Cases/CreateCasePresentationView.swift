import SwiftUI

struct CreateCasePresentationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataManager.self) private var dataManager

    let patient: Patient
    let fromChart: DentalChart?

    @State private var caseTitle = ""
    @State private var treatments: [Treatment] = []
    @State private var insuranceEstimate: Decimal = 0
    @State private var showingAddTreatment = false
    @State private var showingFinancingOptions = false
    @State private var selectedFinancingOptions: [FinancingOption] = []
    @State private var notes = ""

    @State private var financingService = FinancingService()

    init(patient: Patient, fromChart: DentalChart? = nil) {
        self.patient = patient
        self.fromChart = fromChart
    }

    private var totalCost: Decimal {
        treatments.reduce(0) { $0 + $1.estimatedCost }
    }

    private var outOfPocketCost: Decimal {
        max(0, totalCost - insuranceEstimate)
    }

    var body: some View {
        Form {
            // Case Information
            Section("Case Information") {
                TextField("Case Title", text: $caseTitle)

                HStack {
                    Text("Patient")
                    Spacer()
                    Text(patient.fullName)
                        .foregroundStyle(.secondary)
                }
            }

            // Treatments
            treatmentsSection

            // Financial Summary
            financialSection

            // Financing Options
            if outOfPocketCost > 0 {
                financingSection
            }

            // Notes
            Section("Notes") {
                TextField("Additional notes...", text: $notes, axis: .vertical)
                    .lineLimit(3...5)
            }
        }
        .navigationTitle("New Treatment Case")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Create") {
                    createCase()
                }
                .fontWeight(.medium)
                .disabled(!canCreate)
            }
        }
        .sheet(isPresented: $showingAddTreatment) {
            NavigationStack {
                AddTreatmentView { treatment in
                    treatments.append(treatment)
                }
            }
        }
        .sheet(isPresented: $showingFinancingOptions) {
            NavigationStack {
                FinancingOptionsView(
                    amount: outOfPocketCost,
                    patient: patient,
                    selectedOptions: $selectedFinancingOptions
                )
            }
        }
        .onAppear {
            setupFromChart()
        }
    }

    // MARK: - Sections

    private var treatmentsSection: some View {
        Section {
            ForEach(treatments) { treatment in
                TreatmentRowView(treatment: treatment) {
                    removeTreatment(treatment)
                }
            }

            Button {
                showingAddTreatment = true
            } label: {
                Label("Add Treatment", systemImage: "plus.circle")
            }
        } header: {
            Text("Treatments")
        } footer: {
            if !treatments.isEmpty {
                Text("Swipe left to remove treatments")
                    .font(.caption)
            }
        }
    }

    private var financialSection: some View {
        Section("Financial Summary") {
            HStack {
                Text("Total Cost")
                Spacer()
                Text(totalCost.formatted(.currency(code: "USD")))
                    .fontWeight(.medium)
            }

            HStack {
                Text("Insurance Estimate")
                Spacer()
                TextField("Amount", value: $insuranceEstimate, format: .currency(code: "USD"))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
            }

            HStack {
                Text("Out of Pocket")
                    .fontWeight(.medium)
                Spacer()
                Text(outOfPocketCost.formatted(.currency(code: "USD")))
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
        }
    }

    private var financingSection: some View {
        Section("Financing Options") {
            if selectedFinancingOptions.isEmpty {
                Button {
                    showingFinancingOptions = true
                } label: {
                    Label("Generate Financing Options", systemImage: "creditcard")
                }
            } else {
                ForEach(selectedFinancingOptions) { option in
                    FinancingOptionRowView(option: option)
                }

                Button {
                    showingFinancingOptions = true
                } label: {
                    Text("Modify Options")
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Helpers

    private var canCreate: Bool {
        !caseTitle.isEmpty && !treatments.isEmpty
    }

    private func setupFromChart() {
        guard let chart = fromChart else { return }

        // Generate case title
        caseTitle = "Treatment Plan - \(Date().formatted(date: .abbreviated, time: .omitted))"

        // Extract treatments from chart conditions
        let conditionsByTooth = Dictionary(grouping: chart.teeth.filter { !$0.conditions.isEmpty }) { $0 }

        // Suggest treatments based on conditions
        for (_, teeth) in conditionsByTooth {
            for tooth in teeth {
                if tooth.conditions.contains(.cavity) || tooth.conditions.contains(.decay) {
                    treatments.append(Treatment(
                        type: .filling,
                        toothNumbers: [tooth.number],
                        description: "Composite filling for tooth #\(tooth.number)",
                        estimatedCost: 250
                    ))
                }

                if tooth.conditions.contains(.abscess) || tooth.conditions.contains(.rootCanal) {
                    treatments.append(Treatment(
                        type: .rootCanal,
                        toothNumbers: [tooth.number],
                        description: "Root canal treatment for tooth #\(tooth.number)",
                        estimatedCost: 1200
                    ))
                }

                if tooth.conditions.contains(.crown) {
                    treatments.append(Treatment(
                        type: .crown,
                        toothNumbers: [tooth.number],
                        description: "Porcelain crown for tooth #\(tooth.number)",
                        estimatedCost: 1500
                    ))
                }
            }
        }

        // Auto-generate financing options if treatments exist
        if !treatments.isEmpty {
            Task {
                let options = financingService.generateFinancingOptions(for: totalCost)
                await MainActor.run {
                    selectedFinancingOptions = Array(options.prefix(3))
                }
            }
        }
    }

    private func removeTreatment(_ treatment: Treatment) {
        treatments.removeAll { $0.id == treatment.id }
    }

    private func createCase() {
        var newCase = CasePresentation(
            patientId: patient.id,
            title: caseTitle,
            treatments: treatments,
            totalCost: totalCost,
            insuranceEstimate: insuranceEstimate,
            financingOptions: selectedFinancingOptions,
            status: .draft,
            notes: notes
        )

        newCase.generateFinancingOptions()
        dataManager.createCasePresentation(newCase)
        dismiss()
    }
}

// MARK: - Treatment Row View

struct TreatmentRowView: View {
    let treatment: Treatment
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(treatment.type.rawValue)
                    .font(.headline)

                Spacer()

                Text(treatment.estimatedCost.formatted(.currency(code: "USD")))
                    .fontWeight(.medium)
            }

            if !treatment.toothNumbers.isEmpty {
                Text("Teeth: \(treatment.toothNumbers.map { "#\($0)" }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !treatment.description.isEmpty {
                Text(treatment.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Treatment View

struct AddTreatmentView: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (Treatment) -> Void

    @State private var treatmentType: TreatmentType = .filling
    @State private var selectedTeeth: Set<Int> = []
    @State private var description = ""
    @State private var estimatedCost: Decimal = 0
    @State private var priority: TreatmentPriority = .moderate

    var body: some View {
        Form {
            Section("Treatment Type") {
                Picker("Type", selection: $treatmentType) {
                    ForEach(TreatmentType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }

            Section("Teeth") {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(1...32, id: \.self) { number in
                            ToothSelectionButton(
                                number: number,
                                isSelected: selectedTeeth.contains(number)
                            ) {
                                toggleTooth(number)
                            }
                        }
                    }
                }
                .frame(height: 120)
            }

            Section("Details") {
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(2...4)

                HStack {
                    Text("Estimated Cost")
                    Spacer()
                    TextField("Amount", value: $estimatedCost, format: .currency(code: "USD"))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }

                Picker("Priority", selection: $priority) {
                    ForEach(TreatmentPriority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
            }
        }
        .navigationTitle("Add Treatment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    addTreatment()
                }
                .disabled(estimatedCost <= 0)
            }
        }
        .onAppear {
            setDefaultCost()
        }
        .onChange(of: treatmentType) { _, _ in
            setDefaultCost()
        }
    }

    private func toggleTooth(_ number: Int) {
        if selectedTeeth.contains(number) {
            selectedTeeth.remove(number)
        } else {
            selectedTeeth.insert(number)
        }
    }

    private func setDefaultCost() {
        // Set default costs based on treatment type
        switch treatmentType {
        case .filling: estimatedCost = 250
        case .crown: estimatedCost = 1500
        case .rootCanal: estimatedCost = 1200
        case .extraction: estimatedCost = 200
        case .implant: estimatedCost = 3500
        case .bridge: estimatedCost = 3000
        case .veneer: estimatedCost = 1300
        case .cleaning: estimatedCost = 150
        case .deepCleaning: estimatedCost = 300
        case .orthodontics: estimatedCost = 5000
        case .whitening: estimatedCost = 400
        case .other: estimatedCost = 0
        }
    }

    private func addTreatment() {
        let treatment = Treatment(
            type: treatmentType,
            toothNumbers: Array(selectedTeeth).sorted(),
            description: description,
            estimatedCost: estimatedCost,
            priority: priority
        )

        onAdd(treatment)
        dismiss()
    }
}

// MARK: - Financing Option Row View

struct FinancingOptionRowView: View {
    let option: FinancingOption

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(option.provider.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if option.isPromotional {
                        Text("PROMO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(3)
                    }
                }

                Text("\(option.monthlyPayment.formatted(.currency(code: "USD")))/mo × \(option.termMonths) months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if option.interestRate > 0 {
                Text("\(NSDecimalNumber(decimal: option.interestRate * 100).intValue)% APR")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("0% APR")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Tooth Selection Button

struct ToothSelectionButton: View {
    let number: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.caption)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CreateCasePresentationView(
            patient: Patient(
                firstName: "John",
                lastName: "Doe",
                dateOfBirth: Date()
            )
        )
        .environment(DataManager())
    }
}