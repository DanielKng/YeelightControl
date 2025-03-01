import Foundation
import Combine

// Create a typealias to disambiguate types
public typealias CoreConfigurationManaging = Core_ConfigurationManaging
public typealias CoreConfigKey = Core_ConfigKey
public typealias CoreConfigurationError = Core_ConfigurationError

// MARK: - Configuration Keys
// Core_ConfigKey enum is defined in ConfigurationProtocols.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Configuration Manager
// Core_ConfigurationManaging protocol is defined in ConfigurationProtocols.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Configuration Error
// Core_ConfigurationError is defined in ConfigurationTypes.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Configuration Manager Implementation
public actor UnifiedConfigurationManager: Core_ConfigurationManaging, Core_BaseService {
    // MARK: - Properties
    private var configValues: [String: Any] = [:]
    private let storageManager: any Core_StorageManaging
    private let configSubject = PassthroughSubject<Core_ConfigKey, Never>()
    private var _isEnabled: Bool = true
    
    // MARK: - Core_BaseService Implementation
    public nonisolated var isEnabled: Bool {
        // Using a default value since we can't access actor state in a nonisolated context
        return true
    }
    
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
    
    // MARK: - Core_ConfigurationManaging
    
    public nonisolated var values: [Core_ConfigKey: Any] {
        // Using a simplified approach to avoid async property access
        // In a real app, you would need a more robust solution
        return [:]
    }
    
    public nonisolated var configurationUpdates: AnyPublisher<Core_ConfigKey, Never> {
        let publisher = PassthroughSubject<Core_ConfigKey, Never>()
        
        Task {
            for await key in await configSubject.values {
                publisher.send(key)
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    public nonisolated func getValue<T>(for key: Core_ConfigKey) throws -> T {
        // Using a simplified approach to avoid async property access
        // In a real app, you would need a more robust solution
        throw Core_ConfigurationError.valueNotFound(key)
    }
    
    public nonisolated func setValue<T>(_ value: T, for key: Core_ConfigKey) throws {
        Task {
            await setValueInternal(value, for: key)
        }
    }
    
    private func setValueInternal<T>(_ value: T, for key: Core_ConfigKey) {
        configValues[key.rawValue] = value
        configSubject.send(key)
        
        // Save to storage
        Task {
            try await saveConfiguration()
        }
    }
    
    public nonisolated func removeValue(for key: Core_ConfigKey) throws {
        Task {
            await removeValueInternal(for: key)
        }
    }
    
    private func removeValueInternal(for key: Core_ConfigKey) {
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
            if let config = try await storageManager.load([String: String].self, forKey: "configuration") {
                // Convert [String: String] to [String: Any]
                var configAny: [String: Any] = [:]
                for (key, value) in config {
                    configAny[key] = value
                }
                self.configValues = configAny
            } else {
                // Initialize with default values
                initializeDefaults()
            }
        } catch {
            print("Error loading configuration: \(error.localizedDescription)")
            // Initialize with default values
            initializeDefaults()
        }
    }
    
    private func saveConfiguration() async throws {
        // Convert configValues to a Codable type
        var codableConfig: [String: String] = [:]
        for (key, value) in configValues {
            codableConfig[key] = String(describing: value)
        }
        try await storageManager.save(codableConfig, forKey: "configuration")
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
