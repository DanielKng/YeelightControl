import Foundation
import Combine
import SwiftUI

// MARK: - Configuration Managing Protocol
protocol ConfigurationManaging {
    var configurationUpdates: AnyPublisher<Void, Never> { get }
    
    func getValue<T>(for key: ConfigKey) -> T?
    func setValue<T>(_ value: T, for key: ConfigKey) throws
    func resetToDefaults()
}

// MARK: - Configuration Keys
enum ConfigKey: String {
    // Network Configuration
    case discoveryTimeout
    case discoveryRetryCount
    case discoveryRetryDelay
    case useBonjourDiscovery
    case ssdpDiscoveryPort
    
    // Background Configuration
    case minRefreshInterval
    case maxRetryAttempts
    case retryDelay
    case backgroundTaskTimeout
    
    // Location Configuration
    case desiredAccuracy
    case distanceFilter
    case activityType
    case pausesLocationUpdatesAutomatically
    case allowsBackgroundLocationUpdates
    
    // Logger Configuration
    case maxLogFileSize
    case maxLogFiles
    case minDiskSpace
    case rotationInterval
    case isFileLoggingEnabled
    
    // App Configuration
    case theme
    case autoDiscoveryEnabled
    case defaultTransitionDuration
    case defaultBrightness
    case defaultColorTemperature
}

// MARK: - Configuration Value Type
enum ConfigValue: Codable, Equatable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case timeInterval(TimeInterval)
    
    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }
    
    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }
    
    var doubleValue: Double? {
        if case .double(let value) = self { return value }
        return nil
    }
    
    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }
    
    var timeIntervalValue: TimeInterval? {
        if case .timeInterval(let value) = self { return value }
        return nil
    }
}

// MARK: - Configuration Manager Implementation
@MainActor
public final class UnifiedConfigurationManager: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var configuration: Configuration
    @Published public private(set) var isDirty = false
    
    // MARK: - Private Properties
    private let storage: UnifiedStorageManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum Constants {
        static let configurationKey = "app_configuration"
        static let autosaveInterval: TimeInterval = 30
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedConfigurationManager()
    
    private init() {
        self.storage = .shared
        self.configuration = Self.defaultConfiguration
        loadConfiguration()
        setupAutosave()
    }
    
    // MARK: - Public Methods
    public func updateConfiguration(_ update: (inout Configuration) -> Void) {
        var newConfig = configuration
        update(&newConfig)
        configuration = newConfig
        isDirty = true
        saveConfiguration()
    }
    
    public func resetToDefaults() {
        configuration = Self.defaultConfiguration
        isDirty = true
        saveConfiguration()
    }
    
    // MARK: - Private Methods
    private func loadConfiguration() {
        do {
            let data = try storage.load(forKey: Constants.configurationKey)
            let decoder = JSONDecoder()
            configuration = try decoder.decode(Configuration.self, from: data)
            isDirty = false
        } catch {
            print("Failed to load configuration: \(error)")
            configuration = Self.defaultConfiguration
        }
    }
    
    private func saveConfiguration() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(configuration)
            try storage.save(data, forKey: Constants.configurationKey)
            isDirty = false
        } catch {
            print("Failed to save configuration: \(error)")
        }
    }
    
    private func setupAutosave() {
        Timer.publish(every: Constants.autosaveInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isDirty else { return }
                self.saveConfiguration()
            }
            .store(in: &cancellables)
    }
    
    private static var defaultConfiguration: Configuration {
        Configuration(
            deviceSettings: .init(
                defaultBrightness: 50,
                defaultColorTemperature: 4000,
                autoConnect: true,
                discoveryTimeout: 10
            ),
            networkSettings: .init(
                discoveryPort: 1982,
                controlPort: 55443,
                discoveryInterval: 5,
                connectionTimeout: 5
            ),
            appSettings: .init(
                theme: .system,
                analyticsEnabled: true,
                notificationsEnabled: true,
                backgroundRefreshEnabled: true
            ),
            securitySettings: .init(
                biometricsEnabled: true,
                autoLockTimeout: 300
            )
        )
    }
}

// MARK: - Configuration Types
public struct Configuration: Codable {
    public var deviceSettings: DeviceSettings
    public var networkSettings: NetworkSettings
    public var appSettings: AppSettings
    public var securitySettings: SecuritySettings
    
    public struct DeviceSettings: Codable {
        public var defaultBrightness: Int
        public var defaultColorTemperature: Int
        public var autoConnect: Bool
        public var discoveryTimeout: TimeInterval
    }
    
    public struct NetworkSettings: Codable {
        public var discoveryPort: Int
        public var controlPort: Int
        public var discoveryInterval: TimeInterval
        public var connectionTimeout: TimeInterval
    }
    
    public struct AppSettings: Codable {
        public var theme: Theme
        public var analyticsEnabled: Bool
        public var notificationsEnabled: Bool
        public var backgroundRefreshEnabled: Bool
    }
    
    public struct SecuritySettings: Codable {
        public var biometricsEnabled: Bool
        public var autoLockTimeout: TimeInterval
    }
}

public enum Theme: String, Codable {
    case light
    case dark
    case system
}

// MARK: - ConfigValue Extensions
extension ConfigValue {
    init<T>(value: T) throws {
        switch value {
        case let bool as Bool:
            self = .bool(bool)
        case let int as Int:
            self = .int(int)
        case let double as Double:
            self = .double(double)
        case let string as String:
            self = .string(string)
        case let timeInterval as TimeInterval:
            self = .timeInterval(timeInterval)
        default:
            throw ConfigurationError.unsupportedType
        }
    }
    
    func getValue<T>() -> T? {
        switch self {
        case .bool(let value):
            return value as? T
        case .int(let value):
            return value as? T
        case .double(let value):
            return value as? T
        case .string(let value):
            return value as? T
        case .timeInterval(let value):
            return value as? T
        }
    }
}

// MARK: - Configuration Errors
enum ConfigurationError: LocalizedError {
    case invalidKey
    case invalidValue
    case unsupportedType
    case saveFailed
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "Invalid configuration key"
        case .invalidValue:
            return "Invalid configuration value"
        case .unsupportedType:
            return "Unsupported configuration value type"
        case .saveFailed:
            return "Failed to save configuration"
        case .loadFailed:
            return "Failed to load configuration"
        }
    }
} 