import SwiftUI

struct PatientDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataManager.self) private var dataManager

    let patient: Patient

    @State private var selectedTab = 0
    @State private var showingNewChart = false
    @State private var showingNewCase = false

    private var charts: [DentalChart] {
        dataManager.getDentalCharts(for: patient.id)
    }

    private var cases: [CasePresentation] {
        dataManager.getCasePresentations(for: patient.id)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Patient Header
                patientHeader

                // Tab Selection
                Picker("View", selection: $selectedTab) {
                    Text("Charts").tag(0)
                    Text("Cases").tag(1)
                    Text("Info").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab Content
                switch selectedTab {
                case 0:
                    chartsSection
                case 1:
                    casesSection
                case 2:
                    infoSection
                default:
                    EmptyView()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(patient.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingNewChart) {
            NavigationStack {
                VoiceChartingView(patientId: patient.id)
            }
        }
        .sheet(isPresented: $showingNewCase) {
            NavigationStack {
                CreateCasePresentationView(patient: patient)
            }
        }
    }

    // MARK: - Sections

    private var patientHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            Text(patient.fullName)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 20) {
                Label("\(patient.age) years", systemImage: "calendar")
                if let phone = patient.phone {
                    Label(phone, systemImage: "phone")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var chartsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Dental Charts")
                    .font(.headline)
                Spacer()
                Button {
                    showingNewChart = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .padding(.horizontal)

            if charts.isEmpty {
                emptyChartsView
            } else {
                ForEach(charts) { chart in
                    ChartRowView(chart: chart)
                        .padding(.horizontal)
                }
            }
        }
    }

    private var casesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Treatment Cases")
                    .font(.headline)
                Spacer()
                Button {
                    showingNewCase = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            .padding(.horizontal)

            if cases.isEmpty {
                emptyCasesView
            } else {
                ForEach(cases) { casePresentation in
                    CaseRowView(casePresentation: casePresentation)
                        .padding(.horizontal)
                }
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Contact Information
            GroupBox("Contact Information") {
                VStack(alignment: .leading, spacing: 12) {
                    if let email = patient.email {
                        Label(email, systemImage: "envelope")
                    }
                    if let phone = patient.phone {
                        Label(phone, systemImage: "phone")
                    }
                    if let address = patient.address {
                        Label("\(address.street), \(address.city), \(address.state) \(address.zipCode)",
                              systemImage: "location")
                    }
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Medical History
            if !patient.medicalHistory.isEmpty {
                GroupBox("Medical History") {
                    Text(patient.medicalHistory)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // Financial Preferences
            if !patient.preferredFinancing.isEmpty {
                GroupBox("Financing Preferences") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(patient.preferredFinancing, id: \.self) { type in
                            Label(type.rawValue, systemImage: "creditcard")
                                .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // HIPAA Status
            GroupBox("Compliance") {
                HStack {
                    Image(systemName: patient.hipaaConsent ? "checkmark.shield.fill" : "xmark.shield")
                        .foregroundStyle(patient.hipaaConsent ? .green : .red)
                    Text("HIPAA Consent")
                    Spacer()
                    if let consentDate = patient.hipaaConsentDate {
                        Text(consentDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Empty States

    private var emptyChartsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No dental charts yet")
                .foregroundStyle(.secondary)
            Button("Create First Chart") {
                showingNewChart = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 150)
    }

    private var emptyCasesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "briefcase")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No treatment cases yet")
                .foregroundStyle(.secondary)
            Button("Create First Case") {
                showingNewCase = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(height: 150)
    }
}

// MARK: - Supporting Views

struct ChartRowView: View {
    let chart: DentalChart

    var body: some View {
        NavigationLink {
            DentalChartDetailView(chart: chart)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chart.recordingDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)

                    if let duration = chart.recordingDuration {
                        Label("\(Int(duration)) seconds", systemImage: "mic")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct CaseRowView: View {
    let casePresentation: CasePresentation

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
        NavigationLink {
            CasePresentationDetailView(casePresentation: casePresentation)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(casePresentation.title)
                        .font(.headline)

                    HStack {
                        Label(casePresentation.outOfPocketCost.formatted(.currency(code: "USD")),
                              systemImage: "dollarsign.circle")
                            .font(.caption)

                        Text("•")

                        Text(casePresentation.status.rawValue)
                            .font(.caption)
                            .foregroundStyle(statusColor)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PatientDetailView(patient: Patient(
            firstName: "Jane",
            lastName: "Smith",
            dateOfBirth: Date(),
            email: "jane@example.com",
            phone: "(555) 123-4567"
        ))
        .environment(DataManager())
    }
}