import Foundation

/// Central container for all app services
final class ServiceContainer {
    // MARK: - Shared Instance
    static let shared = ServiceContainer()
    
    // MARK: - Services
    let storage: StorageManaging
    let config: ConfigurationManaging
    let errorHandler: ErrorHandling
    let networkManager: UnifiedNetworkManager
    let connectionManager: ConnectionManaging
    let stateManager: StateManaging
    let effectManager: EffectManaging
    let deviceManager: DeviceManaging
    let logger: UnifiedLogger
    let roomManager: RoomManaging
    let automationManager: AutomationManaging
    let backgroundManager: BackgroundManaging
    let locationManager: LocationManaging
    let themeManager: ThemeManaging
    let sceneManager: SceneManaging
    let analyticsManager: AnalyticsManaging
    let notificationManager: NotificationManaging
    let permissionManager: PermissionManaging
    let securityManager: SecurityManaging
    
    // MARK: - Initialization
    private init() {
        // Initialize core services
        storage = UnifiedStorageManager()
        config = UnifiedConfigurationManager(storage: storage)
        logger = UnifiedLogger()
        errorHandler = UnifiedErrorHandler(storage: storage)
        
        // Initialize network services
        networkManager = UnifiedNetworkManager()
        connectionManager = UnifiedConnectionManager()
        
        // Initialize state and device services
        stateManager = UnifiedStateManager(connectionManager: connectionManager)
        deviceManager = UnifiedDeviceManager(services: .shared)
        effectManager = UnifiedEffectManager(services: .shared)
        
        // Initialize room management
        roomManager = UnifiedRoomManager(services: .shared)
        
        // Initialize automation management
        automationManager = UnifiedAutomationManager(services: .shared)
        
        // Initialize background management
        backgroundManager = UnifiedBackgroundManager(services: .shared)
        
        // Initialize location management
        locationManager = UnifiedLocationManager()
        
        // Initialize theme management
        themeManager = UnifiedThemeManager(services: .shared)
        
        // Initialize scene management
        sceneManager = UnifiedSceneManager(services: .shared)
        
        // Initialize analytics
        analyticsManager = UnifiedAnalyticsManager(services: .shared)
        
        // Initialize notification management
        notificationManager = UnifiedNotificationManager(services: .shared)
        
        // Initialize permission management
        permissionManager = UnifiedPermissionManager(services: .shared)
        
        // Initialize security management
        securityManager = UnifiedSecurityManager(services: .shared)
    }
}

// MARK: - View Controller Extension
extension UIViewController {
    /// Access to service container
    var services: ServiceContainer {
        .shared
    }
}

// MARK: - View Extension
extension View {
    /// Access to service container
    var services: ServiceContainer {
        .shared
    }
} 