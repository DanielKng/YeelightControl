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
        let manager = ObservableYeelightManager(manager: self.yeelightManager as! UnifiedYeelightManager)
        _yeelightManager = manager
        return manager
    }
    
    /// Observable wrapper for DeviceManager
    public var deviceManager: ObservableDeviceManager {
        if let manager = _deviceManager {
            return manager
        }
        let manager = ObservableDeviceManager(manager: self.deviceManager as! UnifiedDeviceManager)
        _deviceManager = manager
        return manager
    }
    
    /// Observable wrapper for SceneManager
    public var sceneManager: ObservableSceneManager {
        if let manager = _sceneManager {
            return manager
        }
        let manager = ObservableSceneManager(manager: self.sceneManager as! UnifiedSceneManager)
        _sceneManager = manager
        return manager
    }
    
    /// Observable wrapper for EffectManager
    public var effectManager: ObservableEffectManager {
        if let manager = _effectManager {
            return manager
        }
        let manager = ObservableEffectManager(manager: self.effectManager as! UnifiedEffectManager)
        _effectManager = manager
        return manager
    }
    
    /// Observable wrapper for NetworkManager
    public var networkManager: ObservableNetworkManager {
        if let manager = _networkManager {
            return manager
        }
        let manager = ObservableNetworkManager(manager: self.networkManager as! UnifiedNetworkManager)
        _networkManager = manager
        return manager
    }
    
    /// Observable wrapper for StorageManager
    public var storageManager: ObservableStorageManager {
        if let manager = _storageManager {
            return manager
        }
        let manager = ObservableStorageManager(manager: self.storageManager as! UnifiedStorageManager)
        _storageManager = manager
        return manager
    }
    
    /// Observable wrapper for LocationManager
    public var locationManager: ObservableLocationManager {
        if let manager = _locationManager {
            return manager
        }
        let manager = ObservableLocationManager(manager: self.locationManager as! UnifiedLocationManager)
        _locationManager = manager
        return manager
    }
    
    /// Observable wrapper for PermissionManager
    public var permissionManager: ObservablePermissionManager {
        if let manager = _permissionManager {
            return manager
        }
        let manager = ObservablePermissionManager(manager: self.permissionManager as! UnifiedPermissionManager)
        _permissionManager = manager
        return manager
    }
    
    /// Observable wrapper for AnalyticsManager
    public var analyticsManager: ObservableAnalyticsManager {
        if let manager = _analyticsManager {
            return manager
        }
        let manager = ObservableAnalyticsManager(manager: self.analyticsManager as! UnifiedAnalyticsManager)
        _analyticsManager = manager
        return manager
    }
    
    /// Observable wrapper for ConfigurationManager
    public var configurationManager: ObservableConfigurationManager {
        if let manager = _configurationManager {
            return manager
        }
        let manager = ObservableConfigurationManager(manager: self.configurationManager as! UnifiedConfigurationManager)
        _configurationManager = manager
        return manager
    }
    
    /// Observable wrapper for StateManager
    public var stateManager: ObservableStateManager {
        if let manager = _stateManager {
            return manager
        }
        let manager = ObservableStateManager(manager: self.stateManager as! UnifiedStateManager)
        _stateManager = manager
        return manager
    }
    
    /// Observable wrapper for SecurityManager
    public var securityManager: ObservableSecurityManager {
        if let manager = _securityManager {
            return manager
        }
        let manager = ObservableSecurityManager(manager: self.securityManager as! UnifiedSecurityManager)
        _securityManager = manager
        return manager
    }
    
    /// Observable wrapper for ErrorManager
    public var errorManager: ObservableErrorManager {
        if let manager = _errorManager {
            return manager
        }
        let manager = ObservableErrorManager(manager: self.errorHandler as! UnifiedErrorManager)
        _errorManager = manager
        return manager
    }
    
    /// Observable wrapper for ThemeManager
    public var themeManager: ObservableThemeManager {
        if let manager = _themeManager {
            return manager
        }
        let manager = ObservableThemeManager(manager: self.themeManager as! UnifiedThemeManager)
        _themeManager = manager
        return manager
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

// MARK: - Dummy Implementations

/// Dummy implementation of UnifiedRoomManager
class UnifiedRoomManager {}

/// Dummy implementation of UnifiedConnectionManager
class UnifiedConnectionManager {
    func initialize() async throws {}
    func testConnection() async -> Bool { return true }
} 