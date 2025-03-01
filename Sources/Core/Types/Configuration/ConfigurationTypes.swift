import Foundation
import Combine

// Create typealiases to disambiguate types
public typealias CoreTheme = Core_Theme
public typealias CoreConfiguration = Core_Configuration
public typealias CoreConfigValue = Core_ConfigValue

// Core_Theme is defined in UnifiedThemeManager.swift
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

// Use the ConfigKey from ConfigurationProtocols.swift
// public enum ConfigKey: String, Codable, Hashable {
//     case theme
//     case notifications
//     case location
//     case analytics
//     case backgroundRefresh
//     case deviceSettings
//     case sceneSettings
//     case effectSettings
//     case configuration
// }

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

// Use the Core_ConfigurationError from ConfigurationProtocols.swift
// public enum ConfigurationError: LocalizedError {
//     case valueNotFound
//     case unsupportedType
//     case saveFailed
//     case loadFailed
//     
//     public var errorDescription: String? {
//         switch self {
//         case .valueNotFound:
//             return "Configuration value not found"
//         case .unsupportedType:
//             return "Unsupported configuration value type"
//         case .saveFailed:
//             return "Failed to save configuration"
//         case .loadFailed:
//             return "Failed to load configuration"
//         }
//     }
// } 