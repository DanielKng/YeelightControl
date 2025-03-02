import SwiftUI
import Foundation
// Remove the import for YeelightTypes since it's in the same module (Core)
// import YeelightTypes

// MARK: - Core Device

// Commented out to avoid ambiguity
// Commented out to avoid ambiguity
public struct Core_Device: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let type: Core_DeviceType
    public let manufacturer: String
    public let model: String
    public let firmwareVersion: String?
    public let ipAddress: String?
    public let macAddress: String?
    public var state: Core_DeviceState?
    public var isConnected: Bool?
    public var lastSeen: Date?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: Core_DeviceType,
        manufacturer: String,
        model: String,
        firmwareVersion: String? = nil,
        ipAddress: String? = nil,
        macAddress: String? = nil,
        state: Core_DeviceState? = nil,
        isConnected: Bool? = nil,
        lastSeen: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.manufacturer = manufacturer
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.state = state
        self.isConnected = isConnected
        self.lastSeen = lastSeen
    }
}

// MARK: - Device Type

// Make Device the implementation of Core_Device
// // // public typealias Core_Device = Device

public struct Device: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public var state: DeviceState
    public var isOnline: Bool
    public var lastSeen: Date
    public var isConnected: Bool
    
    // Additional properties required by Core_Device
    public let manufacturer: String
    public let model: String
    public let firmwareVersion: String?
    public let ipAddress: String?
    public let macAddress: String?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: DeviceType,
        state: DeviceState = .init(),
        isOnline: Bool = false,
        lastSeen: Date = Date(),
        isConnected: Bool = false,
        manufacturer: String = "Yeelight",
        model: String = "Unknown",
        firmwareVersion: String? = nil,
        ipAddress: String? = nil,
        macAddress: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.state = state
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.isConnected = isConnected
        self.manufacturer = manufacturer
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.ipAddress = ipAddress
        self.macAddress = macAddress
    }
    
    public init(yeelight: Yeelight) {
        self.id = yeelight.id
        self.name = yeelight.name
        self.type = .yeelight(yeelight)
        self.state = yeelight.state
        self.isOnline = yeelight.isOnline
        self.lastSeen = yeelight.lastSeen
        self.isConnected = yeelight.isOnline
        self.manufacturer = "Yeelight"
        self.model = yeelight.model.rawValue
        self.firmwareVersion = yeelight.firmwareVersion
        self.ipAddress = yeelight.ipAddress
        self.macAddress = nil
    }
    
    // Initialize from Core_DeviceType
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: Core_DeviceType,
        manufacturer: String = "Unknown",
        model: String = "Unknown",
        firmwareVersion: String? = nil,
        ipAddress: String? = nil,
        macAddress: String? = nil,
        state: Core_DeviceState? = nil,
        isConnected: Bool? = nil,
        lastSeen: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = DeviceType.from(coreType: type)
        self.manufacturer = manufacturer
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        
        // Create a default state if none is provided
        let defaultState = DeviceState()
        
        // Use the provided state if available, otherwise use default
        if let coreState = state {
            self.state = DeviceState(
                power: coreState.power,
                brightness: coreState.brightness,
                colorTemperature: coreState.colorTemperature,
                color: DeviceColor(
                    red: coreState.color.red,
                    green: coreState.color.green,
                    blue: coreState.color.blue
                ),
                effect: coreState.effect,
                isOnline: coreState.isOnline,
                lastSeen: coreState.lastSeen,
                mode: coreState.mode
            )
        } else {
            self.state = defaultState
        }
        
        self.isConnected = isConnected ?? false
        self.lastSeen = lastSeen ?? Date()
        self.isOnline = isConnected ?? false  // Initialize isOnline based on isConnected
    }
}

public enum DeviceType: Codable, Hashable {
    case bulb
    case strip
    case yeelight(Yeelight)
    
    public var displayName: String {
        switch self {
        case .yeelight:
            return "Yeelight"
        case .bulb:
            return "Bulb"
        case .strip:
            return "Strip"
        }
    }
    
    // Convert from Core_DeviceType
    public static func from(coreType: Core_DeviceType) -> DeviceType {
        switch coreType {
        case .bulb:
            return .bulb
        case .strip:
            return .strip
        case .lamp, .ceiling, .ambient, .unknown:
            return .bulb // Default mapping
        }
    }
    
    // Convert to Core_DeviceType
    public var coreType: Core_DeviceType {
        switch self {
        case .bulb:
            return .bulb
        case .strip:
            return .strip
        case .yeelight:
            return .bulb // Default mapping
        }
    }
}

public struct DeviceState: Codable, Hashable {
    public var power: Bool
    public var brightness: Int
    public var colorTemperature: Int
    public var color: DeviceColor
    public var effect: Effect?
    public var isOnline: Bool
    public var lastSeen: Date
    public var mode: YeelightMode?
    
    public init(
        power: Bool = false,
        brightness: Int = 100,
        colorTemperature: Int = 4000,
        color: DeviceColor = .white,
        effect: Effect? = nil,
        isOnline: Bool = false,
        lastSeen: Date = Date(),
        mode: YeelightMode? = .normal
    ) {
        self.power = power
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.color = color
        self.effect = effect
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.mode = mode
    }
    
    // Convert from Core_DeviceState
    public static func from(coreState: Core_DeviceState) -> DeviceState {
        return DeviceState(
            power: coreState.power,
            brightness: coreState.brightness,
            colorTemperature: coreState.colorTemperature,
            color: DeviceColor(
                red: coreState.color.red,
                green: coreState.color.green,
                blue: coreState.color.blue
            ),
            effect: coreState.effect,
            isOnline: coreState.isOnline,
            lastSeen: coreState.lastSeen,
            mode: coreState.mode
        )
    }
    
    // Convert to Core_DeviceState
    public var coreState: Core_DeviceState {
        return Core_DeviceState(
            power: power,
            brightness: brightness,
            colorTemperature: colorTemperature,
            color: Core_DeviceColor(
                red: color.red,
                green: color.green,
                blue: color.blue
            ),
            effect: effect,
            isOnline: isOnline,
            lastSeen: lastSeen,
            mode: mode
        )
    }
}

public struct DeviceColor: Codable, Hashable {
    public var red: Int
    public var green: Int
    public var blue: Int
    
    public static let white = DeviceColor(red: 255, green: 255, blue: 255)
    public static let red = DeviceColor(red: 255, green: 0, blue: 0)
    public static let green = DeviceColor(red: 0, green: 255, blue: 0)
    public static let blue = DeviceColor(red: 0, green: 0, blue: 255)
    
    public init(red: Int = 255, green: Int = 255, blue: Int = 255) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

// MARK: - Device State Update

public struct DeviceStateUpdate: Codable, Hashable {
    public let deviceId: String
    public let state: DeviceState
    public let timestamp: Date
    
    public init(deviceId: String, state: DeviceState, timestamp: Date = Date()) {
        self.deviceId = deviceId
        self.state = state
        self.timestamp = timestamp
    }
}

// MARK: - Location

public struct Location: Codable, Hashable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?
    public let horizontalAccuracy: Double?
    public let verticalAccuracy: Double?
    public let timestamp: Date
    
    public init(
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        horizontalAccuracy: Double? = nil,
        verticalAccuracy: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.timestamp = timestamp
    }
}

// MARK: - Conversion Methods

extension Device {
    public static func from(yeelightDevice: YeelightDevice) -> Device {
        return Device(
            id: yeelightDevice.id,
            name: yeelightDevice.name,
            type: .bulb,
            state: DeviceState(
                power: yeelightDevice.state.power,
                brightness: yeelightDevice.state.brightness,
                colorTemperature: yeelightDevice.state.colorTemperature,
                color: DeviceColor(
                    red: yeelightDevice.state.color.red,
                    green: yeelightDevice.state.color.green,
                    blue: yeelightDevice.state.color.blue
                ),
                effect: yeelightDevice.state.effect,
                isOnline: yeelightDevice.isOnline,
                lastSeen: yeelightDevice.lastSeen,
                mode: yeelightDevice.state.mode
            ),
            isOnline: yeelightDevice.isOnline,
            lastSeen: yeelightDevice.lastSeen,
            isConnected: yeelightDevice.isConnected,
            manufacturer: "Yeelight",
            model: yeelightDevice.model.rawValue,
            firmwareVersion: yeelightDevice.firmwareVersion,
            ipAddress: yeelightDevice.ipAddress,
            macAddress: nil
        )
    }
} 