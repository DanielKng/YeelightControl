import Foundation
import Combine

// Create a typealias to disambiguate types
public typealias CoreConfigurationManaging = Core_ConfigurationManaging
public typealias CoreConfigKey = Core_ConfigKey
public typealias CoreConfigurationError = Core_ConfigurationError

// MARK: - Configuration Key
public enum ConfigKey: String, CaseIterable {
    case appTheme
    case deviceRefreshInterval
    case notificationsEnabled
    case analyticsEnabled
    case locationTrackingEnabled
    case backgroundRefreshEnabled
    case lastSyncDate
    case userPreferences
    case deviceSettings
    case sceneSettings
    case effectSettings
    case debugMode
    case apiEndpoint
    case apiKey
}

// MARK: - Configuration Managing Protocol
@preconcurrency public protocol ConfigurationManaging: Actor {
    var configurationUpdates: AnyPublisher<ConfigKey, Never> { get }
    
    func getValue<T>(for key: ConfigKey) async throws -> T
    func setValue<T>(_ value: T, for key: ConfigKey) async throws
    func removeValue(for key: ConfigKey) async throws
    func hasValue(for key: ConfigKey) async -> Bool
    func clearAll() async throws
}

// MARK: - Configuration Manager Implementation
public actor UnifiedConfigurationManager: Core_ConfigurationManaging {
    // MARK: - Properties
    private var configValues: [String: Any] = [:]
    private let storageManager: any Core_StorageManaging
    private let configSubject = PassthroughSubject<Core_ConfigKey, Never>()
    
    // MARK: - Initialization
    public init(storageManager: any Core_StorageManaging) {
        self.storageManager = storageManager
        
        Task {
            await loadConfiguration()
        }
    }
    
    // MARK: - Core_BaseService
    public var serviceIdentifier: String {
        return "core.configuration"
    }
    
    public var values: [Core_ConfigKey: Any] {
        var result: [Core_ConfigKey: Any] = [:]
        for (key, value) in configValues {
            if let configKey = Core_ConfigKey(rawValue: key) {
                result[configKey] = value
            }
        }
        return result
    }
    
    // MARK: - Core_ConfigurationManaging
    
    public var configurationUpdates: AnyPublisher<Core_ConfigKey, Never> {
        configSubject.eraseToAnyPublisher()
    }
    
    public func getValue<T>(for key: Core_ConfigKey) throws -> T {
        guard let value = configValues[key.rawValue] as? T else {
            throw Core_ConfigurationError.valueNotFound(key)
        }
        return value
    }
    
    public func setValue<T>(_ value: T, for key: Core_ConfigKey) throws {
        configValues[key.rawValue] = value
        configSubject.send(key)
        
        // Save to storage
        Task {
            try await saveConfiguration()
        }
    }
    
    public func removeValue(for key: Core_ConfigKey) throws {
        configValues.removeValue(forKey: key.rawValue)
        configSubject.send(key)
        
        // Save to storage
        Task {
            try await saveConfiguration()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadConfiguration() async {
        do {
            let config: [String: Any] = try await storageManager.load(forKey: "configuration")
            self.configValues = config
        } catch {
            print("Error loading configuration: \(error.localizedDescription)")
            // Initialize with default values
            initializeDefaults()
        }
    }
    
    private func saveConfiguration() async throws {
        try await storageManager.save(configValues, forKey: "configuration")
    }
    
    private func initializeDefaults() {
        // Set default values for Core_ConfigKey cases
        configValues[Core_ConfigKey.appTheme.rawValue] = "system"
        configValues[Core_ConfigKey.deviceRefreshInterval.rawValue] = 30.0
        configValues[Core_ConfigKey.notificationsEnabled.rawValue] = true
        configValues[Core_ConfigKey.analyticsEnabled.rawValue] = false
        configValues[Core_ConfigKey.locationEnabled.rawValue] = false
        configValues[Core_ConfigKey.debugMode.rawValue] = false
    }
}

// MARK: - Configuration Error
public enum ConfigurationError: Error {
    case valueNotFound(ConfigKey)
    case invalidType
    case saveFailed
    case loadFailed
}
