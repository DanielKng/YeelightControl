import Foundation
import SwiftUI
import Combine

/// Container for all services used in the app
@MainActor
public final class ServiceContainer: ObservableObject {
    /// Shared instance of the service container
    public static let shared = ServiceContainer()
    
    // MARK: - Core Services
    
    /// Logger service for app-wide logging
    @Published private(set) var logger: UnifiedLogger
    
    /// Network manager for handling all network operations
    @Published private(set) var networkManager: UnifiedNetworkManager
    
    /// Yeelight device manager
    @Published private(set) var yeelightManager: UnifiedYeelightManager
    
    /// Background task manager
    @Published private(set) var backgroundManager: UnifiedBackgroundManager
    
    /// Effect manager for visual effects
    @Published private(set) var effectManager: UnifiedEffectManager
    
    // MARK: - Services
    @Published private(set) var storageManager: UnifiedStorageManager
    @Published private(set) var configManager: UnifiedConfigurationManager
    @Published private(set) var errorManager: UnifiedErrorHandler
    @Published private(set) var connectionManager: UnifiedConnectionManager
    @Published private(set) var stateManager: UnifiedStateManager
    @Published private(set) var deviceManager: UnifiedDeviceManager
    @Published private(set) var roomManager: UnifiedRoomManager
    @Published private(set) var automationManager: UnifiedAutomationManager
    @Published private(set) var locationManager: UnifiedLocationManager
    @Published private(set) var themeManager: UnifiedThemeManager
    @Published private(set) var sceneManager: UnifiedSceneManager
    @Published private(set) var notificationManager: UnifiedNotificationManager
    @Published private(set) var permissionManager: UnifiedPermissionManager
    @Published private(set) var securityManager: UnifiedSecurityManager
    @Published private(set) var analyticsManager: UnifiedAnalyticsManager
    
    // MARK: - Initialization
    
    private init() {
        // Initialize core services
        storageManager = UnifiedStorageManager.shared
        networkManager = UnifiedNetworkManager.shared
        stateManager = UnifiedStateManager.shared
        deviceManager = UnifiedDeviceManager.shared
        sceneManager = UnifiedSceneManager.shared
        effectManager = UnifiedEffectManager.shared
        backgroundManager = UnifiedBackgroundManager.shared
        notificationManager = UnifiedNotificationManager.shared
        permissionManager = UnifiedPermissionManager.shared
        analyticsManager = UnifiedAnalyticsManager.shared
        securityManager = UnifiedSecurityManager.shared
        errorManager = UnifiedErrorHandler.shared
        
        // Setup dependencies
        networkManager.messageHandler = deviceManager
        deviceManager.stateManager = stateManager
        deviceManager.networkManager = networkManager
        deviceManager.storageManager = storageManager
        
        sceneManager.deviceManager = deviceManager
        sceneManager.storageManager = storageManager
        
        effectManager.deviceManager = deviceManager
        effectManager.storageManager = storageManager
        
        backgroundManager.deviceManager = deviceManager
        backgroundManager.sceneManager = sceneManager
        backgroundManager.effectManager = effectManager
        
        notificationManager.deviceManager = deviceManager
        notificationManager.sceneManager = sceneManager
        
        errorManager.storageManager = storageManager
        
        // Initialize state management
        self.stateManager = UnifiedStateManager(services: self)
        
        // Initialize device managers that depend on network
        self.yeelightManager = UnifiedYeelightManager(services: self)
        self.connectionManager = UnifiedConnectionManager(services: self)
        
        // Initialize location and permission services
        self.locationManager = UnifiedLocationManager(services: self)
        
        // Initialize feature managers
        self.roomManager = UnifiedRoomManager(services: self)
        self.automationManager = UnifiedAutomationManager(services: self)
        self.themeManager = UnifiedThemeManager(services: self)
        
        // Initialize config manager
        self.configManager = UnifiedConfigurationManager(storageManager: storageManager)
        
        setupObservers()
    }
    
    private func setupObservers() {
        // Setup core service observers
        networkManager.startMonitoring()
        
        // Setup location and permission observers
        locationManager.startMonitoring()
        permissionManager.checkPermissions()
        
        // Setup notification observers
        notificationManager.registerForNotifications()
        
        // Setup background task observers
        backgroundManager.setupBackgroundTasks()
    }
}

// MARK: - SwiftUI View Extension
extension View {
    /// Access to the shared service container
    var services: ServiceContainer {
        ServiceContainer.shared
    }
} 