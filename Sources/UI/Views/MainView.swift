import SwiftUI
import Combine
import Network

/// Main tab-based navigation view for the application
/// Provides access to all major features through a tab interface
struct MainView: View {
    // MARK: - Environment Objects
    
    // Core Device Management
    @EnvironmentObject private var yeelightManager: UnifiedYeelightManager
    @EnvironmentObject private var deviceManager: UnifiedDeviceManager
    
    // Feature Management
    @EnvironmentObject private var effectManager: UnifiedEffectManager
    @EnvironmentObject private var sceneManager: UnifiedSceneManager
    @EnvironmentObject private var automationManager: UnifiedAutomationManager
    @EnvironmentObject private var roomManager: UnifiedRoomManager
    
    // Core Services
    @EnvironmentObject private var networkManager: UnifiedNetworkManager
    @EnvironmentObject private var storageManager: UnifiedStorageManager
    @EnvironmentObject private var backgroundManager: UnifiedBackgroundManager
    @EnvironmentObject private var notificationManager: UnifiedNotificationManager
    @EnvironmentObject private var locationManager: UnifiedLocationManager
    @EnvironmentObject private var permissionManager: UnifiedPermissionManager
    @EnvironmentObject private var analyticsManager: UnifiedAnalyticsManager
    @EnvironmentObject private var configurationManager: UnifiedConfigurationManager
    @EnvironmentObject private var stateManager: UnifiedStateManager
    @EnvironmentObject private var securityManager: UnifiedSecurityManager
    @EnvironmentObject private var errorManager: UnifiedErrorManager
    @EnvironmentObject private var themeManager: UnifiedThemeManager
    @EnvironmentObject private var connectionManager: UnifiedConnectionManager
    @EnvironmentObject private var logger: UnifiedLogger
    
    // MARK: - State
    
    @AppStorage("selectedTab") private var selectedTab = Tab.lights
    @State private var showingPermissionAlert = false
    @State private var showingErrorAlert = false
    @State private var showingSecurityAlert = false
    @State private var showingRetryAlert = false
    @State private var alertMessage: String?
    @State private var isInitializing = true
    @State private var isOffline = false
    @State private var initializationProgress: Double = 0
    
    // MARK: - Navigation State
    @State private var showingDeviceSetup = false
    @State private var showingNetworkDiagnostics = false
    @State private var showingAdvancedSettings = false
    @State private var showingHelp = false
    @State private var selectedDevice: UnifiedYeelightDevice?
    @State private var selectedScene: Scene?
    @State private var selectedEffect: Effect?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Types
    
    enum Tab {
        case lights, scenes, automation, effects, settings
        
        var title: String {
            switch self {
            case .lights: return "Lights"
            case .scenes: return "Scenes"
            case .automation: return "Automation"
            case .effects: return "Effects"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .lights: return "lightbulb.fill"
            case .scenes: return "theatermasks.fill"
            case .automation: return "timer"
            case .effects: return "waveform.path.ecg"
            case .settings: return "gear"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isInitializing {
                splashScreen
            } else {
                mainContent
            }
        }
        .onChange(of: errorManager.currentError) { error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingErrorAlert = true
            }
        }
        .onChange(of: securityManager.securityAlert) { alert in
            if let alert = alert {
                alertMessage = alert
                showingSecurityAlert = true
            }
        }
        .onChange(of: networkManager.isConnected) { isConnected in
            isOffline = !isConnected
        }
        .alert("Network Unavailable", isPresented: .constant(isOffline)) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please check your network connection.")
        }
        .alert("Initialization Failed", isPresented: $showingRetryAlert) {
            Button("Retry", role: .none) {
                initializeApp()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(alertMessage ?? "Failed to initialize the app. Would you like to retry?")
        }
        .task {
            setupNetworkMonitoring()
        }
        .sheet(isPresented: $showingDeviceSetup) {
            DeviceSetupView()
                .environmentObject(yeelightManager)
                .environmentObject(deviceManager)
                .environmentObject(networkManager)
                .environmentObject(stateManager)
        }
        .sheet(isPresented: $showingNetworkDiagnostics) {
            NetworkDiagnosticsView()
                .environmentObject(networkManager)
                .environmentObject(connectionManager)
        }
        .sheet(isPresented: $showingAdvancedSettings) {
            AdvancedSettingsView()
                .environmentObject(configurationManager)
                .environmentObject(storageManager)
                .environmentObject(securityManager)
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }
    
    private var splashScreen: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            if isOffline {
                Text("Waiting for network connection...")
                    .foregroundColor(.secondary)
            }
            VStack(spacing: 8) {
                ProgressView(value: initializationProgress, total: 1.0)
                Text("\(Int(initializationProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 200)
        }
        .onAppear {
            initializeApp()
        }
    }
    
    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LightsView()
                    .environmentObject(yeelightManager)
                    .environmentObject(deviceManager)
                    .environmentObject(roomManager)
                    .environmentObject(networkManager)
                    .environmentObject(stateManager)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingDeviceSetup = true }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .tabItem {
                Label(Tab.lights.title, systemImage: Tab.lights.icon)
            }
            .tag(Tab.lights)
            
            NavigationStack {
                SceneListView()
                    .environmentObject(sceneManager)
                    .environmentObject(yeelightManager)
                    .environmentObject(deviceManager)
                    .environmentObject(roomManager)
                    .environmentObject(stateManager)
                    .sheet(item: $selectedScene) { scene in
                        ScenePreview(scene: scene)
                            .environmentObject(sceneManager)
                            .environmentObject(yeelightManager)
                    }
            }
            .tabItem {
                Label(Tab.scenes.title, systemImage: Tab.scenes.icon)
            }
            .tag(Tab.scenes)
            
            NavigationStack {
                AutomationView()
                    .environmentObject(automationManager)
                    .environmentObject(yeelightManager)
                    .environmentObject(sceneManager)
                    .environmentObject(locationManager)
                    .environmentObject(stateManager)
                    .sheet(isPresented: $showingLocationPicker) {
                        LocationPicker()
                            .environmentObject(locationManager)
                    }
            }
            .tabItem {
                Label(Tab.automation.title, systemImage: Tab.automation.icon)
            }
            .tag(Tab.automation)
            
            NavigationStack {
                EffectsListView()
                    .environmentObject(effectManager)
                    .environmentObject(yeelightManager)
                    .environmentObject(deviceManager)
                    .environmentObject(stateManager)
                    .sheet(item: $selectedEffect) { effect in
                        FlowEffectEditor(effect: effect)
                            .environmentObject(effectManager)
                            .environmentObject(yeelightManager)
                    }
            }
            .tabItem {
                Label(Tab.effects.title, systemImage: Tab.effects.icon)
            }
            .tag(Tab.effects)
            
            NavigationStack {
                SettingsView()
                    .environmentObject(yeelightManager)
                    .environmentObject(deviceManager)
                    .environmentObject(roomManager)
                    .environmentObject(networkManager)
                    .environmentObject(storageManager)
                    .environmentObject(backgroundManager)
                    .environmentObject(notificationManager)
                    .environmentObject(locationManager)
                    .environmentObject(permissionManager)
                    .environmentObject(analyticsManager)
                    .environmentObject(configurationManager)
                    .environmentObject(stateManager)
                    .environmentObject(securityManager)
                    .environmentObject(themeManager)
                    .environmentObject(connectionManager)
                    .environmentObject(logger)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button(action: { showingAdvancedSettings = true }) {
                                    Label("Advanced Settings", systemImage: "gear")
                                }
                                Button(action: { showingNetworkDiagnostics = true }) {
                                    Label("Network Diagnostics", systemImage: "network")
                                }
                                Button(action: { showingHelp = true }) {
                                    Label("Help", systemImage: "questionmark.circle")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
            }
            .tabItem {
                Label(Tab.settings.title, systemImage: Tab.settings.icon)
            }
            .tag(Tab.settings)
        }
        .alert("Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings", role: .none) {
                permissionManager.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(alertMessage ?? "Please grant the required permissions to use this app.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {
                errorManager.clearError()
            }
        } message: {
            Text(alertMessage ?? "An unknown error occurred.")
        }
        .alert("Security Alert", isPresented: $showingSecurityAlert) {
            Button("Settings", role: .none) {
                securityManager.openSecuritySettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(alertMessage ?? "Please review your security settings.")
        }
    }
    
    // MARK: - Private Methods
    
    private func initializeApp() {
        Task {
            do {
                // Initialize logger first
                logger.startLogging()
                updateProgress(0.1)
                
                // Initialize security
                try await securityManager.initialize()
                updateProgress(0.2)
                
                // Check and request permissions
                try await permissionManager.checkAndRequestPermissions()
                updateProgress(0.3)
                
                // Initialize state management
                try await stateManager.initialize()
                updateProgress(0.4)
                
                // Initialize core services
                try await networkManager.initialize()
                try await connectionManager.initialize()
                updateProgress(0.5)
                
                // Initialize location and notifications
                try await locationManager.startMonitoring()
                try await notificationManager.registerForNotifications()
                updateProgress(0.6)
                
                // Initialize analytics and theme
                try await analyticsManager.startSession()
                themeManager.applyTheme()
                updateProgress(0.7)
                
                // Start device discovery
                try await yeelightManager.startDiscovery()
                updateProgress(0.8)
                
                // Initialize background tasks
                try await backgroundManager.startBackgroundTasks()
                updateProgress(0.9)
                
                // Load saved data
                try await storageManager.loadSavedState()
                updateProgress(1.0)
                
                // Update UI state
                withAnimation {
                    isInitializing = false
                }
            } catch {
                errorManager.handle(error)
                alertMessage = error.localizedDescription
                showingRetryAlert = true
            }
        }
    }
    
    private func updateProgress(_ value: Double) {
        withAnimation {
            initializationProgress = value
        }
    }
    
    private func setupNetworkMonitoring() {
        networkManager.connectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { isConnected in
                isOffline = !isConnected
                if isConnected && isInitializing {
                    initializeApp()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Preview

#Preview {
    MainView()
        // Core Device Management
        .environmentObject(ServiceContainer.shared.yeelightManager)
        .environmentObject(ServiceContainer.shared.deviceManager)
        
        // Feature Management
        .environmentObject(ServiceContainer.shared.effectManager)
        .environmentObject(ServiceContainer.shared.sceneManager)
        .environmentObject(ServiceContainer.shared.automationManager)
        .environmentObject(ServiceContainer.shared.roomManager)
        
        // Core Services
        .environmentObject(ServiceContainer.shared.networkManager)
        .environmentObject(ServiceContainer.shared.storageManager)
        .environmentObject(ServiceContainer.shared.backgroundManager)
        .environmentObject(ServiceContainer.shared.notificationManager)
        .environmentObject(ServiceContainer.shared.locationManager)
        .environmentObject(ServiceContainer.shared.permissionManager)
        .environmentObject(ServiceContainer.shared.analyticsManager)
        .environmentObject(ServiceContainer.shared.configurationManager)
        .environmentObject(ServiceContainer.shared.stateManager)
        .environmentObject(ServiceContainer.shared.securityManager)
        .environmentObject(ServiceContainer.shared.errorManager)
        .environmentObject(ServiceContainer.shared.themeManager)
        .environmentObject(ServiceContainer.shared.connectionManager)
        .environmentObject(ServiceContainer.shared.logger)
} 