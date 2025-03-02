import SwiftUI
import Core

// MARK: - Device

/// Device type for UI components
public struct Device: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let manufacturer: String
    public let model: String
    public let firmwareVersion: String
    public var isConnected: Bool
    public var lastSeen: Date
    public var capabilities: [DeviceCapability]
    public var state: UI_DeviceState
    
    public init(
        id: String,
        name: String,
        type: DeviceType,
        manufacturer: String,
        model: String,
        firmwareVersion: String,
        isConnected: Bool = false,
        lastSeen: Date = Date(),
        capabilities: [DeviceCapability] = [],
        state: UI_DeviceState = UI_DeviceState()
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
        self.state = state
    }
    
    // Convert from Core_Device
    public static func from(coreDevice: Core_Device) -> Device {
        let deviceType: DeviceType
        switch coreDevice.type {
        case .light:
            deviceType = .light
        case .sensor:
            deviceType = .sensor
        case .switch_:
            deviceType = .switch
        default:
            deviceType = .other
        }
        
        let capabilities: [DeviceCapability] = []
        // In a real implementation, we would map capabilities based on device type
        
        return Device(
            id: coreDevice.id,
            name: coreDevice.name,
            type: deviceType,
            manufacturer: coreDevice.manufacturer,
            model: coreDevice.model,
            firmwareVersion: coreDevice.firmwareVersion ?? "unknown",
            isConnected: coreDevice.isConnected ?? false,
            lastSeen: coreDevice.lastSeen ?? Date(),
            capabilities: capabilities,
            state: coreDevice.state?.uiState ?? UI_DeviceState()
        )
    }
    
    // Convert from YeelightDevice
    public static func from(yeelightDevice: YeelightDevice) -> Device {
        let capabilities: [DeviceCapability] = [.onOff, .brightness]
        
        // Add color capabilities based on model
        if yeelightDevice.model == .colorLEDBulb || yeelightDevice.model == .colorLEDStrip {
            capabilities.append(.color)
            capabilities.append(.colorTemperature)
        } else if yeelightDevice.model == .ceilingLight || yeelightDevice.model == .deskLamp {
            capabilities.append(.colorTemperature)
        }
        
        return Device(
            id: yeelightDevice.id,
            name: yeelightDevice.name,
            type: .light,
            manufacturer: "Yeelight",
            model: yeelightDevice.model.displayName,
            firmwareVersion: yeelightDevice.firmwareVersion,
            isConnected: yeelightDevice.isOnline,
            lastSeen: yeelightDevice.lastSeen,
            capabilities: capabilities,
            state: yeelightDevice.state.uiState
        )
    }
}

public enum DeviceType: String, CaseIterable {
    case light
    case sensor
    case switch
    case other
    
    public var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .sensor:
            return "Sensor"
        case .switch:
            return "Switch"
        case .other:
            return "Other"
        }
    }
}

public enum DeviceCapability: String, CaseIterable {
    case onOff
    case brightness
    case color
    case colorTemperature
    case effects
    case scenes
    case scheduling
    case sensors
    
    public var displayName: String {
        switch self {
        case .onOff:
            return "On/Off"
        case .brightness:
            return "Brightness"
        case .color:
            return "Color"
        case .colorTemperature:
            return "Color Temperature"
        case .effects:
            return "Effects"
        case .scenes:
            return "Scenes"
        case .scheduling:
            return "Scheduling"
        case .sensors:
            return "Sensors"
        }
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
}

public enum EffectType: String, CaseIterable {
    case colorFlow
    case pulse
    case strobe
    case candle
    case music
    case custom
    
    public var displayName: String {
        switch self {
        case .colorFlow:
            return "Color Flow"
        case .pulse:
            return "Pulse"
        case .strobe:
            return "Strobe"
        case .candle:
            return "Candle"
        case .music:
            return "Music"
        case .custom:
            return "Custom"
        }
    }
}

public struct EffectParameters: Codable, Equatable {
    public var duration: Int?
    public var colors: [Color]?
    public var speed: Int?
    public var intensity: Int?
    public var customData: [String: AnyCodable]?
    
    public init(
        duration: Int? = nil,
        colors: [Color]? = nil,
        speed: Int? = nil,
        intensity: Int? = nil,
        customData: [String: AnyCodable]? = nil
    ) {
        self.duration = duration
        self.colors = colors
        self.speed = speed
        self.intensity = intensity
        self.customData = customData
    }
}

// MARK: - Scene

/// Scene type for UI components
public protocol YeelightScene: Identifiable, Equatable {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var type: SceneType { get }
    var brightness: Int? { get }
    var colorTemperature: Int? { get }
    var color: Color? { get }
    var isBuiltIn: Bool { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

public struct Scene: YeelightScene {
    public let id: String
    public let name: String
    public let description: String
    public let type: SceneType
    public let brightness: Int?
    public let colorTemperature: Int?
    public let color: Color?
    public let isBuiltIn: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        name: String,
        description: String,
        type: SceneType,
        brightness: Int? = nil,
        colorTemperature: Int? = nil,
        color: Color? = nil,
        isBuiltIn: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.color = color
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public static func == (lhs: Scene, rhs: Scene) -> Bool {
        return lhs.id == rhs.id
    }
}

public enum SceneType: String, CaseIterable {
    case custom
    case night
    case reading
    case movie
    case party
    
    public var displayName: String {
        switch self {
        case .custom:
            return "Custom"
        case .night:
            return "Night"
        case .reading:
            return "Reading"
        case .movie:
            return "Movie"
        case .party:
            return "Party"
        }
    }
}

// MARK: - Room

/// Room type for UI components
public struct Room: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let icon: String
    public var deviceIds: [String]
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        icon: String = "house",
        deviceIds: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.deviceIds = deviceIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public static func == (lhs: Room, rhs: Room) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Theme

/// Theme type for UI components
public struct Theme: Equatable {
    public let primaryColor: Color
    public let secondaryColor: Color
    public let accentColor: Color
    public let backgroundColor: Color
    public let textColor: Color
    public let isDark: Bool
    
    public static let `default` = Theme(
        primaryColor: .blue,
        secondaryColor: .purple,
        accentColor: .orange,
        backgroundColor: .white,
        textColor: .black,
        isDark: false
    )
    
    public static let dark = Theme(
        primaryColor: .blue,
        secondaryColor: .purple,
        accentColor: .orange,
        backgroundColor: .black,
        textColor: .white,
        isDark: true
    )
}

// MARK: - Connection Type

/// Connection type for UI components
public enum ConnectionType: String, CaseIterable {
    case wifi
    case bluetooth
    case internet
    
    public var displayName: String {
        switch self {
        case .wifi:
            return "Wi-Fi"
        case .bluetooth:
            return "Bluetooth"
        case .internet:
            return "Internet"
        }
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
} 