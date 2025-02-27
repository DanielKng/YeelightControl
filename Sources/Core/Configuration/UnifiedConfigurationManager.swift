import Foundation
import Combine

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
final class UnifiedConfigurationManager: ConfigurationManaging, ObservableObject {
    // MARK: - Publishers
    private let configurationSubject = PassthroughSubject<Void, Never>()
    var configurationUpdates: AnyPublisher<Void, Never> {
        configurationSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let storage: StorageManaging
    private let queue = DispatchQueue(label: "de.knng.app.yeelightcontrol.config", qos: .userInitiated)
    private var cache: [ConfigKey: ConfigValue] = [:]
    
    // MARK: - Default Configuration
    private let defaults: [ConfigKey: ConfigValue] = [
        // Network defaults
        .discoveryTimeout: .timeInterval(30),
        .discoveryRetryCount: .int(3),
        .discoveryRetryDelay: .timeInterval(5),
        .useBonjourDiscovery: .bool(true),
        .ssdpDiscoveryPort: .int(1982),
        
        // Background defaults
        .minRefreshInterval: .timeInterval(15 * 60),
        .maxRetryAttempts: .int(3),
        .retryDelay: .timeInterval(5),
        .backgroundTaskTimeout: .timeInterval(30),
        
        // Location defaults
        .desiredAccuracy: .double(100),
        .distanceFilter: .double(100),
        .activityType: .int(0),
        .pausesLocationUpdatesAutomatically: .bool(true),
        .allowsBackgroundLocationUpdates: .bool(false),
        
        // Logger defaults
        .maxLogFileSize: .int(10 * 1024 * 1024),
        .maxLogFiles: .int(5),
        .minDiskSpace: .int(100 * 1024 * 1024),
        .rotationInterval: .timeInterval(24 * 60 * 60),
        .isFileLoggingEnabled: .bool(true),
        
        // App defaults
        .theme: .string("system"),
        .autoDiscoveryEnabled: .bool(true),
        .defaultTransitionDuration: .int(1000),
        .defaultBrightness: .int(100),
        .defaultColorTemperature: .int(4000)
    ]
    
    // MARK: - Initialization
    init(storage: StorageManaging) {
        self.storage = storage
        loadConfiguration()
    }
    
    // MARK: - Public Methods
    func getValue<T>(for key: ConfigKey) -> T? {
        queue.sync {
            guard let value = cache[key] else {
                return defaults[key]?.getValue()
            }
            return value.getValue()
        }
    }
    
    func setValue<T>(_ value: T, for key: ConfigKey) throws {
        try queue.sync {
            let configValue = ConfigValue(value: value)
            cache[key] = configValue
            try saveConfiguration()
            configurationSubject.send()
        }
    }
    
    func resetToDefaults() {
        queue.sync {
            cache = defaults
            try? saveConfiguration()
            configurationSubject.send()
        }
    }
    
    // MARK: - Private Methods
    private func loadConfiguration() {
        do {
            cache = try storage.load(forKey: .configuration)
        } catch {
            cache = defaults
            try? saveConfiguration()
        }
    }
    
    private func saveConfiguration() throws {
        try storage.save(cache, forKey: .configuration)
    }
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