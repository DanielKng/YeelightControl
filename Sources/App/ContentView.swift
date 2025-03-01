i; ; ; ; mport SwiftUI
i; ; ; ; mport Core
i; ; ; ; mport UI

s; ; ; ; truct ContentView: View {
    @; ; ; ; EnvironmentObject var serviceContainer: BaseServiceContainer
    
 ; ; ; ; var body:; ; ; ; some View {
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

s; ; ; ; truct ContentView_Previews: PreviewProvider {
 ; ; ; ; static var previews:; ; ; ; some View {
        ContentView()
            .environmentObject(ServiceContainer.shared)
    }
}
