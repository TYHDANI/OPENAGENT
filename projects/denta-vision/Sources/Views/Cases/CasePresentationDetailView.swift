import SwiftUI

struct CasePresentationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataManager.self) private var dataManager
    @Environment(AuthManager.self) private var authManager

    let casePresentation: CasePresentation

    @State private var showingStatusChange = false
    @State private var showingFinancingApplication = false
    @State private var selectedFinancingOption: FinancingOption? = nil

    private var patient: Patient? {
        dataManager.patients.first { $0.id == casePresentation.patientId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection

                // Financial Summary
                financialSummarySection

                // Treatments
                treatmentsSection

                // Financing Options
                if !casePresentation.financingOptions.isEmpty {
                    financingOptionsSection
                }

                // Notes
                if !casePresentation.notes.isEmpty {
                    notesSection
                }

                // Actions
                actionsSection
            }
            .padding()
        }
        .navigationTitle(casePresentation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingStatusChange) {
            StatusChangeView(
                currentStatus: casePresentation.status,
                onStatusChange: updateStatus
            )
            .presentationDetents([.medium])
        }
        .sheet(item: $selectedFinancingOption) { option in
            NavigationStack {
                FinancingApplicationView(
                    patient: patient!,
                    option: option,
                    amount: casePresentation.outOfPocketCost
                )
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let patient = patient {
                        Text(patient.fullName)
                            .font(.headline)
                    }

                    Text("Presented on \(casePresentation.presentationDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusBadge
            }

            if let acceptedDate = casePresentation.acceptedDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Accepted on \(acceptedDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var statusBadge: some View {
        Text(casePresentation.status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(colorForStatus(casePresentation.status).opacity(0.2))
            .foregroundColor(colorForStatus(casePresentation.status))
            .cornerRadius(20)
    }

    private var financialSummarySection: some View {
        GroupBox("Financial Summary") {
            VStack(spacing: 16) {
                HStack {
                    Text("Total Treatment Cost")
                    Spacer()
                    Text(casePresentation.totalCost.formatted(.currency(code: "USD")))
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Insurance Estimate")
                    Spacer()
                    Text(casePresentation.insuranceEstimate.formatted(.currency(code: "USD")))
                        .foregroundStyle(.green)
                }

                Divider()

                HStack {
                    Text("Patient Responsibility")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(casePresentation.outOfPocketCost.formatted(.currency(code: "USD")))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private var treatmentsSection: some View {
        GroupBox("Proposed Treatments") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(casePresentation.treatments) { treatment in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(treatment.type.rawValue)
                                .fontWeight(.medium)

                            if treatment.priority == .urgent {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }

                            Spacer()

                            Text(treatment.estimatedCost.formatted(.currency(code: "USD")))
                        }

                        if !treatment.toothNumbers.isEmpty {
                            Text("Teeth: \(treatment.toothNumbers.map { "#\($0)" }.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(treatment.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if treatment != casePresentation.treatments.last {
                        Divider()
                    }
                }
            }
        }
    }

    private var financingOptionsSection: some View {
        GroupBox("Financing Options") {
            VStack(spacing: 12) {
                ForEach(casePresentation.financingOptions) { option in
                    FinancingOptionCard(option: option) {
                        if patient != nil && casePresentation.status != .declined {
                            selectedFinancingOption = option
                        }
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        GroupBox("Notes") {
            Text(casePresentation.notes)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if casePresentation.status == .draft || casePresentation.status == .presented {
                Button {
                    showingStatusChange = true
                } label: {
                    Label("Update Status", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            if casePresentation.status == .accepted {
                NavigationLink {
                    // Would navigate to treatment tracking
                    Text("Treatment Tracking (Coming Soon)")
                } label: {
                    Label("Track Treatments", systemImage: "checklist")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Helpers

    private func colorForStatus(_ status: CaseStatus) -> Color {
        switch status {
        case .accepted: return .green
        case .declined: return .red
        case .presented: return .blue
        case .draft: return .gray
        case .partiallyAccepted: return .orange
        case .expired: return .secondary
        }
    }

    private func updateStatus(_ newStatus: CaseStatus) {
        var updated = casePresentation
        updated.status = newStatus

        if newStatus == .accepted {
            updated.acceptedDate = Date()
        }

        do {
            try dataManager.updateCasePresentation(updated)
        } catch {
            // Handle error
        }
    }
}

// MARK: - Financing Option Card

struct FinancingOptionCard: View {
    let option: FinancingOption
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(option.provider.rawValue)
                        .font(.headline)

                    if option.isPromotional {
                        Text("PROMO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(option.monthlyPayment.formatted(.currency(code: "USD")))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Term")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(option.termMonths) months")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    if option.interestRate > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("APR")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(NSDecimalNumber(decimal: option.interestRate * 100).intValue)%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }

                if let promoDetails = option.promoDetails {
                    Text(promoDetails)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Change View

struct StatusChangeView: View {
    @Environment(\.dismiss) private var dismiss

    let currentStatus: CaseStatus
    let onStatusChange: (CaseStatus) -> Void

    @State private var selectedStatus: CaseStatus
    @State private var notes = ""

    init(currentStatus: CaseStatus, onStatusChange: @escaping (CaseStatus) -> Void) {
        self.currentStatus = currentStatus
        self.onStatusChange = onStatusChange
        _selectedStatus = State(initialValue: currentStatus)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Status") {
                    HStack {
                        Text(currentStatus.rawValue)
                        Spacer()
                        Circle()
                            .fill(colorForStatus(currentStatus))
                            .frame(width: 12, height: 12)
                    }
                }

                Section("New Status") {
                    ForEach(CaseStatus.allCases, id: \.self) { status in
                        HStack {
                            Text(status.rawValue)
                            Spacer()
                            if selectedStatus == status {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedStatus = status
                        }
                    }
                }

                Section("Notes") {
                    TextField("Reason for status change...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Update Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        onStatusChange(selectedStatus)
                        dismiss()
                    }
                    .disabled(selectedStatus == currentStatus)
                }
            }
        }
    }

    private func colorForStatus(_ status: CaseStatus) -> Color {
        switch status {
        case .accepted: return .green
        case .declined: return .red
        case .presented: return .blue
        case .draft: return .gray
        case .partiallyAccepted: return .orange
        case .expired: return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CasePresentationDetailView(
            casePresentation: CasePresentation(
                patientId: UUID(),
                title: "Comprehensive Treatment Plan",
                treatments: [
                    Treatment(
                        type: .crown,
                        toothNumbers: [14],
                        description: "Porcelain crown",
                        estimatedCost: 1500
                    )
                ],
                totalCost: 1500,
                insuranceEstimate: 750,
                status: .presented
            )
        )
        .environment(DataManager())
        .environment(AuthManager())
    }
}