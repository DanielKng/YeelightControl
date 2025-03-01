import CoreLocation
import Combine
import Foundation
import SwiftUI

// MARK: - Type Aliases for Core Service Protocols
// These typealiases help with backward compatibility
public typealias CoreBaseService = Core_BaseService
public typealias CoreNetworkManaging = Core_NetworkManaging
public typealias CoreSecurityManaging = Core_SecurityManaging
public typealias CoreNotificationManaging = Core_NotificationManaging
public typealias CoreSceneManaging = Core_SceneManaging
public typealias CoreYeelightManaging = Core_YeelightManaging
public typealias CoreLocationManaging = Core_LocationManaging
public typealias CoreDeviceManaging = Core_DeviceManaging
public typealias CoreEffectManaging = Core_EffectManaging
public typealias CoreConfigurationManaging = Core_ConfigurationManaging
public typealias CoreStorageManaging = Core_StorageManaging
public typealias CoreLoggingService = Core_LoggingService
public typealias CoreThemeManaging = Core_ThemeManaging
public typealias CoreErrorHandling = Core_ErrorHandling
public typealias CoreAnalyticsManaging = Core_AnalyticsManaging
public typealias CorePermissionManaging = Core_PermissionManaging
public typealias CoreStateManaging = Core_StateManaging

// MARK: - Type Aliases for Core Types
public typealias CoreLogCategory = Core_LogCategory
public typealias CoreLogLevel = Core_LogLevel
public typealias CoreLogEntry = Core_LogEntry
public typealias CorePermissionType = Core_PermissionType
public typealias CorePermissionStatus = Core_PermissionStatus
public typealias AppTheme = Core_Theme
public typealias CoreDeviceState = Core_DeviceState
public typealias CoreDevice = Core_Device
public typealias CoreYeelight = Core_Yeelight
public typealias CoreScene = Core_Scene
public typealias CoreSceneUpdate = Core_SceneUpdate
public typealias CoreEffect = Core_Effect
public typealias CoreEffectType = Core_EffectType
public typealias CoreEffectParameters = Core_EffectParameters
public typealias CoreEffectUpdate = Core_EffectUpdate
public typealias CoreLocation = Core_Location
public typealias CoreNetworkError = Core_NetworkError
public typealias CoreConfigKey = Core_ConfigKey
public typealias CoreConfigValue = Core_ConfigValue
public typealias CoreConfiguration = Core_Configuration
public typealias CoreConfigurationError = Core_ConfigurationError
public typealias CoreStorageKey = Core_StorageKey
public typealias CoreStorageDirectory = Core_StorageDirectory
public typealias CoreStorageError = Core_StorageError
public typealias CoreSecurityError = Core_SecurityError
public typealias CoreAnalyticsEvent = Core_AnalyticsEvent
public typealias CoreAnalyticsEventType = Core_AnalyticsEventType

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
    
    private init() {
        // Initialize with default implementations
        // These will be replaced by the actual implementations during app startup
        self.analyticsManager = DummyAnalyticsManager()
        self.configurationManager = DummyConfigurationManager()
        self.deviceManager = DummyDeviceManager()
        self.effectManager = DummyEffectManager()
        self.errorHandler = DummyErrorHandler()
        self.locationManager = DummyLocationManager()
        self.logManager = DummyLogManager()
        self.networkManager = DummyNetworkManager()
        self.notificationManager = DummyNotificationManager()
        self.permissionManager = DummyPermissionManager()
        self.sceneManager = DummySceneManager()
        self.securityManager = DummySecurityManager()
        self.stateManager = DummyStateManager()
        self.storageManager = DummyStorageManager()
        self.themeManager = DummyThemeManager()
        self.yeelightManager = DummyYeelightManager()
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

// MARK: - Dummy Implementations

private class DummyAnalyticsManager: Core_AnalyticsManaging {
    var isEnabled: Bool = false
    var analyticsEvents: AnyPublisher<Core_AnalyticsEvent, Never> {
        Empty().eraseToAnyPublisher()
    }
    func trackEvent(_ event: Core_AnalyticsEvent) {}
    func setUserProperty(_ property: String, value: String) {}
}

private class DummyConfigurationManager: Core_ConfigurationManaging {
    var isEnabled: Bool = false
    var values: [Core_ConfigKey: Any] { [:] }
    var configurationUpdates: AnyPublisher<Core_ConfigKey, Never> {
        Empty().eraseToAnyPublisher()
    }
    func getValue<T>(for key: Core_ConfigKey) throws -> T { throw Core_ConfigurationError.notFound }
    func setValue<T>(_ value: T, for key: Core_ConfigKey) throws {}
    func removeValue(for key: Core_ConfigKey) throws {}
}

private class DummyDeviceManager: Core_DeviceManaging {
    var isEnabled: Bool = false
    var devices: [Core_Device] { [] }
    var deviceUpdates: AnyPublisher<[Core_Device], Never> {
        Empty().eraseToAnyPublisher()
    }
    func discoverDevices() async throws {}
    func connectToDevice(_ device: Core_Device) async throws {}
    func disconnectFromDevice(_ device: Core_Device) async throws {}
    func updateDevice(_ device: Core_Device) async throws {}
}

private class DummyEffectManager: Core_EffectManaging {
    var isEnabled: Bool = false
    func applyEffect(_ effect: Core_Effect, to device: Core_Device) async throws {}
    func getAvailableEffects() -> [Core_Effect] { [] }
}

private class DummyErrorHandler: Core_ErrorHandling {
    var isEnabled: Bool = false
    var lastError: Core_AppError? { nil }
    var errorUpdates: AnyPublisher<Core_AppError, Never> {
        Empty().eraseToAnyPublisher()
    }
    func handle(_ appError: Core_AppError) async {}
}

private class DummyLocationManager: Core_LocationManaging {
    var isEnabled: Bool = false
    var currentLocation: CLLocation? { nil }
    var locationUpdates: AnyPublisher<CLLocation, Never> {
        Empty().eraseToAnyPublisher()
    }
    func startUpdatingLocation() async {}
    func stopUpdatingLocation() async {}
    func requestAuthorization() async -> Core_PermissionStatus { .notDetermined }
    func getAuthorizationStatus() async -> Core_PermissionStatus { .notDetermined }
}

private class DummyLogManager: Core_LoggingService {
    var isEnabled: Bool = false
    func log(_ message: String, level: Core_LogLevel, category: Core_LogCategory, file: String, function: String, line: Int) {}
    func getAllLogs() -> [Core_LogEntry] { [] }
    func clearLogs() {}
}

private class DummyNetworkManager: Core_NetworkManaging {
    var isEnabled: Bool = false
    func request<T: Decodable>(_ endpoint: String, method: String, headers: [String: String]?, body: Data?) async throws -> T {
        throw Core_NetworkError.invalidResponse
    }
    func download(_ url: URL) async throws -> Data {
        throw Core_NetworkError.invalidResponse
    }
}

private class DummyNotificationManager: Core_NotificationManaging {
    var isEnabled: Bool = false
    var notificationEvents: AnyPublisher<Core_NotificationEvent, Never> {
        Empty().eraseToAnyPublisher()
    }
    func requestAuthorization() async throws -> Core_PermissionStatus { .notDetermined }
    func getAuthorizationStatus() async -> Core_PermissionStatus { .notDetermined }
    func scheduleNotification(_ notification: Core_NotificationRequest) async throws {}
    func cancelNotification(withId id: String) async {}
    func cancelAllNotifications() async {}
    func getPendingNotifications() async -> [Core_NotificationRequest] { [] }
    func getDeliveredNotifications() async -> [Core_NotificationRequest] { [] }
}

private class DummyPermissionManager: Core_PermissionManaging {
    var isEnabled: Bool = false
    var permissionUpdates: AnyPublisher<(Core_PermissionType, Core_PermissionStatus), Never> {
        Empty().eraseToAnyPublisher()
    }
    func getPermissionStatus(_ permission: Core_PermissionType) async -> Core_PermissionStatus { .notDetermined }
    func requestPermission(_ permission: Core_PermissionType) async -> Core_PermissionStatus { .notDetermined }
    func isPermissionGranted(_ permission: Core_PermissionType) async -> Bool { false }
}

private class DummySceneManager: Core_SceneManaging {
    var isEnabled: Bool = false
    var scenes: [Core_Scene] { [] }
    var sceneUpdates: AnyPublisher<[Core_Scene], Never> {
        Empty().eraseToAnyPublisher()
    }
    func activateScene(_ scene: Core_Scene) async throws {}
    func deactivateScene(_ scene: Core_Scene) async throws {}
    func createScene(_ scene: Core_Scene) async throws {}
    func updateScene(_ scene: Core_Scene) async throws {}
    func deleteScene(_ scene: Core_Scene) async throws {}
}

private class DummySecurityManager: Core_SecurityManaging {
    var isEnabled: Bool = false
    func encrypt(_ data: Data, withKey key: String) async throws -> Data { Data() }
    func decrypt(_ data: Data, withKey key: String) async throws -> Data { Data() }
    func generateSecureKey() async throws -> String { "" }
    func storeSecureValue(_ value: String, forKey key: String) async throws {}
    func retrieveSecureValue(forKey key: String) async throws -> String? { nil }
    func deleteSecureValue(forKey key: String) async throws {}
    func isBiometricAuthenticationAvailable() async -> Bool { false }
    func authenticateWithBiometrics(reason: String) async throws -> Bool { false }
}

private class DummyStateManager: Core_StateManaging {
    var isEnabled: Bool = false
    var deviceStates: [String: Core_DeviceState] { [:] }
    var stateUpdates: AnyPublisher<[String: Core_DeviceState], Never> {
        Empty().eraseToAnyPublisher()
    }
    func updateDeviceState(_ state: Core_DeviceState, forDeviceId deviceId: String) async {}
    func getDeviceState(forDeviceId deviceId: String) -> Core_DeviceState? { nil }
}

private class DummyStorageManager: Core_StorageManaging {
    var isEnabled: Bool = false
    func save<T: Encodable>(_ object: T, withId id: String, inCollection collection: String) async throws {}
    func get<T: Decodable>(withId id: String, fromCollection collection: String) async throws -> T {
        throw Core_StorageError.notFound
    }
    func getAll<T: Decodable>(fromCollection collection: String) async throws -> [T] { [] }
    func delete(withId id: String, fromCollection collection: String) async throws {}
    func deleteCollection(_ collection: String) async throws {}
    func exists(withId id: String, inCollection collection: String) async -> Bool { false }
}

private class DummyThemeManager: Core_ThemeManaging {
    var isEnabled: Bool = false
    var currentTheme: Core_Theme { .system }
    var themeUpdates: AnyPublisher<Core_Theme, Never> {
        Empty().eraseToAnyPublisher()
    }
    func setTheme(_ theme: Core_Theme) {}
    func getThemeColors() -> ThemeColors { DefaultThemeColors() }
    func getThemeFonts() -> ThemeFonts { DefaultThemeFonts() }
    func getThemeMetrics() -> ThemeMetrics { DefaultThemeMetrics() }
}

private class DummyYeelightManager: Core_YeelightManaging {
    var isEnabled: Bool = false
    var devices: [Core_Yeelight] { [] }
    var deviceUpdates: AnyPublisher<[Core_Yeelight], Never> {
        Empty().eraseToAnyPublisher()
    }
    func discoverDevices() async throws {}
    func connectToDevice(_ device: Core_Yeelight) async throws {}
    func disconnectFromDevice(_ device: Core_Yeelight) async throws {}
    func turnOn(_ device: Core_Yeelight) async throws {}
    func turnOff(_ device: Core_Yeelight) async throws {}
    func setBrightness(_ brightness: Int, for device: Core_Yeelight) async throws {}
    func setColor(_ color: Core_Color, for device: Core_Yeelight) async throws {}
}

// MARK: - Default Theme Implementations

private struct DefaultThemeColors: ThemeColors {
    var primary: Color { .blue }
    var secondary: Color { .gray }
    var accent: Color { .orange }
    var background: Color { .white }
    var text: Color { .black }
    var error: Color { .red }
    var success: Color { .green }
    var warning: Color { .yellow }
    var info: Color { .blue }
}

private struct DefaultThemeFonts: ThemeFonts {
    var title: Font { .title }
    var headline: Font { .headline }
    var body: Font { .body }
    var caption: Font { .caption }
    var button: Font { .headline }
}

private struct DefaultThemeMetrics: ThemeMetrics {
    var spacing: CGFloat { 8 }
    var padding: CGFloat { 16 }
    var cornerRadius: CGFloat { 8 }
    var iconSize: CGFloat { 24 }
    var buttonHeight: CGFloat { 44 }
}

// MARK: - View Extension
extension View {
    var services: ServiceContainer {
        return ServiceContainer.shared
    }
} 