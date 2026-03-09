import SwiftUI

struct AccountsListView: View {
    @State private var viewModel = AccountsViewModel()
    @Environment(StoreManager.self) private var storeManager
    @State private var showingAddAccount = false

    var body: some View {
        List {
            if viewModel.accounts.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No Accounts",
                    systemImage: "link.badge.plus",
                    description: Text("Connect your exchange accounts and wallets to start monitoring your crypto estate.")
                )
            }

            ForEach(viewModel.accounts) { account in
                NavigationLink {
                    AccountDetailView(account: account)
                } label: {
                    accountRow(account)
                }
            }
            .onDelete { offsets in
                Task { await viewModel.removeAccount(at: offsets) }
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddAccount = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add account")
            }
        }
        .sheet(isPresented: $showingAddAccount) {
            AccountConnectionView()
        }
        .refreshable {
            await viewModel.loadAccounts()
        }
        .task {
            await viewModel.loadAccounts()
        }
        .overlay {
            if viewModel.isLoading && viewModel.accounts.isEmpty {
                ProgressView("Loading accounts...")
            }
        }
    }

    private func accountRow(_ account: Account) -> some View {
        HStack(spacing: 12) {
            Image(systemName: account.platform.iconSystemName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.nickname)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text(account.platform.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let error = account.connectionError {
                        Text("(\(error))")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(account.totalValueUSD, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 4) {
                    Circle()
                        .fill(dormancyColor(account.dormancyStatus))
                        .frame(width: 6, height: 6)
                    Text(account.dormancyStatus.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func dormancyColor(_ status: DormancyStatus) -> Color {
        switch status {
        case .active: return .green
        case .warning: return .yellow
        case .dormant: return .red
        case .unknown: return .gray
        }
    }
}
