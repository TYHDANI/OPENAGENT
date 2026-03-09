import SwiftUI

@main
struct GridStackApp: App {
    @State private var energyService = EnergyService()
    @State private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(energyService)
                .environment(storeManager)
                .preferredColorScheme(.dark)
        }
    }
}
