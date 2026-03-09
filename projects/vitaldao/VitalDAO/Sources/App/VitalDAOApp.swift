import SwiftUI

@main
struct VitalDAOApp: App {
    @State private var service = WearableAggregatorService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(service)
                .preferredColorScheme(.dark)
        }
    }
}
