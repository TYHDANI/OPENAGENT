import SwiftUI

struct AddEditPatientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataManager.self) private var dataManager

    let patient: Patient?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dateOfBirth = Date()
    @State private var email = ""
    @State private var phone = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var medicalHistory = ""
    @State private var preferredFinancing: Set<FinancingType> = []
    @State private var hipaaConsent = false

    @State private var showingError = false
    @State private var errorMessage = ""

    private var isEditing: Bool { patient != nil }

    var body: some View {
        Form {
            // Personal Information
            Section("Personal Information") {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)

                DatePicker("Date of Birth",
                          selection: $dateOfBirth,
                          in: ...Date(),
                          displayedComponents: .date)
            }

            // Contact Information
            Section("Contact Information") {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
            }

            // Address
            Section("Address") {
                TextField("Street", text: $street)
                TextField("City", text: $city)
                TextField("State", text: $state)
                    .textInputAutocapitalization(.characters)
                TextField("ZIP Code", text: $zipCode)
                    .keyboardType(.numberPad)
            }

            // Medical Information
            Section("Medical Information") {
                TextField("Medical History & Notes",
                         text: $medicalHistory,
                         axis: .vertical)
                    .lineLimit(3...6)
            }

            // Financial Preferences
            Section("Preferred Financing Options") {
                ForEach(FinancingType.allCases, id: \.self) { type in
                    Toggle(type.rawValue, isOn: binding(for: type))
                }
            }

            // HIPAA Consent
            Section {
                Toggle("HIPAA Privacy Consent", isOn: $hipaaConsent)
                    .tint(.blue)

                if hipaaConsent {
                    Text("Patient consents to the collection, use, and disclosure of their health information as outlined in our Privacy Policy.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Patient" : "New Patient")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    savePatient()
                }
                .fontWeight(.medium)
                .disabled(!canSave)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadPatientData()
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        hipaaConsent
    }

    private func binding(for financingType: FinancingType) -> Binding<Bool> {
        Binding(
            get: { preferredFinancing.contains(financingType) },
            set: { isOn in
                if isOn {
                    preferredFinancing.insert(financingType)
                } else {
                    preferredFinancing.remove(financingType)
                }
            }
        )
    }

    private func loadPatientData() {
        guard let patient else { return }

        firstName = patient.firstName
        lastName = patient.lastName
        dateOfBirth = patient.dateOfBirth
        email = patient.email ?? ""
        phone = patient.phone ?? ""
        medicalHistory = patient.medicalHistory
        hipaaConsent = patient.hipaaConsent

        if let address = patient.address {
            street = address.street
            city = address.city
            state = address.state
            zipCode = address.zipCode
        }

        preferredFinancing = Set(patient.preferredFinancing)
    }

    private func savePatient() {
        let address = (!street.isEmpty || !city.isEmpty) ?
            Address(
                street: street,
                city: city,
                state: state,
                zipCode: zipCode
            ) : nil

        do {
            if let patient {
                // Update existing patient
                var updated = patient
                updated.firstName = firstName
                updated.lastName = lastName
                updated.dateOfBirth = dateOfBirth
                updated.email = email.isEmpty ? nil : email
                updated.phone = phone.isEmpty ? nil : phone
                updated.address = address
                updated.medicalHistory = medicalHistory
                updated.preferredFinancing = Array(preferredFinancing)
                updated.hipaaConsent = hipaaConsent
                if hipaaConsent && patient.hipaaConsentDate == nil {
                    updated.hipaaConsentDate = Date()
                }

                try dataManager.updatePatient(updated)
            } else {
                // Create new patient
                let newPatient = Patient(
                    firstName: firstName,
                    lastName: lastName,
                    dateOfBirth: dateOfBirth,
                    email: email.isEmpty ? nil : email,
                    phone: phone.isEmpty ? nil : phone,
                    address: address,
                    medicalHistory: medicalHistory,
                    preferredFinancing: Array(preferredFinancing),
                    hipaaConsent: hipaaConsent,
                    hipaaConsentDate: hipaaConsent ? Date() : nil
                )

                try dataManager.createPatient(newPatient)
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview("New Patient") {
    NavigationStack {
        AddEditPatientView(patient: nil)
            .environment(DataManager())
    }
}

#Preview("Edit Patient") {
    NavigationStack {
        AddEditPatientView(patient: Patient(
            firstName: "John",
            lastName: "Doe",
            dateOfBirth: Date()
        ))
        .environment(DataManager())
    }
}