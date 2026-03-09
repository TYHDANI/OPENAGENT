import SwiftUI

struct AddAccountSheet: View {
    let entityID: UUID
    @Environment(EntityViewModel.self) private var entityVM
    @Environment(\.dismiss) private var dismiss

    // MARK: Flow State

    enum FlowStep: Int, CaseIterable {
        case details = 0
        case apiKey = 1
        case syncing = 2
        case success = 3
    }

    @State private var currentStep: FlowStep = .details

    // MARK: Account Fields

    @State private var accountName = ""
    @State private var custodian: Custodian = .coinbase
    @State private var accountIdentifier = ""

    // MARK: API Key Fields

    @State private var apiKey = ""
    @State private var apiSecret = ""
    @State private var passphrase = "" // Some exchanges require this

    // MARK: Sync State

    @State private var syncProgress: Double = 0.0
    @State private var syncStatusText = "Preparing..."
    @State private var syncComplete = false
    @State private var syncError: String?
    @State private var transactionsSynced = 0

    // MARK: Created Account

    @State private var createdAccount: CustodialAccount?

    var body: some View {
        NavigationStack {
            ZStack {
                TPTheme.background.ignoresSafeArea()

                Group {
                    switch currentStep {
                    case .details:
                        detailsStep
                    case .apiKey:
                        apiKeyStep
                    case .syncing:
                        syncingStep
                    case .success:
                        successStep
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep != .syncing {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(TPTheme.textSecondary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    stepIndicator
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        switch currentStep {
        case .details: return "Add Account"
        case .apiKey: return "API Credentials"
        case .syncing: return "Syncing"
        case .success: return "Connected"
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(FlowStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue ? TPTheme.gold : TPTheme.surfaceRaised)
                    .frame(width: step == currentStep ? 20 : 8, height: 4)
                    .animation(.spring(response: 0.4), value: currentStep)
            }
        }
    }

    // MARK: - Step 1: Account Details

    private var detailsStep: some View {
        ScrollView {
            VStack(spacing: TPTheme.sectionSpacing) {
                // Custodian picker
                VStack(alignment: .leading, spacing: 10) {
                    TPSectionHeader(title: "Exchange", icon: "building.columns")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(Custodian.allCases) { c in
                            Button {
                                custodian = c
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: c.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(custodian == c ? TPTheme.gold : TPTheme.textSecondary)
                                    Text(c.rawValue)
                                        .font(TPTheme.subheading(14))
                                        .foregroundStyle(custodian == c ? TPTheme.textPrimary : TPTheme.textSecondary)
                                    Spacer()
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: TPTheme.cornerRadiusSmall)
                                        .fill(custodian == c ? TPTheme.gold.opacity(0.1) : TPTheme.surfaceRaised)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: TPTheme.cornerRadiusSmall)
                                        .stroke(
                                            custodian == c ? TPTheme.gold.opacity(0.4) : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Account info
                VStack(alignment: .leading, spacing: 10) {
                    TPSectionHeader(title: "Account Info", icon: "info.circle")

                    VStack(spacing: 12) {
                        themedTextField("Account Name", text: $accountName, icon: "textformat")
                        themedTextField("Account ID (last 4 digits)", text: $accountIdentifier, icon: "number")
                    }
                }

                // Next button
                Button {
                    if custodian == .manual {
                        // Manual entry skips API key step
                        Task { await createAccountAndSync(skipAPI: true) }
                    } else {
                        withAnimation { currentStep = .apiKey }
                    }
                } label: {
                    Text(custodian == .manual ? "Add Account" : "Next: API Credentials")
                        .font(TPTheme.subheading())
                        .foregroundStyle(TPTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: TPTheme.cornerRadius)
                                .fill(accountName.isEmpty ? TPTheme.textTertiary : TPTheme.gold)
                        )
                }
                .disabled(accountName.isEmpty)

                Spacer(minLength: 40)
            }
            .padding(TPTheme.paddingStandard)
        }
    }

    // MARK: - Step 2: API Key Entry

    private var apiKeyStep: some View {
        ScrollView {
            VStack(spacing: TPTheme.sectionSpacing) {
                // Info banner
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(TPTheme.gold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Secure Connection")
                            .font(TPTheme.subheading(14))
                            .foregroundStyle(TPTheme.textPrimary)
                        Text("API keys are encrypted and stored in the device Keychain. They are never transmitted to our servers. Use read-only keys for maximum security.")
                            .font(TPTheme.caption())
                            .foregroundStyle(TPTheme.textSecondary)
                    }
                }
                .glassCard()

                // API key fields
                VStack(alignment: .leading, spacing: 10) {
                    TPSectionHeader(title: "\(custodian.rawValue) API Credentials", icon: "key.fill")

                    VStack(spacing: 12) {
                        themedSecureField("API Key", text: $apiKey, icon: "key")
                        themedSecureField("API Secret", text: $apiSecret, icon: "lock")

                        if custodianRequiresPassphrase {
                            themedSecureField("Passphrase", text: $passphrase, icon: "ellipsis.rectangle")
                        }
                    }
                }

                // Help link
                HStack {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(TPTheme.accentSecondary)
                    Text("How to generate a read-only API key on \(custodian.rawValue)")
                        .font(TPTheme.caption())
                        .foregroundStyle(TPTheme.accentSecondary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(TPTheme.accentSecondary)
                }
                .padding(.horizontal, 4)

                // Action buttons
                VStack(spacing: 10) {
                    Button {
                        Task { await createAccountAndSync(skipAPI: false) }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 14))
                            Text("Connect & Sync")
                                .font(TPTheme.subheading())
                        }
                        .foregroundStyle(TPTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: TPTheme.cornerRadius)
                                .fill(apiKey.isEmpty ? TPTheme.textTertiary : TPTheme.gold)
                        )
                    }
                    .disabled(apiKey.isEmpty)

                    Button {
                        Task { await createAccountAndSync(skipAPI: true) }
                    } label: {
                        Text("Skip for now")
                            .font(TPTheme.caption())
                            .foregroundStyle(TPTheme.textTertiary)
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(TPTheme.paddingStandard)
        }
    }

    // MARK: - Step 3: Syncing Progress

    private var syncingStep: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(TPTheme.gold.opacity(0.08))
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(TPTheme.gold.opacity(0.15), lineWidth: 3)
                    .frame(width: 100, height: 100)

                if syncComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(TPTheme.success)
                        .transition(.scale.combined(with: .opacity))
                } else if syncError != nil {
                    Image(systemName: "xmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(TPTheme.danger)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .tint(TPTheme.gold)
                }
            }

            VStack(spacing: 8) {
                Text(syncComplete ? "Sync Complete" : (syncError != nil ? "Sync Failed" : "Syncing Transactions..."))
                    .font(TPTheme.heading(20))
                    .foregroundStyle(TPTheme.textPrimary)

                Text(syncStatusText)
                    .font(TPTheme.caption())
                    .foregroundStyle(TPTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Progress bar
            if !syncComplete && syncError == nil {
                VStack(spacing: 6) {
                    ProgressView(value: syncProgress, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(TPTheme.gold)
                        .frame(maxWidth: 240)

                    Text("\(Int(syncProgress * 100))%")
                        .font(TPTheme.mono(12))
                        .foregroundStyle(TPTheme.textTertiary)
                }
            }

            if syncComplete {
                Text("\(transactionsSynced) transactions imported")
                    .font(TPTheme.subheading(14))
                    .foregroundStyle(TPTheme.gold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(TPTheme.gold.opacity(0.12))
                    )
            }

            Spacer()

            // Continue / Retry button
            if syncComplete || syncError != nil {
                Button {
                    if syncComplete {
                        withAnimation { currentStep = .success }
                    } else {
                        // Retry
                        syncError = nil
                        syncProgress = 0
                        Task { await performSync() }
                    }
                } label: {
                    Text(syncComplete ? "Continue" : "Retry")
                        .font(TPTheme.subheading())
                        .foregroundStyle(TPTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: TPTheme.cornerRadius)
                                .fill(syncComplete ? TPTheme.gold : TPTheme.warning)
                        )
                }
                .padding(.horizontal, TPTheme.paddingStandard)
            }

            Spacer(minLength: 20)
        }
    }

    // MARK: - Step 4: Success Confirmation

    private var successStep: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success badge
            ZStack {
                Circle()
                    .fill(TPTheme.success.opacity(0.1))
                    .frame(width: 96, height: 96)

                Circle()
                    .stroke(TPTheme.success.opacity(0.3), lineWidth: 2)
                    .frame(width: 96, height: 96)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(TPTheme.success)
            }

            VStack(spacing: 6) {
                Text("Account Connected")
                    .font(TPTheme.heading(22))
                    .foregroundStyle(TPTheme.textPrimary)

                Text("\(accountName) on \(custodian.rawValue)")
                    .font(TPTheme.body())
                    .foregroundStyle(TPTheme.textSecondary)
            }

            // Account summary card
            if let account = createdAccount {
                VStack(spacing: 12) {
                    summaryRow(label: "Exchange", value: account.custodian.rawValue, icon: "building.columns")
                    TPDivider()
                    summaryRow(label: "Account", value: account.accountName, icon: "person.text.rectangle")
                    TPDivider()
                    summaryRow(label: "Status", value: account.connectionStatus.rawValue, icon: "antenna.radiowaves.left.and.right")
                    if transactionsSynced > 0 {
                        TPDivider()
                        summaryRow(label: "Transactions", value: "\(transactionsSynced) imported", icon: "list.bullet.rectangle")
                    }
                }
                .glassCard()
                .padding(.horizontal, TPTheme.paddingStandard)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Text("View Entity Details")
                        .font(TPTheme.subheading())
                        .foregroundStyle(TPTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: TPTheme.cornerRadius)
                                .fill(TPTheme.gold)
                        )
                }

                Button {
                    // Reset flow for adding another account
                    resetFlow()
                } label: {
                    Text("Add Another Account")
                        .font(TPTheme.subheading(14))
                        .foregroundStyle(TPTheme.accentSecondary)
                }
            }
            .padding(.horizontal, TPTheme.paddingStandard)

            Spacer(minLength: 20)
        }
    }

    // MARK: - Reusable Components

    private func themedTextField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(TPTheme.textTertiary)
                .frame(width: 20)
            TextField(placeholder, text: text)
                .font(TPTheme.body())
                .foregroundStyle(TPTheme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: TPTheme.cornerRadiusSmall)
                .fill(TPTheme.surfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TPTheme.cornerRadiusSmall)
                .stroke(TPTheme.border, lineWidth: 1)
        )
        .accessibilityLabel(placeholder)
    }

    private func themedSecureField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(TPTheme.textTertiary)
                .frame(width: 20)
            SecureField(placeholder, text: text)
                .font(TPTheme.mono(14))
                .foregroundStyle(TPTheme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: TPTheme.cornerRadiusSmall)
                .fill(TPTheme.surfaceRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: TPTheme.cornerRadiusSmall)
                .stroke(TPTheme.border, lineWidth: 1)
        )
        .accessibilityLabel(placeholder)
    }

    private func summaryRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(TPTheme.gold)
                .frame(width: 20)
            Text(label)
                .font(TPTheme.caption())
                .foregroundStyle(TPTheme.textSecondary)
            Spacer()
            Text(value)
                .font(TPTheme.subheading(14))
                .foregroundStyle(TPTheme.textPrimary)
        }
    }

    // MARK: - Logic

    private var custodianRequiresPassphrase: Bool {
        custodian == .coinbase // Coinbase Pro required a passphrase
    }

    private func createAccountAndSync(skipAPI: Bool) async {
        let account = CustodialAccount(
            entityID: entityID,
            custodian: custodian,
            accountName: accountName,
            accountIdentifier: accountIdentifier,
            connectionStatus: skipAPI ? .connected : .pending
        )
        createdAccount = account
        await entityVM.addAccount(account)

        // Store API key in Keychain (simulated — real impl uses KeychainService)
        if !skipAPI && !apiKey.isEmpty {
            // In production: KeychainService.store(apiKey, for: account.id)
            // In production: KeychainService.store(apiSecret, for: account.id)
        }

        withAnimation { currentStep = .syncing }
        await performSync()
    }

    private func performSync() async {
        syncStatusText = "Connecting to \(custodian.rawValue)..."
        syncProgress = 0.0

        // Simulated sync phases
        let phases: [(String, Double, Int)] = [
            ("Authenticating...", 0.15, 0),
            ("Fetching account info...", 0.3, 0),
            ("Downloading transactions...", 0.55, 12),
            ("Processing cost basis...", 0.75, 24),
            ("Calculating tax lots...", 0.9, 31),
            ("Finalizing...", 1.0, 34),
        ]

        for (status, progress, txCount) in phases {
            try? await Task.sleep(for: .milliseconds(600))
            withAnimation(.easeInOut(duration: 0.3)) {
                syncStatusText = status
                syncProgress = progress
                if txCount > 0 { transactionsSynced = txCount }
            }
        }

        try? await Task.sleep(for: .milliseconds(400))

        withAnimation(.spring(response: 0.5)) {
            syncComplete = true
            syncStatusText = "All transactions imported successfully."
        }

        // Update account status to connected
        if var account = createdAccount {
            account.connectionStatus = .connected
            account.lastSyncDate = Date()
            createdAccount = account
        }
    }

    private func resetFlow() {
        currentStep = .details
        accountName = ""
        custodian = .coinbase
        accountIdentifier = ""
        apiKey = ""
        apiSecret = ""
        passphrase = ""
        syncProgress = 0
        syncComplete = false
        syncError = nil
        syncStatusText = "Preparing..."
        transactionsSynced = 0
        createdAccount = nil
    }
}
