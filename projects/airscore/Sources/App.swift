import SwiftUI

@main
struct AirScoreApp: App {
    @State private var storeManager = StoreManager()
    @State private var airService = AirQualityService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
                .environment(airService)
                .preferredColorScheme(.dark)
        }
    }
}
