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
        let task = Task {
            await _configValues
        }
        return (try? task.value) ?? [:]
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
        let task = Task { () -> T in
            guard let value = await configValues[key.rawValue] as? T else {
                throw Core_ConfigurationError.valueNotFound(key)
            }
            return value
        }
        
        do {
            return try task.result.get()
        } catch {
            if let configError = error as? Core_ConfigurationError {
                throw configError
            } else {
                throw Core_ConfigurationError.valueNotFound(key)
            }
        }
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
