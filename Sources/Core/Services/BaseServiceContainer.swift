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
    }
    
    // MARK: - Lazy Managers
    
    lazy var logManager: UnifiedLogger = {
        return UnifiedLogger(storageManager: self.storageManager as any Core_StorageManaging)
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
    
    lazy var stateManager: UnifiedStateManager = {
        return await UnifiedStateManager(services: self)
    }()
    
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
    
    lazy var securityManager: UnifiedSecurityManager = {
        return await UnifiedSecurityManager(services: self)
    }()
    
    lazy var networkManager: UnifiedNetworkManager = {
        return UnifiedNetworkManager()
    }()
    
    lazy var analyticsManager: UnifiedAnalyticsManager = {
        return UnifiedAnalyticsManager(
            storageManager: self.storageManager as any Core_StorageManaging,
            configurationManager: self.configurationManager as any Core_ConfigurationManaging
        )
    }()
    
    lazy var notificationManager: UnifiedNotificationManager = {
        return await UnifiedNotificationManager()
    }()
    
    lazy var yeelightManager: UnifiedYeelightManager = {
        return UnifiedYeelightManager(
            storageManager: self.storageManager as any Core_StorageManaging,
            networkManager: self.networkManager as any Core_NetworkManaging
        )
    }()
} 