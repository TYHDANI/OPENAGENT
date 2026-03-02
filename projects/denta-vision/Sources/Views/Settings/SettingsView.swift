import SwiftUI

struct SettingsView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(DataManager.self) private var dataManager
    @Environment(AuthManager.self) private var authManager
    @State private var showSubscriptionDetails = false
    @State private var showDataExport = false
    @State private var showAuditLog = false

    var body: some View {
        List {
            // MARK: - Account Section
            Section("Account") {
                HStack {
                    Label("User", systemImage: "person.circle.fill")
                    Spacer()
                    Text(authManager.currentUser?.email ?? "No user")
                        .foregroundStyle(.secondary)
                }

                Button(action: {
                    storeManager.showPaywall = true
                }) {
                    Label("Subscription", systemImage: "creditcard.fill")
                        .foregroundColor(.primary)
                    Spacer()
                    if storeManager.isSubscribed {
                        Text(storeManager.activeSubscription?.displayName ?? "Active")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Free Trial")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Practice Settings
            Section("Practice Settings") {
                NavigationLink(destination: PracticeInfoView()) {
                    Label("Practice Information", systemImage: "building.2")
                }

                NavigationLink(destination: IntegrationsView()) {
                    Label("Integrations", systemImage: "link")
                }

                NavigationLink(destination: FinancingSettingsView()) {
                    Label("Financing Options", systemImage: "dollarsign.circle")
                }
            }

            // MARK: - Privacy & Security
            Section("Privacy & Security") {
                NavigationLink(destination: SecuritySettingsView()) {
                    Label("Security", systemImage: "lock.fill")
                }

                Button(action: { showAuditLog = true }) {
                    Label("HIPAA Audit Log", systemImage: "doc.text.magnifyingglass")
                }

                Button(action: { showDataExport = true }) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
            }

            // MARK: - Support
            Section("Support") {
                Link(destination: URL(string: "https://dentimatch.com/help")!) {
                    Label("Help Center", systemImage: "questionmark.circle")
                }

                Link(destination: URL(string: "mailto:support@dentimatch.com")!) {
                    Label("Contact Support", systemImage: "envelope")
                }
            }

            // MARK: - About
            Section("About") {
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text(Bundle.main.appVersion)
                        .foregroundStyle(.secondary)
                }

                NavigationLink(destination: LicensesView()) {
                    Label("Licenses", systemImage: "doc.text")
                }

                Link(destination: URL(string: "https://dentimatch.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }

                Link(destination: URL(string: "https://dentimatch.com/terms")!) {
                    Label("Terms of Service", systemImage: "doc.plaintext")
                }
            }

            // MARK: - Sign Out
            Section {
                Button(action: {
                    authManager.logout()
                }) {
                    Label("Sign Out", systemImage: "arrow.right.square")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showDataExport) {
            DataExportView()
        }
        .sheet(isPresented: $showAuditLog) {
            AuditLogView()
        }
    }
}

// MARK: - Supporting Views

struct PracticeInfoView: View {
    @State private var practiceName = ""
    @State private var address = ""
    @State private var phone = ""
    @State private var email = ""

    var body: some View {
        Form {
            Section("Practice Details") {
                TextField("Practice Name", text: $practiceName)
                TextField("Address", text: $address)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }

            Section {
                Button("Save Changes") {
                    // Save practice info
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Practice Information")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IntegrationsView: View {
    @State private var openDentalEnabled = false
    @State private var openDentalURL = ""

    var body: some View {
        Form {
            Section("Practice Management Systems") {
                Toggle(isOn: $openDentalEnabled) {
                    VStack(alignment: .leading) {
                        Text("Open Dental")
                            .font(.headline)
                        Text("Connect to your Open Dental server")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if openDentalEnabled {
                    TextField("Server URL", text: $openDentalURL)
                        .textInputAutocapitalization(.never)
                }
            }

            Section {
                Text("Additional integrations coming soon")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Integrations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FinancingSettingsView: View {
    @State private var careCreditEnabled = true
    @State private var sunbitEnabled = false
    @State private var inHouseEnabled = true

    var body: some View {
        Form {
            Section("Available Financing Partners") {
                Toggle("CareCredit", isOn: $careCreditEnabled)
                Toggle("Sunbit", isOn: $sunbitEnabled)
                Toggle("In-House Payment Plans", isOn: $inHouseEnabled)
            }

            Section("Default Terms") {
                HStack {
                    Text("In-House Down Payment")
                    Spacer()
                    Text("25%")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("In-House Term Length")
                    Spacer()
                    Text("3 months")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Financing Options")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SecuritySettingsView: View {
    @State private var requireBiometrics = true
    @State private var autoLockEnabled = true
    @State private var autoLockMinutes = 10

    var body: some View {
        Form {
            Section("Authentication") {
                Toggle("Require Face ID/Touch ID", isOn: $requireBiometrics)
            }

            Section("Session") {
                Toggle("Auto-Lock", isOn: $autoLockEnabled)

                if autoLockEnabled {
                    Picker("Lock After", selection: $autoLockMinutes) {
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("30 minutes").tag(30)
                    }
                }
            }

            Section {
                Text("All data is encrypted at rest and in transit using industry-standard AES-256 encryption.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataExportView: View {
    @State private var exportFormat = "JSON"
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $exportFormat) {
                        Text("JSON").tag("JSON")
                        Text("CSV").tag("CSV")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Data to Export") {
                    Label("Patient Records", systemImage: "person.3")
                    Label("Dental Charts", systemImage: "doc.text")
                    Label("Case Presentations", systemImage: "dollarsign.circle")
                }

                Section {
                    Button(action: exportData) {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Export All Data")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        // Dismiss
                    }
                }
            }
        }
    }

    func exportData() {
        isExporting = true
        // Export implementation
        // This would create a HIPAA-compliant export
    }
}

struct AuditLogView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(1...20, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Patient Record Accessed")
                            .font(.headline)
                        Text("User: doctor@example.com")
                            .font(.caption)
                        Text(Date(), style: .date) +
                        Text(" at ") +
                        Text(Date(), style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("HIPAA Audit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss
                    }
                }
            }
        }
    }
}

struct LicensesView: View {
    var body: some View {
        List {
            Text("Open Source Licenses")
                .font(.headline)

            Text("This app uses Apple frameworks and APIs.")
                .padding(.vertical)
        }
        .navigationTitle("Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(StoreManager())
            .environment(DataManager())
            .environment(AuthManager())
    }
}