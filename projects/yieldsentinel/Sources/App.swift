import SwiftUI
import StoreKit

@main
struct YieldSentinelApp: App {
    @State private var storeManager = StoreManager()
    @State private var alertService = AlertService()

    var body: some Scene {
        WindowGroup {
            ContentView(alertService: alertService)
                .environment(storeManager)
                .task {
                    await storeManager.loadProducts()
                    await storeManager.checkSubscriptionStatus()
                    storeManager.listenForTransactions()
                    alertService.requestNotificationPermission()
                }
        }
    }
}
