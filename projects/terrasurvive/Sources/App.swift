import SwiftUI

// MARK: - TerraSurvive App

@main
struct TerraSurviveApp: App {
    @State private var survivalService = SurvivalService()
    @State private var storeManager = StoreManager()
    @State private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(survivalService)
                .environment(storeManager)
                .environment(locationManager)
                .preferredColorScheme(.dark)
        }
    }
}
