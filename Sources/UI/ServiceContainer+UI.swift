import SwiftUI
import Core

// MARK: - UI Observable Storage

/// Storage class for observable wrappers
public class UIObservableStorage {
    // Singleton instance
    public static let shared = UIObservableStorage()
    
    // Observable wrappers
    public var yeelightManager: ObservableYeelightManager?
    public var deviceManager: ObservableDeviceManager?
    public var sceneManager: ObservableSceneManager?
    public var effectManager: ObservableEffectManager?
    public var networkManager: ObservableNetworkManager?
    public var storageManager: ObservableStorageManager?
    public var locationManager: ObservableLocationManager?
    public var permissionManager: ObservablePermissionManager?
    public var analyticsManager: ObservableAnalyticsManager?
    public var configurationManager: ObservableConfigurationManager?
    public var stateManager: ObservableStateManager?
    public var securityManager: ObservableSecurityManager?
    public var errorManager: ObservableErrorManager?
    public var themeManager: ObservableThemeManager?
    public var logger: ObservableLogger?
    
    // Private constructor to enforce singleton pattern
    private init() {}
}

// MARK: - ServiceContainer UI Extensions

/// Extension to add UI-specific properties to ServiceContainer
extension ServiceContainer {
    // MARK: - Observable Wrappers
    
    /// Observable wrapper for YeelightManager
    public var observableYeelightManager: ObservableYeelightManager {
        if let manager = UIObservableStorage.shared.yeelightManager {
            return manager
        }
        
        if let unifiedManager = self.yeelightManager as? UnifiedYeelightManager {
            let manager = ObservableYeelightManager(manager: unifiedManager)
            UIObservableStorage.shared.yeelightManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let storageManager = self.storageManager as? UnifiedStorageManager ?? UnifiedStorageManager()
            let networkManager = self.networkManager as? UnifiedNetworkManager ?? UnifiedNetworkManager()
            let unifiedManager = UnifiedYeelightManager(storageManager: storageManager, networkManager: networkManager)
            let manager = ObservableYeelightManager(manager: unifiedManager)
            UIObservableStorage.shared.yeelightManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for DeviceManager
    public var observableDeviceManager: ObservableDeviceManager {
        if let manager = UIObservableStorage.shared.deviceManager {
            return manager
        }
        
        if let unifiedManager = self.deviceManager as? UnifiedDeviceManager {
            let manager = ObservableDeviceManager(manager: unifiedManager)
            UIObservableStorage.shared.deviceManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedDeviceManager()
            let manager = ObservableDeviceManager(manager: unifiedManager)
            UIObservableStorage.shared.deviceManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for SceneManager
    public var observableSceneManager: ObservableSceneManager {
        if let manager = UIObservableStorage.shared.sceneManager {
            return manager
        }
        
        if let unifiedManager = self.sceneManager as? UnifiedSceneManager {
            let manager = ObservableSceneManager(manager: unifiedManager)
            UIObservableStorage.shared.sceneManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedSceneManager()
            let manager = ObservableSceneManager(manager: unifiedManager)
            UIObservableStorage.shared.sceneManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for EffectManager
    public var observableEffectManager: ObservableEffectManager {
        if let manager = UIObservableStorage.shared.effectManager {
            return manager
        }
        
        if let unifiedManager = self.effectManager as? UnifiedEffectManager {
            let manager = ObservableEffectManager(manager: unifiedManager)
            UIObservableStorage.shared.effectManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedEffectManager()
            let manager = ObservableEffectManager(manager: unifiedManager)
            UIObservableStorage.shared.effectManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for NetworkManager
    public var observableNetworkManager: ObservableNetworkManager {
        if let manager = UIObservableStorage.shared.networkManager {
            return manager
        }
        
        if let unifiedManager = self.networkManager as? UnifiedNetworkManager {
            let manager = ObservableNetworkManager(manager: unifiedManager)
            UIObservableStorage.shared.networkManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedNetworkManager()
            let manager = ObservableNetworkManager(manager: unifiedManager)
            UIObservableStorage.shared.networkManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for StorageManager
    public var observableStorageManager: ObservableStorageManager {
        if let manager = UIObservableStorage.shared.storageManager {
            return manager
        }
        
        if let unifiedManager = self.storageManager as? UnifiedStorageManager {
            let manager = ObservableStorageManager(manager: unifiedManager)
            UIObservableStorage.shared.storageManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedStorageManager()
            let manager = ObservableStorageManager(manager: unifiedManager)
            UIObservableStorage.shared.storageManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for LocationManager
    public var observableLocationManager: ObservableLocationManager {
        if let manager = UIObservableStorage.shared.locationManager {
            return manager
        }
        
        if let unifiedManager = self.locationManager as? UnifiedLocationManager {
            let manager = ObservableLocationManager(manager: unifiedManager)
            UIObservableStorage.shared.locationManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedLocationManager()
            let manager = ObservableLocationManager(manager: unifiedManager)
            UIObservableStorage.shared.locationManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for PermissionManager
    public var observablePermissionManager: ObservablePermissionManager {
        if let manager = UIObservableStorage.shared.permissionManager {
            return manager
        }
        
        if let unifiedManager = self.permissionManager as? UnifiedPermissionManager {
            let manager = ObservablePermissionManager(manager: unifiedManager)
            UIObservableStorage.shared.permissionManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedPermissionManager()
            let manager = ObservablePermissionManager(manager: unifiedManager)
            UIObservableStorage.shared.permissionManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for AnalyticsManager
    public var observableAnalyticsManager: ObservableAnalyticsManager {
        if let manager = UIObservableStorage.shared.analyticsManager {
            return manager
        }
        
        if let unifiedManager = self.analyticsManager as? UnifiedAnalyticsManager {
            let manager = ObservableAnalyticsManager(manager: unifiedManager)
            UIObservableStorage.shared.analyticsManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedAnalyticsManager()
            let manager = ObservableAnalyticsManager(manager: unifiedManager)
            UIObservableStorage.shared.analyticsManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for ConfigurationManager
    public var observableConfigurationManager: ObservableConfigurationManager {
        if let manager = UIObservableStorage.shared.configurationManager {
            return manager
        }
        
        if let unifiedManager = self.configurationManager as? UnifiedConfigurationManager {
            let manager = ObservableConfigurationManager(manager: unifiedManager)
            UIObservableStorage.shared.configurationManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedConfigurationManager()
            let manager = ObservableConfigurationManager(manager: unifiedManager)
            UIObservableStorage.shared.configurationManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for StateManager
    public var observableStateManager: ObservableStateManager {
        if let manager = UIObservableStorage.shared.stateManager {
            return manager
        }
        
        if let unifiedManager = self.stateManager as? UnifiedStateManager {
            let manager = ObservableStateManager(manager: unifiedManager)
            UIObservableStorage.shared.stateManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedStateManager()
            let manager = ObservableStateManager(manager: unifiedManager)
            UIObservableStorage.shared.stateManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for SecurityManager
    public var observableSecurityManager: ObservableSecurityManager {
        if let manager = UIObservableStorage.shared.securityManager {
            return manager
        }
        
        if let unifiedManager = self.securityManager as? UnifiedSecurityManager {
            let manager = ObservableSecurityManager(manager: unifiedManager)
            UIObservableStorage.shared.securityManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedSecurityManager()
            let manager = ObservableSecurityManager(manager: unifiedManager)
            UIObservableStorage.shared.securityManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for ErrorManager
    public var observableErrorManager: ObservableErrorManager {
        if let manager = UIObservableStorage.shared.errorManager {
            return manager
        }
        
        if let unifiedManager = self.errorHandler as? UnifiedErrorHandler {
            let manager = ObservableErrorManager(manager: unifiedManager)
            UIObservableStorage.shared.errorManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedErrorHandler()
            let manager = ObservableErrorManager(manager: unifiedManager)
            UIObservableStorage.shared.errorManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for ThemeManager
    public var observableThemeManager: ObservableThemeManager {
        if let manager = UIObservableStorage.shared.themeManager {
            return manager
        }
        
        if let unifiedManager = self.themeManager as? UnifiedThemeManager {
            let manager = ObservableThemeManager(manager: unifiedManager)
            UIObservableStorage.shared.themeManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedThemeManager()
            let manager = ObservableThemeManager(manager: unifiedManager)
            UIObservableStorage.shared.themeManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for Logger
    public var observableLogger: ObservableLogger {
        if let logger = UIObservableStorage.shared.logger {
            return logger
        }
        
        if let unifiedLogger = self.logger as? UnifiedLogger {
            let logger = ObservableLogger(logger: unifiedLogger)
            UIObservableStorage.shared.logger = logger
            return logger
        } else {
            // Create a new logger if the cast fails
            let unifiedLogger = UnifiedLogger()
            let logger = ObservableLogger(logger: unifiedLogger)
            UIObservableStorage.shared.logger = logger
            return logger
        }
    }
    
    /// Observable wrapper for AutomationManager
    public var automationManager: ObservableAutomationManager {
        return ObservableAutomationManager.shared
    }
    
    /// Observable wrapper for RoomManager
    public var roomManager: ObservableRoomManager {
        if let manager = _roomManager {
            return manager
        }
        let manager = ObservableRoomManager(manager: UnifiedRoomManager())
        _roomManager = manager
        return manager
    }
    
    /// Observable wrapper for ConnectionManager
    public var connectionManager: ObservableConnectionManager {
        if let manager = _connectionManager {
            return manager
        }
        let manager = ObservableConnectionManager(manager: UnifiedConnectionManager())
        _connectionManager = manager
        return manager
    }
    
    // MARK: - Private Properties
    
    private var _yeelightManager: ObservableYeelightManager?
    private var _deviceManager: ObservableDeviceManager?
    private var _sceneManager: ObservableSceneManager?
    private var _effectManager: ObservableEffectManager?
    private var _networkManager: ObservableNetworkManager?
    private var _storageManager: ObservableStorageManager?
    private var _locationManager: ObservableLocationManager?
    private var _permissionManager: ObservablePermissionManager?
    private var _analyticsManager: ObservableAnalyticsManager?
    private var _configurationManager: ObservableConfigurationManager?
    private var _stateManager: ObservableStateManager?
    private var _securityManager: ObservableSecurityManager?
    private var _errorManager: ObservableErrorManager?
    private var _themeManager: ObservableThemeManager?
    private var _roomManager: ObservableRoomManager?
    private var _connectionManager: ObservableConnectionManager?
}

// MARK: - Real Implementations for UI

extension UnifiedRoomManager {
    // This extension ensures the UnifiedRoomManager from Features module 
    // is properly integrated with the UI layer
}

extension UnifiedConnectionManager {
    // This extension ensures the UnifiedConnectionManager
    // is properly integrated with the UI layer
}

// MARK: - View Extension

extension View {
    /// Injects all observable managers into the environment
    public func withObservableManagers(container: ServiceContainer = ServiceContainer.shared) -> some View {
        self
            .environmentObject(container.observableYeelightManager)
            .environmentObject(container.observableDeviceManager)
            .environmentObject(container.observableSceneManager)
            .environmentObject(container.observableEffectManager)
            .environmentObject(container.observableNetworkManager)
            .environmentObject(container.observableStorageManager)
            .environmentObject(container.observableLocationManager)
            .environmentObject(container.observablePermissionManager)
            .environmentObject(container.observableAnalyticsManager)
            .environmentObject(container.observableConfigurationManager)
            .environmentObject(container.observableStateManager)
            .environmentObject(container.observableSecurityManager)
            .environmentObject(container.observableErrorManager)
            .environmentObject(container.observableThemeManager)
            .environmentObject(container.observableLogger)
    }
} 