import Foundation
import Combine

/// A container for all the core services used throughout the app
open class BaseServiceContainer {
    // MARK: - Shared Instance
    public static let shared = BaseServiceContainer()
    
    // MARK: - Properties
    
    private let storageManager: UnifiedStorageManager
    
    // MARK: - Initialization
    
    public init() {
        self.storageManager = UnifiedStorageManager()
        
        // Initialize async properties
        Task {
            await initializeAsyncManagers()
        }
    }
    
    // MARK: - Async initialization
    
    private func initializeAsyncManagers() async {
        self._stateManager = await createStateManager()
        self._securityManager = await createSecurityManager()
        self._notificationManager = await createNotificationManager()
    }
    
    // MARK: - Async property creation methods
    
    private func createStateManager() async -> UnifiedStateManager {
        // Use Task to handle the async call
        let task = Task {
            return await UnifiedStateManager(services: self as! ServiceContainer)
        }
        return await task.value
    }
    
    private func createSecurityManager() async -> UnifiedSecurityManager {
        // Check if manager already exists
        if let manager = _securityManager {
            return manager
        }
        // Create a new manager with await since it's an async expression
        let manager = await UnifiedSecurityManager(services: self)
        _securityManager = manager
        return manager
    }
    
    private func createNotificationManager() async -> UnifiedNotificationManager {
        // Check if manager already exists
        if let manager = _notificationManager {
            return manager
        }
        // Create a new manager with await since it's an async expression
        let manager = await UnifiedNotificationManager()
        _notificationManager = manager
        return manager
    }
    
    // MARK: - Private properties for async managers
    private var _stateManager: UnifiedStateManager?
    private var _securityManager: UnifiedSecurityManager?
    private var _notificationManager: UnifiedNotificationManager?
    
    // MARK: - Lazy Managers
    
    lazy var logManager: UnifiedLogger = {
        return UnifiedLogger(storageManager: self.storageManager)
    }()
    
    lazy var themeManager: UnifiedThemeManager = {
        return UnifiedThemeManager(storageManager: self.storageManager as any Core_StorageManaging)
    }()
    
    lazy var permissionManager: UnifiedPermissionManager = {
        return UnifiedPermissionManager()
    }()
    
    lazy var deviceManager: UnifiedDeviceManager = {
        return UnifiedDeviceManager(storageManager: self.storageManager as any Core_StorageManaging)
    }()
    
    // Replace lazy properties with computed properties for async-initialized managers
    var stateManager: UnifiedStateManager {
        guard let manager = _stateManager else {
            fatalError("StateManager not initialized yet. Access this property after initialization is complete.")
        }
        return manager
    }
    
    lazy var sceneManager: UnifiedSceneManager = {
        return UnifiedSceneManager(
            storageManager: self.storageManager as any Core_StorageManaging,
            deviceManager: self.deviceManager as any Core_DeviceManaging,
            effectManager: self.effectManager as any Core_EffectManaging
        )
    }()
    
    lazy var effectManager: UnifiedEffectManager = {
        return UnifiedEffectManager(
            storageManager: self.storageManager as any Core_StorageManaging,
            deviceManager: self.deviceManager as any Core_DeviceManaging
        )
    }()
    
    lazy var configurationManager: UnifiedConfigurationManager = {
        return UnifiedConfigurationManager(storageManager: self.storageManager as any Core_StorageManaging)
    }()
    
    // Replace lazy property with computed property for async-initialized manager
    var securityManager: UnifiedSecurityManager {
        guard let manager = _securityManager else {
            fatalError("SecurityManager not initialized yet. Access this property after initialization is complete.")
        }
        return manager
    }
    
    lazy var networkManager: UnifiedNetworkManager = {
        return UnifiedNetworkManager()
    }()
    
    lazy var analyticsManager: UnifiedAnalyticsManager = {
        return UnifiedAnalyticsManager(
            storageManager: self.storageManager as any Core_StorageManaging
        )
    }()
    
    // Replace lazy property with computed property for async-initialized manager
    var notificationManager: UnifiedNotificationManager {
        guard let manager = _notificationManager else {
            fatalError("NotificationManager not initialized yet. Access this property after initialization is complete.")
        }
        return manager
    }
    
    lazy var yeelightManager: UnifiedYeelightManager = {
        return UnifiedYeelightManager(
            storageManager: self.storageManager as any Core_StorageManaging,
            networkManager: self.networkManager as any Core_NetworkManaging
        )
    }()
}

// MARK: - Sendable Extensions
// Make UserDefaults and FileManager conform to Sendable to fix actor isolation issues
extension UserDefaults: @unchecked Sendable {}
extension FileManager: @unchecked Sendable {} 