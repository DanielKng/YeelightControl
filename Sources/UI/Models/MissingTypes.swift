import SwiftUI
import Core

// MARK: - Device

/// Device type for UI components
public struct Device: Identifiable, Equatable, Codable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let manufacturer: String
    public let model: String
    public let firmwareVersion: String
    public let isConnected: Bool
    public let lastSeen: Date
    public let capabilities: [DeviceCapability]
    
    public init(
        id: String,
        name: String,
        type: DeviceType,
        manufacturer: String,
        model: String,
        firmwareVersion: String,
        isConnected: Bool,
        lastSeen: Date,
        capabilities: [DeviceCapability]
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.manufacturer = manufacturer
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.isConnected = isConnected
        self.lastSeen = lastSeen
        self.capabilities = capabilities
    }
    
    public enum DeviceType: String, Codable {
        case light, sensor, switch_, outlet, fan, thermostat, camera, speaker, other
    }
    
    public enum DeviceCapability: String, Codable {
        case onOff, brightness, colorTemperature, color, effects, scenes, scheduling, grouping, other
    }
}

// MARK: - DeviceState

/// Device state for UI components
public struct DeviceState: Equatable, Codable {
    public var isOn: Bool
    public var brightness: Double?
    public var colorTemperature: Double?
    public var color: Color?
    public var mode: String?
    public var activeEffect: String?
    
    public init(
        isOn: Bool = true,
        brightness: Double? = nil,
        colorTemperature: Double? = nil,
        color: Color? = nil,
        mode: String? = nil,
        activeEffect: String? = nil
    ) {
        self.isOn = isOn
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.color = color
        self.mode = mode
        self.activeEffect = activeEffect
    }
}

// MARK: - Effect

/// Effect type for UI components
public struct Effect: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let type: EffectType
    public let parameters: EffectParameters
    public let isBuiltIn: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        name: String,
        description: String,
        type: EffectType,
        parameters: EffectParameters,
        isBuiltIn: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.parameters = parameters
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public enum EffectType: String, Codable, Equatable {
        case colorFlow, pulse, strobe, candle, music, custom
    }
}

// MARK: - EffectParameters

/// Effect parameters for UI components
public struct EffectParameters: Equatable {
    public var duration: TimeInterval
    public var speed: Double
    public var intensity: Double
    public var colors: [Color]
    public var flowTransitions: [FlowTransition]
    public var flowParams: FlowParams
    public var customProperties: [String: Any]
    
    public init(
        duration: TimeInterval = 0,
        speed: Double = 0.5,
        intensity: Double = 0.5,
        colors: [Color] = [],
        flowTransitions: [FlowTransition] = [],
        flowParams: FlowParams = FlowParams(),
        customProperties: [String: Any] = [:]
    ) {
        self.duration = duration
        self.speed = speed
        self.intensity = intensity
        self.colors = colors
        self.flowTransitions = flowTransitions
        self.flowParams = flowParams
        self.customProperties = customProperties
    }
}

// MARK: - FlowParams

/// Flow parameters for UI components
public struct FlowParams: Equatable {
    public var count: Int
    public var action: FlowAction
    
    public init(count: Int = 0, action: FlowAction = .recover) {
        self.count = count
        self.action = action
    }
    
    public enum FlowAction: Int, Codable, Equatable {
        case recover = 0
        case stay = 1
        case turnOff = 2
    }
    
    public static func == (lhs: FlowParams, rhs: FlowParams) -> Bool {
        return lhs.count == rhs.count && lhs.action == rhs.action
    }
}

// MARK: - FlowTransition

/// Flow transition for UI components
public struct FlowTransition: Identifiable, Equatable {
    public let id: String
    public var duration: TimeInterval
    public var mode: TransitionMode
    public var value: TransitionValue
    public var brightness: Double
    
    public init(
        id: String = UUID().uuidString,
        duration: TimeInterval = 1.0,
        mode: TransitionMode = .color,
        value: TransitionValue = .color(.red),
        brightness: Double = 100
    ) {
        self.id = id
        self.duration = duration
        self.mode = mode
        self.value = value
        self.brightness = brightness
    }
    
    public enum TransitionMode: Int, Codable, Equatable {
        case color = 1
        case temperature = 2
        case sleep = 7
    }
    
    public enum TransitionValue: Equatable {
        case color(Color)
        case temperature(Double)
        case sleep
        
        public var description: String {
            switch self {
            case .color(let color):
                return "Color"
            case .temperature(let temp):
                return "Temperature (\(Int(temp))K)"
            case .sleep:
                return "Sleep"
            }
        }
    }
}

// MARK: - Room

/// Room type for UI components
public struct Room: Identifiable, Equatable, Codable {
    public let id: String
    public let name: String
    public let deviceIds: [String]
    public let icon: String
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        deviceIds: [String] = [],
        icon: String = "house",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.deviceIds = deviceIds
        self.icon = icon
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - DeviceGroup

/// Device group type for UI components
public struct DeviceGroup: Identifiable, Equatable, Codable {
    public let id: String
    public let name: String
    public let deviceIds: [String]
    public let icon: String
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        deviceIds: [String] = [],
        icon: String = "lightbulb.fill",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.deviceIds = deviceIds
        self.icon = icon
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - MultiLightScene

/// Multi-light scene type for UI components
public struct MultiLightScene: YeelightScene {
    public let id: String
    public let name: String
    public let description: String?
    public let deviceIds: [String]
    public let deviceSettings: [String: DeviceSettings]
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        deviceIds: [String] = [],
        deviceSettings: [String: DeviceSettings] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.deviceIds = deviceIds
        self.deviceSettings = deviceSettings
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public static func == (lhs: MultiLightScene, rhs: MultiLightScene) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - StripEffect

/// Strip effect type for UI components
public struct StripEffect: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let colors: [Color]
    public let speed: Double
    public let direction: Direction
    public let pattern: Pattern
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        colors: [Color],
        speed: Double = 0.5,
        direction: Direction = .forward,
        pattern: Pattern = .solid
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.colors = colors
        self.speed = speed
        self.direction = direction
        self.pattern = pattern
    }
    
    public enum Direction: String, Codable {
        case forward, backward, alternate
    }
    
    public enum Pattern: String, Codable {
        case solid, gradient, chase, pulse, rainbow, fire, water
    }
} 