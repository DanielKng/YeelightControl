import Foundation

public enum Theme: String, Codable, Hashable {
    case system
    case light
    case dark
}

public struct Configuration: Codable, Hashable {
    public struct AppSettings: Codable, Hashable {
        public var theme: Theme
        public var notificationsEnabled: Bool
        public var locationEnabled: Bool
        public var analyticsEnabled: Bool
        public var backgroundRefreshEnabled: Bool
        
        public init(theme: Theme = .system,
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
    public var deviceSettings: [String: ConfigValue]
    public var sceneSettings: [String: ConfigValue]
    public var effectSettings: [String: ConfigValue]
    
    public init(appSettings: AppSettings = AppSettings(),
                deviceSettings: [String: ConfigValue] = [:],
                sceneSettings: [String: ConfigValue] = [:],
                effectSettings: [String: ConfigValue] = [:]) {
        self.appSettings = appSettings
        self.deviceSettings = deviceSettings
        self.sceneSettings = sceneSettings
        self.effectSettings = effectSettings
    }
}

public enum ConfigKey: String, Codable, Hashable {
    case theme
    case notifications
    case location
    case analytics
    case backgroundRefresh
    case deviceSettings
    case sceneSettings
    case effectSettings
}

public enum ConfigValue: Codable, Hashable {
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
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ConfigValue type")
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