import SwiftUI
import StoreKit

@main
struct LegacyVaultApp: App {
    @State private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
                .task {
                    await storeManager.loadProducts()
                    await storeManager.checkSubscriptionStatus()
                    storeManager.listenForTransactions()
                }
        }
    }
}
