import SwiftUI

@main
struct CP317_Application_App: App {
    // The HealthManager is initialized here so it's available early
    @StateObject private var healthManager = HealthManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager) // Make the manager available throughout the app
        }
    }
}
