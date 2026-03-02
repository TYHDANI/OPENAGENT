import SwiftUI
import StoreKit

@main
struct DentiMatchApp: App {
    @State private var storeManager = StoreManager()
    @State private var dataManager = DataManager()
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
                .environment(dataManager)
                .environment(authManager)
                .task {
                    await storeManager.loadProducts()
                    await storeManager.checkSubscriptionStatus()
                    storeManager.listenForTransactions()
                    dataManager.initializeDataStore()
                }
        }
    }
}
