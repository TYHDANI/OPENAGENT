import SwiftUI

struct SuccessionPlanView: View {
    @State private var viewModel = SuccessionPlanViewModel()
    @State private var showingBuilder = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let plan = viewModel.currentPlan {
                    activePlanCard(plan)
                    triggerConditionsSection(plan)
                    checkInSection(plan)
                    planActionsSection(plan)
                } else {
                    emptyState
                }

                navigationSection

                if viewModel.plans.count > 1 {
                    otherPlansSection
                }
            }
            .padding()
        }
        .navigationTitle("Succession Plan")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingBuilder = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Create new plan")
            }
        }
        .sheet(isPresented: $showingBuilder) {
            SuccessionPlanBuilderView()
        }
        .task {
            await viewModel.loadPlans()
        }
        .onChange(of: showingBuilder) { _, isShowing in
            if !isShowing {
                Task { await viewModel.loadPlans() }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Succession Plan", systemImage: "shield.slash")
        } description: {
            Text("Create a succession plan to protect your crypto assets for your beneficiaries.")
        } actions: {
            Button("Create Plan") {
                showingBuilder = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Active Plan Card

    private func activePlanCard(_ plan: SuccessionPlan) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.name)
                        .font(.headline)
                    Text("Status: \(plan.status.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundStyle(planStatusColor(plan.status))
                }

                Spacer()

                statusBadge(plan.status)
            }

            Divider()

            HStack {
                statItem(
                    label: "Beneficiaries",
                    value: "\(plan.beneficiaryIDs.count)",
                    icon: "person.2"
                )
                Spacer()
                statItem(
                    label: "Triggers",
                    value: "\(plan.triggerConditions.filter(\.isEnabled).count)",
                    icon: "bolt.shield"
                )
                Spacer()
                statItem(
                    label: "Contacts",
                    value: "\(plan.trustedContacts.count)",
                    icon: "person.badge.shield.checkmark"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func statItem(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func statusBadge(_ status: PlanStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(planStatusColor(status).opacity(0.15), in: Capsule())
            .foregroundStyle(planStatusColor(status))
    }

    private func planStatusColor(_ status: PlanStatus) -> Color {
        switch status {
        case .active: return .green
        case .draft: return .orange
        case .triggered: return .red
        case .executed: return .blue
        case .paused: return .gray
        }
    }

    // MARK: - Trigger Conditions

    private func triggerConditionsSection(_ plan: SuccessionPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trigger Conditions")
                .font(.headline)

            ForEach(plan.triggerConditions) { trigger in
                HStack(spacing: 12) {
                    Image(systemName: triggerIcon(trigger.type))
                        .foregroundStyle(trigger.isEnabled ? .blue : .gray)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(trigger.type.displayName)
                            .font(.subheadline.weight(.medium))
                        Text(triggerDetail(trigger))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: trigger.isEnabled ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(trigger.isEnabled ? .green : .gray)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func triggerIcon(_ type: TriggerType) -> String {
        switch type {
        case .dormancy: return "moon.zzz"
        case .deadManSwitch: return "hand.raised"
        case .trustedContactVote: return "person.3"
        }
    }

    private func triggerDetail(_ trigger: TriggerCondition) -> String {
        switch trigger.type {
        case .dormancy:
            return "Triggers after \(trigger.dormancyDays) days of inactivity"
        case .deadManSwitch:
            return "Check-in interval: \(trigger.checkInInterval.displayName)"
        case .trustedContactVote:
            return "Threshold: \(trigger.trustedContactThreshold) confirmations"
        }
    }

    // MARK: - Check-In

    private func checkInSection(_ plan: SuccessionPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Check-In Status")
                .font(.headline)

            if let lastCheckIn = plan.lastCheckInDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Last check-in: \(lastCheckIn, format: .relative(presentation: .named))")
                        .font(.subheadline)
                }
            }

            if let nextCheckIn = plan.nextCheckInDate {
                HStack {
                    Image(systemName: nextCheckIn < Date() ? "exclamationmark.triangle.fill" : "clock")
                        .foregroundStyle(nextCheckIn < Date() ? .red : .blue)
                    Text("Next check-in: \(nextCheckIn, format: .relative(presentation: .named))")
                        .font(.subheadline)
                        .foregroundStyle(nextCheckIn < Date() ? .red : .primary)
                }
            }

            Button {
                Task { await viewModel.performCheckIn() }
            } label: {
                Label("Check In Now", systemImage: "hand.thumbsup.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Confirm check-in")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Navigation to Related Screens

    private var navigationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manage")
                .font(.headline)

            NavigationLink {
                BeneficiaryManagerView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 32)
                    Text("Beneficiaries")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            NavigationLink {
                DeadManSwitchView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 32)
                    Text("Dead-Man Switch")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Plan Actions

    private func planActionsSection(_ plan: SuccessionPlan) -> some View {
        VStack(spacing: 8) {
            if plan.status != .active {
                Button {
                    Task { await viewModel.activatePlan(plan) }
                } label: {
                    Label("Activate Plan", systemImage: "play.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button(role: .destructive) {
                Task { await viewModel.deletePlan(plan) }
            } label: {
                Label("Delete Plan", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Other Plans

    private var otherPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Plans")
                .font(.headline)

            ForEach(viewModel.plans) { plan in
                Button {
                    viewModel.currentPlan = plan
                } label: {
                    HStack {
                        Image(systemName: plan.status == .active ? "shield.checkered" : "shield")
                            .foregroundStyle(planStatusColor(plan.status))
                        Text(plan.name)
                            .font(.subheadline)
                        Spacer()
                        statusBadge(plan.status)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
