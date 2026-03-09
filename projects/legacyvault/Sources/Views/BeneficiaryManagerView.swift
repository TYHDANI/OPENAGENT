import SwiftUI

struct BeneficiaryManagerView: View {
    @State private var viewModel = BeneficiaryViewModel()
    @State private var showingAddSheet = false
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        List {
            if viewModel.beneficiaries.isEmpty {
                ContentUnavailableView(
                    "No Beneficiaries",
                    systemImage: "person.2.slash",
                    description: Text("Add beneficiaries who will receive your crypto assets.")
                )
            } else {
                ForEach(viewModel.beneficiaries) { beneficiary in
                    beneficiaryRow(beneficiary)
                }
                .onDelete { offsets in
                    let toDelete = offsets.map { viewModel.beneficiaries[$0] }
                    Task {
                        for b in toDelete {
                            await viewModel.deleteBeneficiary(b)
                        }
                    }
                }
            }
        }
        .navigationTitle("Beneficiaries")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.resetForm()
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add beneficiary")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            BeneficiaryFormView(viewModel: viewModel, isPresented: $showingAddSheet)
        }
        .task {
            await viewModel.loadBeneficiaries()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    private func beneficiaryRow(_ beneficiary: Beneficiary) -> some View {
        Button {
            viewModel.startEditing(beneficiary)
            showingAddSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(beneficiary.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(beneficiary.relationship.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                verificationBadge(beneficiary.verificationStatus)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(beneficiary.name), \(beneficiary.relationship.displayName)")
    }

    private func verificationBadge(_ status: VerificationStatus) -> some View {
        HStack(spacing: 4) {
            Image(systemName: verificationIcon(status))
                .font(.caption)
            Text(status.rawValue.capitalized)
                .font(.caption2)
        }
        .foregroundStyle(verificationColor(status))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(verificationColor(status).opacity(0.1), in: Capsule())
    }

    private func verificationIcon(_ status: VerificationStatus) -> String {
        switch status {
        case .verified: return "checkmark.seal.fill"
        case .pending: return "clock"
        case .unverified: return "exclamationmark.triangle"
        }
    }

    private func verificationColor(_ status: VerificationStatus) -> Color {
        switch status {
        case .verified: return .green
        case .pending: return .orange
        case .unverified: return .gray
        }
    }
}

// MARK: - Beneficiary Form

struct BeneficiaryFormView: View {
    @Bindable var viewModel: BeneficiaryViewModel
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $viewModel.name)
                        .textContentType(.name)
                        .accessibilityLabel("Beneficiary name")

                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .accessibilityLabel("Beneficiary email")

                    TextField("Phone", text: $viewModel.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .accessibilityLabel("Beneficiary phone")
                }

                Section("Relationship") {
                    Picker("Relationship", selection: $viewModel.relationship) {
                        ForEach(Relationship.allCases) { rel in
                            Text(rel.displayName).tag(rel)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Additional notes")
                }
            }
            .navigationTitle(viewModel.editingBeneficiary == nil ? "Add Beneficiary" : "Edit Beneficiary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.saveBeneficiary() {
                                isPresented = false
                            }
                        }
                    }
                    .disabled(viewModel.name.isEmpty || viewModel.email.isEmpty)
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
