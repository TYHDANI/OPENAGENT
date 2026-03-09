import SwiftUI

struct TransactionListView: View {
    @Environment(EntityViewModel.self) private var entityVM
    @Environment(TransactionViewModel.self) private var transactionVM
    @State private var showAddTransaction = false

    var body: some View {
        NavigationStack {
            Group {
                if transactionVM.filteredTransactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "arrow.left.arrow.right.circle",
                        description: Text("Add transactions manually or connect an exchange account.")
                    )
                } else {
                    List {
                        filterSection

                        ForEach(transactionVM.filteredTransactions) { tx in
                            TransactionRowView(transaction: tx)
                        }
                        .onDelete { indexSet in
                            Task {
                                let txs = transactionVM.filteredTransactions
                                for index in indexSet {
                                    await transactionVM.deleteTransaction(txs[index])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add transaction")
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionSheet()
            }
            .task {
                await transactionVM.load()
            }
        }
    }

    @ViewBuilder
    private var filterSection: some View {
        @Bindable var vm = transactionVM
        Section("Filters") {
            Picker("Entity", selection: $vm.filterEntityID) {
                Text("All Entities").tag(nil as UUID?)
                ForEach(entityVM.entities) { entity in
                    Text(entity.name).tag(entity.id as UUID?)
                }
            }
            Picker("Asset", selection: $vm.filterAsset) {
                Text("All Assets").tag(nil as String?)
                ForEach(transactionVM.uniqueAssets, id: \.self) { asset in
                    Text(asset).tag(asset as String?)
                }
            }
            Picker("Type", selection: $vm.filterType) {
                Text("All Types").tag(nil as TransactionType?)
                ForEach(TransactionType.allCases) { type in
                    Text(type.rawValue).tag(type as TransactionType?)
                }
            }
        }
    }
}

struct AddTransactionSheet: View {
    @Environment(EntityViewModel.self) private var entityVM
    @Environment(TransactionViewModel.self) private var transactionVM
    @Environment(\.dismiss) private var dismiss

    @State private var selectedEntityID: UUID?
    @State private var selectedAccountID: UUID?
    @State private var transactionType: TransactionType = .buy
    @State private var asset = "BTC"
    @State private var quantity = ""
    @State private var pricePerUnit = ""
    @State private var fee = ""
    @State private var date = Date()
    @State private var notes = ""

    private var entityAccounts: [CustodialAccount] {
        guard let entityID = selectedEntityID else { return [] }
        return entityVM.accounts(for: entityID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Entity & Account") {
                    Picker("Entity", selection: $selectedEntityID) {
                        Text("Select Entity").tag(nil as UUID?)
                        ForEach(entityVM.entities) { entity in
                            Text(entity.name).tag(entity.id as UUID?)
                        }
                    }
                    Picker("Account", selection: $selectedAccountID) {
                        Text("Select Account").tag(nil as UUID?)
                        ForEach(entityAccounts) { account in
                            Text(account.accountName).tag(account.id as UUID?)
                        }
                    }
                }

                Section("Transaction Details") {
                    Picker("Type", selection: $transactionType) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Asset (e.g., BTC)", text: $asset)
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                    TextField("Price per Unit (USD)", text: $pricePerUnit)
                        .keyboardType(.decimalPad)
                    TextField("Fee (USD)", text: $fee)
                        .keyboardType(.decimalPad)
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let entityID = selectedEntityID,
                              let accountID = selectedAccountID,
                              let qty = Double(quantity),
                              let price = Double(pricePerUnit) else { return }

                        let tx = CryptoTransaction(
                            accountID: accountID,
                            entityID: entityID,
                            transactionType: transactionType,
                            asset: asset.uppercased(),
                            quantity: qty,
                            pricePerUnit: price,
                            fee: Double(fee) ?? 0,
                            date: date,
                            notes: notes
                        )

                        Task {
                            await transactionVM.addTransaction(tx, entities: entityVM.entities)
                            dismiss()
                        }
                    }
                    .disabled(selectedEntityID == nil || selectedAccountID == nil || quantity.isEmpty || pricePerUnit.isEmpty)
                }
            }
        }
    }
}
