import SwiftUI
import Core
import UI

struct ContentView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    var body: some View {
        MainView()
            .environmentObject(serviceContainer.deviceManager)
            .environmentObject(serviceContainer.sceneManager)
            .environmentObject(serviceContainer.effectManager)
            .environmentObject(serviceContainer.networkManager)
            .environmentObject(serviceContainer.storageManager)
            .environmentObject(serviceContainer.configManager)
            .environmentObject(serviceContainer.notificationManager)
            .environmentObject(serviceContainer.permissionManager)
            .environmentObject(serviceContainer.analyticsManager)
            .environmentObject(serviceContainer.securityManager)
            .environmentObject(serviceContainer.errorManager)
            .environmentObject(serviceContainer.logger)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ServiceContainer.shared)
    }
}
