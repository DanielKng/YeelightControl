import SwiftUI
import Core

@main
struct YeelightControlApp: App {
    @StateObject private var services = ServiceContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(services)
                .environmentObject(services.deviceManager)
                .environmentObject(services.networkManager)
                .environmentObject(services.storageManager)
                .environmentObject(services.stateManager)
                .environmentObject(services.sceneManager)
                .environmentObject(services.effectManager)
                .environmentObject(services.backgroundManager)
                .environmentObject(services.notificationManager)
                .environmentObject(services.permissionManager)
                .environmentObject(services.analyticsManager)
                .environmentObject(services.securityManager)
                .environmentObject(services.errorManager)
                .environmentObject(services.logger)
        }
    }
}
