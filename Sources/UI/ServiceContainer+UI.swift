import SwiftUI
import Core

// MARK: - ServiceContainer UI Extensions

/// Extension to add UI-specific properties to ServiceContainer
extension ServiceContainer {
    // MARK: - Observable Wrappers
    
    /// Observable wrapper for YeelightManager
    public var yeelightManager: ObservableYeelightManager {
        if let manager = _yeelightManager {
            return manager
        }
        
        if let unifiedManager = self.yeelightManager as? UnifiedYeelightManager {
            let manager = ObservableYeelightManager(manager: unifiedManager)
            _yeelightManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let storageManager = self.storageManager as? UnifiedStorageManager ?? UnifiedStorageManager()
            let networkManager = self.networkManager as? UnifiedNetworkManager ?? UnifiedNetworkManager()
            let unifiedManager = UnifiedYeelightManager(storageManager: storageManager, networkManager: networkManager)
            let manager = ObservableYeelightManager(manager: unifiedManager)
            _yeelightManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for DeviceManager
    public var deviceManager: ObservableDeviceManager {
        if let manager = _deviceManager {
            return manager
        }
        
        if let unifiedManager = self.deviceManager as? UnifiedDeviceManager {
            let manager = ObservableDeviceManager(manager: unifiedManager)
            _deviceManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedDeviceManager()
            let manager = ObservableDeviceManager(manager: unifiedManager)
            _deviceManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for SceneManager
    public var sceneManager: ObservableSceneManager {
        if let manager = _sceneManager {
            return manager
        }
        
        if let unifiedManager = self.sceneManager as? UnifiedSceneManager {
            let manager = ObservableSceneManager(manager: unifiedManager)
            _sceneManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedSceneManager()
            let manager = ObservableSceneManager(manager: unifiedManager)
            _sceneManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for EffectManager
    public var effectManager: ObservableEffectManager {
        if let manager = _effectManager {
            return manager
        }
        
        if let unifiedManager = self.effectManager as? UnifiedEffectManager {
            let manager = ObservableEffectManager(manager: unifiedManager)
            _effectManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedEffectManager()
            let manager = ObservableEffectManager(manager: unifiedManager)
            _effectManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for NetworkManager
    public var networkManager: ObservableNetworkManager {
        if let manager = _networkManager {
            return manager
        }
        
        if let unifiedManager = self.networkManager as? UnifiedNetworkManager {
            let manager = ObservableNetworkManager(manager: unifiedManager)
            _networkManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedNetworkManager()
            let manager = ObservableNetworkManager(manager: unifiedManager)
            _networkManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for StorageManager
    public var storageManager: ObservableStorageManager {
        if let manager = _storageManager {
            return manager
        }
        
        if let unifiedManager = self.storageManager as? UnifiedStorageManager {
            let manager = ObservableStorageManager(manager: unifiedManager)
            _storageManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedStorageManager()
            let manager = ObservableStorageManager(manager: unifiedManager)
            _storageManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for LocationManager
    public var locationManager: ObservableLocationManager {
        if let manager = _locationManager {
            return manager
        }
        
        if let unifiedManager = self.locationManager as? UnifiedLocationManager {
            let manager = ObservableLocationManager(manager: unifiedManager)
            _locationManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedLocationManager()
            let manager = ObservableLocationManager(manager: unifiedManager)
            _locationManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for PermissionManager
    public var permissionManager: ObservablePermissionManager {
        if let manager = _permissionManager {
            return manager
        }
        
        if let unifiedManager = self.permissionManager as? UnifiedPermissionManager {
            let manager = ObservablePermissionManager(manager: unifiedManager)
            _permissionManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedPermissionManager()
            let manager = ObservablePermissionManager(manager: unifiedManager)
            _permissionManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for AnalyticsManager
    public var analyticsManager: ObservableAnalyticsManager {
        if let manager = _analyticsManager {
            return manager
        }
        
        if let unifiedManager = self.analyticsManager as? UnifiedAnalyticsManager {
            let manager = ObservableAnalyticsManager(manager: unifiedManager)
            _analyticsManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedAnalyticsManager()
            let manager = ObservableAnalyticsManager(manager: unifiedManager)
            _analyticsManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for ConfigurationManager
    public var configurationManager: ObservableConfigurationManager {
        if let manager = _configurationManager {
            return manager
        }
        
        if let unifiedManager = self.configurationManager as? UnifiedConfigurationManager {
            let manager = ObservableConfigurationManager(manager: unifiedManager)
            _configurationManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedConfigurationManager()
            let manager = ObservableConfigurationManager(manager: unifiedManager)
            _configurationManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for StateManager
    public var stateManager: ObservableStateManager {
        if let manager = _stateManager {
            return manager
        }
        
        if let unifiedManager = self.stateManager as? UnifiedStateManager {
            let manager = ObservableStateManager(manager: unifiedManager)
            _stateManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedStateManager()
            let manager = ObservableStateManager(manager: unifiedManager)
            _stateManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for SecurityManager
    public var securityManager: ObservableSecurityManager {
        if let manager = _securityManager {
            return manager
        }
        
        if let unifiedManager = self.securityManager as? UnifiedSecurityManager {
            let manager = ObservableSecurityManager(manager: unifiedManager)
            _securityManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedSecurityManager()
            let manager = ObservableSecurityManager(manager: unifiedManager)
            _securityManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for ErrorManager
    public var errorManager: ObservableErrorManager {
        if let manager = _errorManager {
            return manager
        }
        
        if let unifiedManager = self.errorHandler as? UnifiedErrorManager {
            let manager = ObservableErrorManager(manager: unifiedManager)
            _errorManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedErrorManager()
            let manager = ObservableErrorManager(manager: unifiedManager)
            _errorManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for ThemeManager
    public var themeManager: ObservableThemeManager {
        if let manager = _themeManager {
            return manager
        }
        
        if let unifiedManager = self.themeManager as? UnifiedThemeManager {
            let manager = ObservableThemeManager(manager: unifiedManager)
            _themeManager = manager
            return manager
        } else {
            // Create a new manager if the cast fails
            let unifiedManager = UnifiedThemeManager()
            let manager = ObservableThemeManager(manager: unifiedManager)
            _themeManager = manager
            return manager
        }
    }
    
    /// Observable wrapper for Logger
    public var logger: ObservableLogger {
        return ObservableLogger.shared
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
// ... existing code ... 