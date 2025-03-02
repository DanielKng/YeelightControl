import CoreLocation
import Combine
import Foundation
import SwiftUI

// MARK: - Type Aliases for Core Service Protocols
// Removing all typealias declarations to resolve redeclaration errors

// MARK: - Core Location Event
public enum Core_LocationEvent {
    case regionEvent(CLRegion, Bool)
    case locationUpdate(CLLocation)
}

// MARK: - Service Container Protocol

@preconcurrency public protocol Core_ServiceContainer: AnyObject {
    // MARK: - Managers
    var analyticsManager: any Core_AnalyticsManaging { get }
    var configurationManager: any Core_ConfigurationManaging { get }
    var deviceManager: any Core_DeviceManaging { get }
    var effectManager: any Core_EffectManaging { get }
    var errorHandler: any Core_ErrorHandling { get }
    var locationManager: any Core_LocationManaging { get }
    var logManager: any Core_LoggingService { get }
    var networkManager: any Core_NetworkManaging { get }
    var notificationManager: any Core_NotificationManaging { get }
    var permissionManager: any Core_PermissionManaging { get }
    var sceneManager: any Core_SceneManaging { get }
    var securityManager: any Core_SecurityManaging { get }
    var stateManager: any Core_StateManaging { get }
    var storageManager: any Core_StorageManaging { get }
    var themeManager: any Core_ThemeManaging { get }
    var yeelightManager: any Core_YeelightManaging { get }
    
    // MARK: - Registration Methods
    func registerAnalyticsManager(_ manager: any Core_AnalyticsManaging)
    func registerConfigurationManager(_ manager: any Core_ConfigurationManaging)
    func registerDeviceManager(_ manager: any Core_DeviceManaging)
    func registerEffectManager(_ manager: any Core_EffectManaging)
    func registerErrorHandler(_ handler: any Core_ErrorHandling)
    func registerLocationManager(_ manager: any Core_LocationManaging)
    func registerLogManager(_ manager: any Core_LoggingService)
    func registerNetworkManager(_ manager: any Core_NetworkManaging)
    func registerNotificationManager(_ manager: any Core_NotificationManaging)
    func registerPermissionManager(_ manager: any Core_PermissionManaging)
    func registerSceneManager(_ manager: any Core_SceneManaging)
    func registerSecurityManager(_ manager: any Core_SecurityManaging)
    func registerStateManager(_ manager: any Core_StateManaging)
    func registerStorageManager(_ manager: any Core_StorageManaging)
    func registerThemeManager(_ manager: any Core_ThemeManaging)
    func registerYeelightManager(_ manager: any Core_YeelightManaging)
}

// MARK: - Service Container Implementation

public class ServiceContainer: Core_ServiceContainer {
    // MARK: - Singleton
    public static let shared = ServiceContainer()
    
    // MARK: - Managers
    public private(set) var analyticsManager: any Core_AnalyticsManaging
    public private(set) var configurationManager: any Core_ConfigurationManaging
    public private(set) var deviceManager: any Core_DeviceManaging
    public private(set) var effectManager: any Core_EffectManaging
    public private(set) var errorHandler: any Core_ErrorHandling
    public private(set) var locationManager: any Core_LocationManaging
    public private(set) var logManager: any Core_LoggingService
    public private(set) var networkManager: any Core_NetworkManaging
    public private(set) var notificationManager: any Core_NotificationManaging
    public private(set) var permissionManager: any Core_PermissionManaging
    public private(set) var sceneManager: any Core_SceneManaging
    public private(set) var securityManager: any Core_SecurityManaging
    public private(set) var stateManager: any Core_StateManaging
    public private(set) var storageManager: any Core_StorageManaging
    public private(set) var themeManager: any Core_ThemeManaging
    public private(set) var yeelightManager: any Core_YeelightManaging
    
    // MARK: - Initialization
    
    public init() {
        // Initialize storage manager first since many other managers depend on it
        self.storageManager = UnifiedStorageManager()
        
        // Initialize managers that only depend on storage
        self.analyticsManager = UnifiedAnalyticsManager(storageManager: self.storageManager)
        self.configurationManager = UnifiedConfigurationManager(storageManager: self.storageManager)
        self.logManager = UnifiedLogger(storageManager: self.storageManager)
        self.networkManager = UnifiedNetworkManager()
        self.themeManager = UnifiedThemeManager(storageManager: self.storageManager)
        
        // Initialize managers that depend on other managers
        self.errorHandler = UnifiedErrorHandler(services: self)
        self.locationManager = UnifiedLocationManager(services: self)
        self.deviceManager = UnifiedDeviceManager(storageManager: self.storageManager)
        self.yeelightManager = UnifiedYeelightManager(storageManager: self.storageManager, networkManager: self.networkManager)
        
        // Initialize managers that depend on device manager
        self.effectManager = UnifiedEffectManager(storageManager: self.storageManager, deviceManager: self.deviceManager)
        
        // Initialize remaining managers
        self.permissionManager = UnifiedPermissionManager()
        self.sceneManager = UnifiedSceneManager(storageManager: self.storageManager, deviceManager: self.deviceManager, effectManager: self.effectManager)
        self.securityManager = UnifiedSecurityManager() as! any Core_SecurityManaging
        
        // Use a placeholder for state manager initially
        let placeholderStateManager = PlaceholderStateManager()
        self.stateManager = placeholderStateManager
        
        // Initialize state manager asynchronously
        Task {
            // Fix actor isolation issue by using nonisolated async function
            let realStateManager = await createStateManager()
            self.stateManager = realStateManager
        }
        
        // Initialize notification manager directly
        self.notificationManager = UnifiedNotificationManager()
        
        // Register for notifications
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        #endif
    }
    
    // Helper method to create state manager without actor isolation issues
    private nonisolated func createStateManager() async -> any Core_StateManaging {
        return await MainActor.run {
            UnifiedStateManager(services: self)
        }
    }
    
    @objc private func handleAppWillTerminate() {
        // Perform cleanup when app terminates
        print("App will terminate, performing cleanup...")
    }
    
    // MARK: - Registration Methods
    
    public func registerAnalyticsManager(_ manager: any Core_AnalyticsManaging) {
        self.analyticsManager = manager
    }
    
    public func registerConfigurationManager(_ manager: any Core_ConfigurationManaging) {
        self.configurationManager = manager
    }
    
    public func registerDeviceManager(_ manager: any Core_DeviceManaging) {
        self.deviceManager = manager
    }
    
    public func registerEffectManager(_ manager: any Core_EffectManaging) {
        self.effectManager = manager
    }
    
    public func registerErrorHandler(_ handler: any Core_ErrorHandling) {
        self.errorHandler = handler
    }
    
    public func registerLocationManager(_ manager: any Core_LocationManaging) {
        self.locationManager = manager
    }
    
    public func registerLogManager(_ manager: any Core_LoggingService) {
        self.logManager = manager
    }
    
    public func registerNetworkManager(_ manager: any Core_NetworkManaging) {
        self.networkManager = manager
    }
    
    public func registerNotificationManager(_ manager: any Core_NotificationManaging) {
        self.notificationManager = manager
    }
    
    public func registerPermissionManager(_ manager: any Core_PermissionManaging) {
        self.permissionManager = manager
    }
    
    public func registerSceneManager(_ manager: any Core_SceneManaging) {
        self.sceneManager = manager
    }
    
    public func registerSecurityManager(_ manager: any Core_SecurityManaging) {
        self.securityManager = manager
    }
    
    public func registerStateManager(_ manager: any Core_StateManaging) {
        self.stateManager = manager
    }
    
    public func registerStorageManager(_ manager: any Core_StorageManaging) {
        self.storageManager = manager
    }
    
    public func registerThemeManager(_ manager: any Core_ThemeManaging) {
        self.themeManager = manager
    }
    
    public func registerYeelightManager(_ manager: any Core_YeelightManaging) {
        self.yeelightManager = manager
    }
}

// MARK: - Placeholder Managers

/// A placeholder state manager that does nothing
private class PlaceholderStateManager: Core_StateManaging {
    public var isEnabled: Bool {
        return true
    }
    
    public var deviceStates: [String: Core_DeviceState] {
        return [:]
    }
    
    public var stateUpdates: AnyPublisher<[String: Core_DeviceState], Never> {
        return PassthroughSubject<[String: Core_DeviceState], Never>().eraseToAnyPublisher()
    }
    
    public func updateDeviceState(_ state: Core_DeviceState, forDeviceId deviceId: String) async {
        // Do nothing
    }
    
    public func getDeviceState(forDeviceId deviceId: String) async -> Core_DeviceState? {
        return nil
    }
}

// MARK: - View Extension
extension View {
    var services: ServiceContainer {
        return ServiceContainer.shared
    }
} 