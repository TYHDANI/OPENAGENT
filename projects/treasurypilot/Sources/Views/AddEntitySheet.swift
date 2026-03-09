import SwiftUI

struct AddEntitySheet: View {
    @Environment(EntityViewModel.self) private var entityVM
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var entityType: EntityType = .llc
    @State private var taxTreatment: TaxTreatment = .taxable
    @State private var costBasisMethod: CostBasisMethod = .fifo
    @State private var fiscalYearEnd: FiscalYearEnd = .december
    @State private var ein = ""
    @State private var notes = ""
    @State private var parentEntityID: UUID?
    @State private var ownershipPercentage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Entity Name", text: $name)
                        .accessibilityLabel("Entity name")
                    Picker("Entity Type", selection: $entityType) {
                        ForEach(EntityType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    TextField("EIN / SSN", text: $ein)
                        .accessibilityLabel("Employer Identification Number or Social Security Number")
                }

                Section("Tax Configuration") {
                    Picker("Tax Treatment", selection: $taxTreatment) {
                        ForEach(TaxTreatment.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    Picker("Cost Basis Method", selection: $costBasisMethod) {
                        ForEach(CostBasisMethod.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    Picker("Fiscal Year End", selection: $fiscalYearEnd) {
                        ForEach(FiscalYearEnd.allCases) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                }

                Section("Ownership Hierarchy (Optional)") {
                    Picker("Parent Entity", selection: $parentEntityID) {
                        Text("None").tag(nil as UUID?)
                        ForEach(entityVM.entities) { entity in
                            Text(entity.name).tag(entity.id as UUID?)
                        }
                    }
                    if parentEntityID != nil {
                        TextField("Ownership %", text: $ownershipPercentage)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Ownership percentage")
                    }
                }

                Section("Notes") {
                    TextField("Additional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Entity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let entity = LegalEntity(
                                name: name,
                                entityType: entityType,
                                taxTreatment: taxTreatment,
                                costBasisMethod: costBasisMethod,
                                fiscalYearEnd: fiscalYearEnd,
                                ein: ein,
                                notes: notes,
                                parentEntityID: parentEntityID,
                                ownershipPercentage: Double(ownershipPercentage)
                            )
                            await entityVM.addEntity(entity)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
