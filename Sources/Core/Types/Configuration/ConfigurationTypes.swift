import Foundation
import Combine

// Typealiases are defined in ServiceContainer.swift
// Removing duplicate definitions to resolve ambiguity errors

// Core_Theme is defined in ThemeTypes.swift
// No need to redefine it here

public struct Core_Configuration: Codable, Hashable {
    public struct AppSettings: Codable, Hashable {
        public var theme: Core_Theme
        public var notificationsEnabled: Bool
        public var locationEnabled: Bool
        public var analyticsEnabled: Bool
        public var backgroundRefreshEnabled: Bool
        
        public init(theme: Core_Theme = .system,
                   notificationsEnabled: Bool = true,
                   locationEnabled: Bool = true,
                   analyticsEnabled: Bool = true,
                   backgroundRefreshEnabled: Bool = true) {
            self.theme = theme
            self.notificationsEnabled = notificationsEnabled
            self.locationEnabled = locationEnabled
            self.analyticsEnabled = analyticsEnabled
            self.backgroundRefreshEnabled = backgroundRefreshEnabled
        }
    }
    
    public var appSettings: AppSettings
    public var deviceSettings: [String: Core_ConfigValue]
    public var sceneSettings: [String: Core_ConfigValue]
    public var effectSettings: [String: Core_ConfigValue]
    
    public init(appSettings: AppSettings = AppSettings(),
                deviceSettings: [String: Core_ConfigValue] = [:],
                sceneSettings: [String: Core_ConfigValue] = [:],
                effectSettings: [String: Core_ConfigValue] = [:]) {
        self.appSettings = appSettings
        self.deviceSettings = deviceSettings
        self.sceneSettings = sceneSettings
        self.effectSettings = effectSettings
    }
}

// Core_ConfigKey is defined in ConfigurationProtocols.swift
// No need to redefine it here

public enum Core_ConfigValue: Codable, Hashable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case stringArray([String])
    case dictionary([String: String])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String].self) {
            self = .stringArray(value)
        } else if let value = try? container.decode([String: String].self) {
            self = .dictionary(value)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot decode ConfigValue"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .stringArray(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Configuration Error
public enum Core_ConfigurationError: Error, Hashable, Equatable {
    case valueNotFound(Core_ConfigKey)
    case invalidType
    case saveFailed
    case loadFailed
    
    public static func == (lhs: Core_ConfigurationError, rhs: Core_ConfigurationError) -> Bool {
        switch (lhs, rhs) {
        case (.valueNotFound(let lhsKey), .valueNotFound(let rhsKey)):
            return lhsKey == rhsKey
        case (.invalidType, .invalidType):
            return true
        case (.saveFailed, .saveFailed):
            return true
        case (.loadFailed, .loadFailed):
            return true
        default:
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .valueNotFound(let key):
            hasher.combine(0)
            hasher.combine(key)
        case .invalidType:
            hasher.combine(1)
        case .saveFailed:
            hasher.combine(2)
        case .loadFailed:
            hasher.combine(3)
        }
    }
} 