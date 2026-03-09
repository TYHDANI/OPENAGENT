import SwiftUI

struct SuccessionPlanBuilderView: View {
    @State private var planVM = SuccessionPlanViewModel()
    @State private var beneficiaryVM = BeneficiaryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator
                    .padding()

                TabView(selection: $planVM.builderStep) {
                    nameStep.tag(0)
                    beneficiaryStep.tag(1)
                    triggersStep.tag(2)
                    reviewStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: planVM.builderStep)

                navigationButtons
                    .padding()
            }
            .navigationTitle("Succession Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await beneficiaryVM.loadBeneficiaries()
                await planVM.loadPlans()
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<planVM.totalBuilderSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= planVM.builderStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
        .accessibilityLabel("Step \(planVM.builderStep + 1) of \(planVM.totalBuilderSteps)")
    }

    // MARK: - Step 1: Name

    private var nameStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name Your Plan")
                        .font(.title2.bold())
                    Text("Give your succession plan a name to help you identify it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                TextField("Plan Name", text: $planVM.planName)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .accessibilityLabel("Plan name")
            }
            .padding()
        }
    }

    // MARK: - Step 2: Beneficiaries

    private var beneficiaryStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Assign Beneficiaries")
                        .font(.title2.bold())
                    Text("Select who should receive your assets if the plan triggers.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if beneficiaryVM.beneficiaries.isEmpty {
                    ContentUnavailableView(
                        "No Beneficiaries",
                        systemImage: "person.badge.plus",
                        description: Text("Add beneficiaries first from the Beneficiaries tab.")
                    )
                } else {
                    ForEach(beneficiaryVM.beneficiaries) { beneficiary in
                        beneficiaryToggleRow(beneficiary)
                    }
                }
            }
            .padding()
        }
    }

    private func beneficiaryToggleRow(_ beneficiary: Beneficiary) -> some View {
        let isSelected = planVM.selectedBeneficiaryIDs.contains(beneficiary.id)
        return Button {
            if isSelected {
                planVM.selectedBeneficiaryIDs.remove(beneficiary.id)
            } else {
                planVM.selectedBeneficiaryIDs.insert(beneficiary.id)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(beneficiary.name)
                        .font(.subheadline.weight(.medium))
                    Text(beneficiary.relationship.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(beneficiary.email)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                isSelected ? Color.blue.opacity(0.08) : Color.clear,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(beneficiary.name), \(isSelected ? "selected" : "not selected")")
    }

    // MARK: - Step 3: Triggers

    private var triggersStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set Trigger Conditions")
                        .font(.title2.bold())
                    Text("Define what activates your succession plan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Dormancy Detection
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $planVM.enableDormancy) {
                        Label("Dormancy Detection", systemImage: "clock.badge.exclamationmark")
                    }

                    if planVM.enableDormancy {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trigger after \(planVM.dormancyDays) days of inactivity")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Slider(
                                value: .init(
                                    get: { Double(planVM.dormancyDays) },
                                    set: { planVM.dormancyDays = Int($0) }
                                ),
                                in: 30...365,
                                step: 30
                            )
                            .accessibilityLabel("Dormancy period: \(planVM.dormancyDays) days")
                        }
                        .padding(.leading, 36)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Dead-Man Switch
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $planVM.enableDeadManSwitch) {
                        Label("Dead-Man Switch", systemImage: "hand.raised.fill")
                    }

                    if planVM.enableDeadManSwitch {
                        Picker("Check-in Interval", selection: $planVM.checkInInterval) {
                            ForEach(CheckInInterval.allCases) { interval in
                                Text(interval.displayName).tag(interval)
                            }
                        }
                        .padding(.leading, 36)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }

    // MARK: - Step 4: Review

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review Your Plan")
                        .font(.title2.bold())
                    Text("Confirm the details of your succession plan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                reviewRow(label: "Plan Name", value: planVM.planName)
                reviewRow(label: "Beneficiaries", value: "\(planVM.selectedBeneficiaryIDs.count) selected")

                if planVM.enableDormancy {
                    reviewRow(label: "Dormancy Trigger", value: "\(planVM.dormancyDays) days")
                }

                if planVM.enableDeadManSwitch {
                    reviewRow(label: "Check-In Interval", value: planVM.checkInInterval.displayName)
                }

                Text("Once activated, LegacyVault will continuously monitor your accounts and enforce the trigger conditions you've configured.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top)
            }
            .padding()
        }
    }

    private func reviewRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack {
            if planVM.builderStep > 0 {
                Button("Back") {
                    withAnimation { planVM.builderStep -= 1 }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if planVM.builderStep < planVM.totalBuilderSteps - 1 {
                Button("Next") {
                    withAnimation { planVM.builderStep += 1 }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Create Plan") {
                    Task {
                        if await planVM.createPlan() {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
