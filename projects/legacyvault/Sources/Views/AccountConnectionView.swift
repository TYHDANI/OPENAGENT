import SwiftUI

struct AccountConnectionView: View {
    @State private var viewModel = AccountsViewModel()
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Platform") {
                    Picker("Select Platform", selection: $viewModel.selectedPlatform) {
                        ForEach(ExchangePlatform.allCases) { platform in
                            Label(platform.displayName, systemImage: platform.iconSystemName)
                                .tag(platform)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Account Name") {
                    TextField("Nickname (optional)", text: $viewModel.accountNickname)
                        .textContentType(.name)
                        .accessibilityLabel("Account nickname")
                }

                if viewModel.selectedPlatform.isExchange {
                    exchangeCredentialsSection
                } else {
                    walletAddressSection
                }

                Section {
                    securityNotice
                }

                Section {
                    Button("Connect Account") {
                        Task {
                            if await viewModel.addAccount() {
                                dismiss()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                    .disabled(isFormIncomplete)
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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

    // MARK: - Exchange Credentials

    private var exchangeCredentialsSection: some View {
        Section {
            SecureField("API Key", text: $viewModel.apiKey)
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityLabel("API Key")

            SecureField("API Secret", text: $viewModel.apiSecret)
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .accessibilityLabel("API Secret")
        } header: {
            Text("API Credentials")
        } footer: {
            Text("Use read-only API keys. LegacyVault never needs trading permissions. Your keys are encrypted and stored in the iOS Keychain.")
        }
    }

    // MARK: - Wallet Address

    private var walletAddressSection: some View {
        Section {
            TextField("Wallet Address", text: $viewModel.walletAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(.body, design: .monospaced))
                .accessibilityLabel("Wallet address")
        } header: {
            Text("Wallet Address")
        } footer: {
            Text("Enter your public wallet address. LegacyVault only monitors balances — no private keys are stored.")
        }
    }

    // MARK: - Security Notice

    private var securityNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.title2)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text("Secure Storage")
                    .font(.subheadline.weight(.medium))
                Text("Credentials are encrypted using the iOS Keychain and never leave your device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var isFormIncomplete: Bool {
        if viewModel.selectedPlatform.isExchange {
            return viewModel.apiKey.isEmpty
        } else {
            return viewModel.walletAddress.isEmpty
        }
    }
}
