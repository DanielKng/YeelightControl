import Foundation
import SwiftUI
import Combine

/// Container for all services used in the app
@MainActor
public final class ServiceContainer {
    /// Shared instance of the service container
    public static let shared = ServiceContainer()
    
    // MARK: - Properties
    private var services: [String: Any] = [:]
    
    // MARK: - Core Services
    
    /// Logger service for app-wide logging
    public private(set) var logger: UnifiedLogger
    
    /// Network manager for handling all network operations
    public private(set) var networkManager: UnifiedNetworkManager
    
    /// Yeelight device manager
    public private(set) var yeelightManager: UnifiedYeelightManager
    
    /// Background task manager
    public private(set) var backgroundManager: UnifiedBackgroundManager
    
    /// Effect manager for visual effects
    public private(set) var effectManager: UnifiedEffectManager
    
    // MARK: - Services
    public private(set) var storage: StorageManaging
    public private(set) var config: ConfigurationManaging
    public private(set) var errorHandler: ErrorHandling
    public private(set) var connectionManager: ConnectionManaging
    public private(set) var stateManager: StateManaging
    public private(set) var deviceManager: DeviceManaging
    public private(set) var roomManager: RoomManaging
    public private(set) var automationManager: AutomationManaging
    public private(set) var locationManager: LocationManaging
    public private(set) var themeManager: ThemeManaging
    public private(set) var sceneManager: SceneManaging
    public private(set) var analyticsManager: AnalyticsManaging
    public private(set) var notificationManager: NotificationManaging
    public private(set) var permissionManager: PermissionManaging
    public private(set) var securityManager: SecurityManaging
    
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
        Task {
            // Setup core service observers
            await networkManager.startMonitoring()
            
            // Setup location and permission observers
            await locationManager.startMonitoring()
            await permissionManager.checkPermissions()
            
            // Setup notification observers
            await notificationManager.registerForNotifications()
            
            // Setup background task observers
            await backgroundManager.setupBackgroundTasks()
        }
    }
    
    // MARK: - Service Registration
    public nonisolated func register<T>(_ service: T) {
        let key = String(describing: T.self)
        services[key] = service
    }
    
    public nonisolated func get<T>() -> T? {
        let key = String(describing: T.self)
        return services[key] as? T
    }
    
    public nonisolated func remove<T>(_ type: T.Type) {
        let key = String(describing: T.self)
        services.removeValue(forKey: key)
    }
    
    public nonisolated func removeAll() {
        services.removeAll()
    }
}

// MARK: - Service Protocol
@preconcurrency protocol Service: Actor {
    func start() async throws
    func stop() async
}

// MARK: - Service Types
public extension ServiceContainer {
    nonisolated func registerLogger(_ logger: UnifiedLogger) {
        register(logger)
    }
    
    nonisolated func registerNetworkManager(_ manager: UnifiedNetworkManager) {
        register(manager)
    }
    
    nonisolated func registerConfigurationManager(_ manager: ConfigurationManaging) {
        register(manager)
    }
    
    nonisolated func registerConnectionManager(_ manager: ConnectionManaging) {
        register(manager)
    }
    
    nonisolated func registerDeviceManager(_ manager: DeviceManaging) {
        register(manager)
    }
    
    nonisolated func registerRoomManager(_ manager: RoomManaging) {
        register(manager)
    }
    
    nonisolated func registerAutomationManager(_ manager: AutomationManaging) {
        register(manager)
    }
    
    nonisolated func registerThemeManager(_ manager: ThemeManaging) {
        register(manager)
    }
    
    nonisolated func registerErrorHandler(_ handler: ErrorHandling) {
        register(handler)
    }
    
    nonisolated func registerStateManager(_ manager: StateManaging) {
        register(manager)
    }
    
    nonisolated func registerLocationManager(_ manager: LocationManaging) {
        register(manager)
    }
    
    nonisolated func registerSceneManager(_ manager: SceneManaging) {
        register(manager)
    }
    
    nonisolated func registerEffectManager(_ manager: EffectManaging) {
        register(manager)
    }
    
    nonisolated func registerAnalyticsManager(_ manager: AnalyticsManaging) {
        register(manager)
    }
    
    nonisolated func registerNotificationManager(_ manager: NotificationManaging) {
        register(manager)
    }
    
    nonisolated func registerPermissionManager(_ manager: PermissionManaging) {
        register(manager)
    }
    
    nonisolated func registerSecurityManager(_ manager: SecurityManaging) {
        register(manager)
    }
}

// MARK: - Service Retrieval Extensions
public extension ServiceContainer {
    var logger: UnifiedLogger {
        guard let logger: UnifiedLogger = get() else {
            fatalError("Logger not registered")
        }
        return logger
    }
    
    var networkManager: UnifiedNetworkManager {
        guard let manager: UnifiedNetworkManager = get() else {
            fatalError("NetworkManager not registered")
        }
        return manager
    }
    
    var configurationManager: ConfigurationManaging {
        guard let manager: ConfigurationManaging = get() else {
            fatalError("ConfigurationManager not registered")
        }
        return manager
    }
    
    var connectionManager: ConnectionManaging {
        guard let manager: ConnectionManaging = get() else {
            fatalError("ConnectionManager not registered")
        }
        return manager
    }
    
    var deviceManager: DeviceManaging {
        guard let manager: DeviceManaging = get() else {
            fatalError("DeviceManager not registered")
        }
        return manager
    }
    
    var roomManager: RoomManaging {
        guard let manager: RoomManaging = get() else {
            fatalError("RoomManager not registered")
        }
        return manager
    }
    
    var automationManager: AutomationManaging {
        guard let manager: AutomationManaging = get() else {
            fatalError("AutomationManager not registered")
        }
        return manager
    }
    
    var themeManager: ThemeManaging {
        guard let manager: ThemeManaging = get() else {
            fatalError("ThemeManager not registered")
        }
        return manager
    }
}

// MARK: - SwiftUI View Extension
extension View {
    /// Access to the shared service container
    var services: ServiceContainer {
        ServiceContainer.shared
    }
} 