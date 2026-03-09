import SwiftUI

@main
struct VaultOSApp: App {
    @State private var storeManager = StoreManager()
    @State private var persistence = PersistenceService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
                .environment(persistence)
                .preferredColorScheme(.dark)
        }
    }
}
