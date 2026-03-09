import SwiftUI

struct LegacyView: View {
    @State private var vm = LegacyViewModel()
    @Environment(PersistenceService.self) private var persistence
    @State private var showAddPlan = false
    @State private var showAddBeneficiary = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Check-in banner
                    if let next = vm.nextCheckinDate {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(AppColors.accent)
                            VStack(alignment: .leading) {
                                Text("Next Check-in").font(.caption).foregroundStyle(.secondary)
                                Text(next, style: .relative).font(.subheadline.bold())
                            }
                            Spacer()
                            Button("Check In") {
                                if let plan = vm.plans.first(where: { $0.status == .active }) {
                                    vm.checkin(plan: plan)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColors.accent)
                        }
                        .padding()
                        .goldGlassCard()
                    }

                    // Succession plans
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Succession Plans").font(.headline)
                            Spacer()
                            Button { showAddPlan = true } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AppColors.accent)
                            }
                        }

                        if vm.filteredPlans.isEmpty {
                            ContentUnavailableView("No Plans", systemImage: "doc.text.magnifyingglass",
                                                   description: Text("Create a succession plan to protect your assets"))
                        }

                        ForEach(vm.filteredPlans) { plan in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(plan.name).font(.subheadline.bold())
                                    Spacer()
                                    Text(plan.status.rawValue.capitalized)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(plan.status == .active ? AppColors.success.opacity(0.2) : Color.gray.opacity(0.2))
                                        .foregroundStyle(plan.status == .active ? AppColors.success : .secondary)
                                        .clipShape(Capsule())
                                }
                                HStack {
                                    Label(plan.triggerType.rawValue.capitalized, systemImage: "bell")
                                    Spacer()
                                    Text("\(plan.beneficiaries.count) beneficiaries")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)

                                if plan.isValid {
                                    Label("Allocations valid (100%)", systemImage: "checkmark.circle")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.success)
                                } else {
                                    Label("Allocations: \(String(format: "%.0f%%", plan.totalAllocation))", systemImage: "exclamationmark.triangle")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.danger)
                                }
                            }
                            .padding()
                            .glassCard()
                        }
                    }

                    // Beneficiaries
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Beneficiaries").font(.headline)
                            Spacer()
                            Button { showAddBeneficiary = true } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AppColors.accent)
                            }
                        }

                        ForEach(vm.filteredBeneficiaries) { b in
                            HStack {
                                Image(systemName: "person.circle")
                                    .font(.title2)
                                    .foregroundStyle(AppColors.accent)
                                VStack(alignment: .leading) {
                                    Text(b.name).font(.subheadline.bold())
                                    Text(b.relation.label).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(String(format: "%.0f%%", b.allocationPercent))
                                    .font(.headline)
                                    .foregroundStyle(AppColors.accent)
                            }
                            .padding()
                            .glassCard()
                        }
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Legacy")
            .onAppear { vm.load(from: persistence) }
            .sheet(isPresented: $showAddPlan) { AddPlanSheet(vm: vm, entities: persistence.entities) }
            .sheet(isPresented: $showAddBeneficiary) { AddBeneficiarySheet(vm: vm, entities: persistence.entities) }
        }
    }
}

struct AddPlanSheet: View {
    @Bindable var vm: LegacyViewModel
    let entities: [LegalEntity]
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedEntityID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Plan Name", text: $name)
                Picker("Entity", selection: $selectedEntityID) {
                    ForEach(entities) { e in Text(e.name).tag(Optional(e.id)) }
                }
            }
            .navigationTitle("New Plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if let eid = selectedEntityID {
                            vm.addPlan(entityID: eid, name: name)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || selectedEntityID == nil)
                }
            }
        }
    }
}

struct AddBeneficiarySheet: View {
    @Bindable var vm: LegacyViewModel
    let entities: [LegalEntity]
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var relation: BeneficiaryRelation = .spouse
    @State private var allocation = 50.0
    @State private var selectedEntityID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Picker("Relation", selection: $relation) {
                    ForEach(BeneficiaryRelation.allCases, id: \.self) { r in Text(r.label).tag(r) }
                }
                Picker("Entity", selection: $selectedEntityID) {
                    ForEach(entities) { e in Text(e.name).tag(Optional(e.id)) }
                }
                Slider(value: $allocation, in: 1...100, step: 1) {
                    Text("Allocation: \(String(format: "%.0f%%", allocation))")
                }
            }
            .navigationTitle("New Beneficiary")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let eid = selectedEntityID {
                            vm.addBeneficiary(entityID: eid, name: name, relation: relation, allocation: allocation)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || selectedEntityID == nil)
                }
            }
        }
    }
}
