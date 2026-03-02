import SwiftUI
import StoreKit

@main
struct MaterialSourceApp: App {
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
        .modelContainer(for: [
            Material.self,
            Supplier.self,
            Specification.self,
            MaterialProperty.self,
            RFQ.self,
            FavoriteMaterial.self,
            MaterialCollection.self
        ])
    }
}
