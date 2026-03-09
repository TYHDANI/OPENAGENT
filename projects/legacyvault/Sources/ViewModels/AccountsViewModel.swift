import Foundation

@Observable
final class AccountsViewModel {
    var accounts: [Account] = []
    var isLoading = false
    var errorMessage: String?
    var showingAddAccount = false

    // Add account form state
    var selectedPlatform: ExchangePlatform = .coinbase
    var accountNickname = ""
    var apiKey = ""
    var apiSecret = ""
    var walletAddress = ""

    private let persistence = PersistenceService.shared

    func loadAccounts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            accounts = try await persistence.loadAccounts()
        } catch {
            errorMessage = "Failed to load accounts: \(error.localizedDescription)"
        }
    }

    func addAccount() async -> Bool {
        let connectionType: AccountConnectionType
        let keychainRef = "account-\(UUID().uuidString)"

        if selectedPlatform.isExchange {
            connectionType = .apiKey
            guard !apiKey.isEmpty else {
                errorMessage = "API key is required"
                return false
            }
            do {
                let credentials = apiSecret.isEmpty ? apiKey : "\(apiKey):\(apiSecret)"
                try KeychainService.save(credentials, forKey: keychainRef)
            } catch {
                errorMessage = "Failed to store credentials securely"
                return false
            }
        } else {
            connectionType = .walletAddress
            guard !walletAddress.isEmpty else {
                errorMessage = "Wallet address is required"
                return false
            }
            do {
                try KeychainService.save(walletAddress, forKey: keychainRef)
            } catch {
                errorMessage = "Failed to store wallet address"
                return false
            }
        }

        let account = Account(
            platform: selectedPlatform,
            nickname: accountNickname.isEmpty ? selectedPlatform.displayName : accountNickname,
            connectionType: connectionType,
            keychainReference: keychainRef,
            isConnected: true
        )

        accounts.append(account)

        do {
            try await persistence.saveAccounts(accounts)
            resetForm()
            return true
        } catch {
            errorMessage = "Failed to save account"
            accounts.removeLast()
            return false
        }
    }

    func removeAccount(at offsets: IndexSet) async {
        let removedAccounts = offsets.map { accounts[$0] }
        accounts.remove(atOffsets: offsets)

        for account in removedAccounts {
            try? KeychainService.delete(forKey: account.keychainReference)
        }

        do {
            try await persistence.saveAccounts(accounts)
        } catch {
            errorMessage = "Failed to save changes"
        }
    }

    func removeAccount(_ account: Account) async {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        try? KeychainService.delete(forKey: account.keychainReference)
        accounts.remove(at: index)

        do {
            try await persistence.saveAccounts(accounts)
        } catch {
            errorMessage = "Failed to save changes"
        }
    }

    private func resetForm() {
        selectedPlatform = .coinbase
        accountNickname = ""
        apiKey = ""
        apiSecret = ""
        walletAddress = ""
        showingAddAccount = false
    }
}
