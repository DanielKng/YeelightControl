import Foundation
import SwiftUI

/// Container for all services used in the app
final class ServiceContainer {
    /// Shared instance of the service container
    static let shared = ServiceContainer()
    
    // MARK: - Core Services
    
    /// Logger service for app-wide logging
    let logger: UnifiedLogger
    
    /// Network manager for handling all network operations
    let networkManager: UnifiedNetworkManager
    
    /// Yeelight device manager
    let yeelightManager: UnifiedYeelightManager
    
    /// Background task manager
    let backgroundManager: UnifiedBackgroundManager
    
    /// Effect manager for visual effects
    let effectManager: UnifiedEffectManager
    
    // MARK: - Services
    let storage: StorageManaging
    let config: ConfigurationManaging
    let errorHandler: ErrorHandling
    let connectionManager: ConnectionManaging
    let stateManager: StateManaging
    let deviceManager: DeviceManaging
    let roomManager: RoomManaging
    let automationManager: AutomationManaging
    let locationManager: LocationManaging
    let themeManager: ThemeManaging
    let sceneManager: SceneManaging
    let analyticsManager: AnalyticsManaging
    let notificationManager: NotificationManaging
    let permissionManager: PermissionManaging
    let securityManager: SecurityManaging
    
    // MARK: - Initialization
    
    private init() {
        // Initialize core services first
        self.storage = UnifiedStorageManager()
        self.config = UnifiedConfigurationManager(storage: self.storage)
        self.logger = UnifiedLogger(services: self)
        self.errorHandler = UnifiedErrorHandler(storage: self.storage)
        
        // Initialize network-dependent services
        self.networkManager = UnifiedNetworkManager(services: self)
        self.connectionManager = UnifiedConnectionManager(services: self)
        
        // Initialize state management
        self.stateManager = UnifiedStateManager(services: self)
        
        // Initialize device managers that depend on network
        self.yeelightManager = UnifiedYeelightManager(services: self)
        self.deviceManager = UnifiedDeviceManager(services: self)
        
        // Initialize location and permission services
        self.locationManager = UnifiedLocationManager(services: self)
        self.permissionManager = UnifiedPermissionManager(services: self)
        
        // Initialize feature managers
        self.roomManager = UnifiedRoomManager(services: self)
        self.automationManager = UnifiedAutomationManager(services: self)
        self.sceneManager = UnifiedSceneManager(services: self)
        
        // Initialize UI and background services
        self.backgroundManager = UnifiedBackgroundManager(services: self)
        self.effectManager = UnifiedEffectManager(services: self)
        self.themeManager = UnifiedThemeManager(services: self)
        
        // Initialize auxiliary services
        self.analyticsManager = UnifiedAnalyticsManager(services: self)
        self.notificationManager = UnifiedNotificationManager(services: self)
        self.securityManager = UnifiedSecurityManager(services: self)
        
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