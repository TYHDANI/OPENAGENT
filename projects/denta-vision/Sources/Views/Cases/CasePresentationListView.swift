import SwiftUI

struct CasePresentationListView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(StoreManager.self) private var storeManager

    @State private var searchText = ""
    @State private var filterStatus: CaseStatus? = nil
    @State private var showingCreateCase = false
    @State private var selectedCase: CasePresentation? = nil

    private var filteredCases: [CasePresentation] {
        let cases = dataManager.casePresentations.filter { casePresentation in
            // Filter by status
            if let status = filterStatus, casePresentation.status != status {
                return false
            }

            // Filter by search text
            if !searchText.isEmpty {
                let lowercased = searchText.lowercased()
                let matchesTitle = casePresentation.title.lowercased().contains(lowercased)
                let matchesPatient = dataManager.patients
                    .first(where: { $0.id == casePresentation.patientId })?
                    .fullName.lowercased().contains(lowercased) ?? false

                return matchesTitle || matchesPatient
            }

            return true
        }

        return cases.sorted { $0.presentationDate > $1.presentationDate }
    }

    private var totalOutstandingAmount: Decimal {
        filteredCases
            .filter { $0.status == .accepted || $0.status == .partiallyAccepted }
            .reduce(0) { $0 + $1.outOfPocketCost }
    }

    var body: some View {
        VStack(spacing: 0) {
            if dataManager.casePresentations.isEmpty {
                emptyStateView
            } else {
                // Summary Header
                summaryHeader

                // Filter Pills
                filterView

                // Cases List
                casesList
            }
        }
        .navigationTitle("Treatment Cases")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search cases or patients")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(dataManager.patients.sorted { $0.lastName < $1.lastName }) { patient in
                        Button(patient.fullName) {
                            selectedCase = nil
                            showingCreateCase = true
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!storeManager.isSubscribed)
            }
        }
        .sheet(isPresented: $showingCreateCase) {
            if let patient = dataManager.patients.first {
                NavigationStack {
                    CreateCasePresentationView(patient: patient)
                }
            }
        }
        .sheet(item: $selectedCase) { casePresentation in
            NavigationStack {
                CasePresentationDetailView(casePresentation: casePresentation)
            }
        }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "briefcase")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Treatment Cases")
                .font(.title2)
                .fontWeight(.medium)

            Text("Create treatment plans with financing options")
                .foregroundStyle(.secondary)

            if !dataManager.patients.isEmpty {
                Button {
                    showingCreateCase = true
                } label: {
                    Label("Create First Case", systemImage: "plus")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var summaryHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Outstanding")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalOutstandingAmount.formatted(.currency(code: "USD")))
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Active Cases")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(filteredCases.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var filterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                FilterChip(
                    title: "All",
                    isSelected: filterStatus == nil
                ) {
                    filterStatus = nil
                }

                ForEach(CaseStatus.allCases, id: \.self) { status in
                    FilterChip(
                        title: status.rawValue,
                        isSelected: filterStatus == status,
                        color: colorForStatus(status)
                    ) {
                        filterStatus = status
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var casesList: some View {
        List {
            ForEach(filteredCases) { casePresentation in
                CasePresentationRowView(
                    casePresentation: casePresentation,
                    patient: dataManager.patients.first { $0.id == casePresentation.patientId }
                ) {
                    selectedCase = casePresentation
                }
            }
        }
        .listStyle(.plain)
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
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Case Row View

struct CasePresentationRowView: View {
    let casePresentation: CasePresentation
    let patient: Patient?
    let action: () -> Void

    private var statusColor: Color {
        switch casePresentation.status {
        case .accepted: return .green
        case .declined: return .red
        case .presented: return .blue
        case .draft: return .gray
        case .partiallyAccepted: return .orange
        case .expired: return .secondary
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(casePresentation.title)
                            .font(.headline)

                        if let patient = patient {
                            Text(patient.fullName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text(casePresentation.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(12)
                }

                // Financial Summary
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(casePresentation.totalCost.formatted(.currency(code: "USD")))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Insurance")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(casePresentation.insuranceEstimate.formatted(.currency(code: "USD")))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Out of Pocket")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(casePresentation.outOfPocketCost.formatted(.currency(code: "USD")))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }

                    Spacer()
                }

                // Date
                Text(casePresentation.presentationDate.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CasePresentationListView()
            .environment(DataManager())
            .environment(StoreManager())
    }
}