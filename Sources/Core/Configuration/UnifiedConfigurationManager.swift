import Foundation
import Combine
import SwiftUI

// MARK: - Configuration Managing Protocol
public protocol ConfigurationManaging {
    var configurationUpdates: AnyPublisher<Configuration, Never> { get }
    
    func getValue<T>(for key: ConfigKey) throws -> T
    func setValue<T>(_ value: T, for key: ConfigKey) throws
    func removeValue(for key: ConfigKey)
    func resetToDefaults()
}

// MARK: - Configuration Manager Implementation
@MainActor
public final class UnifiedConfigurationManager: ObservableObject, ConfigurationManaging {
    // MARK: - Published Properties
    @Published public private(set) var configuration: Configuration
    @Published public private(set) var isDirty = false
    
    // MARK: - Private Properties
    private let services: ServiceContainer
    private var cancellables = Set<AnyCancellable>()
    private let configurationSubject = CurrentValueSubject<Configuration, Never>(Configuration())
    private let storageManager: StorageManaging
    
    // MARK: - Constants
    private enum Constants {
        static let configFileName = "app_config.json"
        static let configFileExtension = "json"
        static let autosaveInterval: TimeInterval = 30
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedConfigurationManager()
    
    // MARK: - Initialization
    public init(services: ServiceContainer) {
        self.services = services
        self.storageManager = services.storageManager
        self.configuration = Configuration()
        
        setupObservers()
        loadConfiguration()
    }
    
    // MARK: - Configuration Management
    public func getValue<T>(for key: ConfigKey) throws -> T {
        guard let value = configuration.deviceSettings[key.rawValue] else {
            throw ConfigurationError.notFound
        }
        
        switch value {
        case .string(let stringValue) where T.self == String.self:
            return stringValue as! T
        case .int(let intValue) where T.self == Int.self:
            return intValue as! T
        case .double(let doubleValue) where T.self == Double.self:
            return doubleValue as! T
        case .bool(let boolValue) where T.self == Bool.self:
            return boolValue as! T
        default:
            throw ConfigurationError.invalidValue
        }
    }
    
    public func setValue<T>(_ value: T, for key: ConfigKey) throws {
        let configValue: ConfigValue
        
        switch value {
        case let stringValue as String:
            configValue = .string(stringValue)
        case let intValue as Int:
            configValue = .int(intValue)
        case let doubleValue as Double:
            configValue = .double(doubleValue)
        case let boolValue as Bool:
            configValue = .bool(boolValue)
        default:
            throw ConfigurationError.invalidValue
        }
        
        configuration.deviceSettings[key.rawValue] = configValue
        configurationSubject.send(configuration)
        try saveConfiguration()
    }
    
    public func removeValue(for key: ConfigKey) {
        configuration.deviceSettings.removeValue(forKey: key.rawValue)
        configurationSubject.send(configuration)
        try? saveConfiguration()
    }
    
    public func resetToDefaults() throws {
        configuration = Configuration()
        configurationSubject.send(configuration)
        try saveConfiguration()
    }
    
    // MARK: - ConfigurationManaging Protocol
    public var configurationUpdates: AnyPublisher<Configuration, Never> {
        configurationSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    private func loadConfiguration() {
        do {
            if let data = try storageManager.readData(fromFile: Constants.configFileName) {
                let decoder = JSONDecoder()
                configuration = try decoder.decode(Configuration.self, from: data)
            }
        } catch {
            print("Failed to load configuration: \(error)")
        }
        configurationSubject.send(configuration)
    }
    
    private func saveConfiguration() throws {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(configuration)
            try storageManager.writeData(data, toFile: Constants.configFileName)
        } catch {
            throw ConfigurationError.saveFailed
        }
    }
    
    private func setupObservers() {
        // Add any necessary observers here
    }
}