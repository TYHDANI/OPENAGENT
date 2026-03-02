import SwiftUI

struct PatientsListView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(AuthManager.self) private var authManager

    @State private var searchText = ""
    @State private var showingAddPatient = false
    @State private var selectedPatient: Patient? = nil

    private var filteredPatients: [Patient] {
        dataManager.searchPatients(query: searchText)
            .sorted { $0.lastName < $1.lastName }
    }

    var body: some View {
        VStack(spacing: 0) {
            if dataManager.patients.isEmpty && searchText.isEmpty {
                emptyStateView
            } else {
                patientsList
            }
        }
        .navigationTitle("Patients")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search patients")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddPatient = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPatient) {
            NavigationStack {
                AddEditPatientView(patient: nil)
            }
        }
        .sheet(item: $selectedPatient) { patient in
            NavigationStack {
                PatientDetailView(patient: patient)
            }
        }
        .onChange(of: selectedPatient) { _, _ in
            authManager.updateActivity()
        }
    }

    // MARK: - Views

    private var patientsList: some View {
        List {
            ForEach(filteredPatients) { patient in
                PatientRowView(patient: patient) {
                    selectedPatient = patient
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deletePatient(patient)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    NavigationLink {
                        AddEditPatientView(patient: patient)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Patients Yet")
                .font(.title2)
                .fontWeight(.medium)

            Text("Add your first patient to get started")
                .foregroundStyle(.secondary)

            Button {
                showingAddPatient = true
            } label: {
                Label("Add Patient", systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func deletePatient(_ patient: Patient) {
        withAnimation {
            dataManager.deletePatient(patient)
        }
    }
}

// MARK: - Patient Row View

struct PatientRowView: View {
    let patient: Patient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.fullName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        Label("\(patient.age) yrs", systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let lastVisit = patient.lastVisit {
                            Label(lastVisit.formatted(.relative(presentation: .named)),
                                  systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if patient.preferredFinancing.contains(.careCredit) {
                    Image(systemName: "creditcard.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PatientsListView()
            .environment(DataManager())
            .environment(AuthManager())
    }
}