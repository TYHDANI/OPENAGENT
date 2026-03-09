import SwiftUI
import StoreKit

@main
struct TreasuryPilotApp: App {
    @State private var storeManager = StoreManager()
    @State private var entityVM = EntityViewModel()
    @State private var transactionVM = TransactionViewModel()
    @State private var taxVM = TaxViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
                .environment(entityVM)
                .environment(transactionVM)
                .environment(taxVM)
                .task {
                    await storeManager.loadProducts()
                    await storeManager.checkSubscriptionStatus()
                    storeManager.listenForTransactions()
                    await entityVM.load()
                    await transactionVM.load()
                    await taxVM.load()
                }
        }
    }
}
