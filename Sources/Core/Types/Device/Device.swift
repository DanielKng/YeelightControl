import SwiftUI
import Foundation

// MARK: - Core Device

public struct Core_Device: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let type: Core_DeviceType
    public let manufacturer: String
    public let model: String
    public let firmwareVersion: String?
    public let ipAddress: String?
    public let macAddress: String?
    public var state: DeviceState?
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
        state: DeviceState? = nil,
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
public typealias Core_Device = Device

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
        manufacturer: String,
        model: String,
        firmwareVersion: String? = nil,
        ipAddress: String? = nil,
        macAddress: String? = nil,
        state: Core_DeviceState = .unknown,
        isConnected: Bool = false,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = DeviceType.from(coreType: type)
        self.manufacturer = manufacturer
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.state = DeviceState.from(coreState: state)
        self.isConnected = isConnected
        self.isOnline = isConnected
        self.lastSeen = lastSeen
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
    
    public init(
        power: Bool = false,
        brightness: Int = 100,
        colorTemperature: Int = 4000,
        color: DeviceColor = .white,
        effect: Effect? = nil
    ) {
        self.power = power
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.color = color
        self.effect = effect
    }
    
    // Convert from Core_DeviceState
    public static func from(coreState: Core_DeviceState) -> DeviceState {
        switch coreState {
        case .on(let brightness, let color):
            return DeviceState(
                power: true,
                brightness: brightness,
                colorTemperature: 4000, // Default
                color: DeviceColor(
                    red: Int(color.red * 255),
                    green: Int(color.green * 255),
                    blue: Int(color.blue * 255)
                )
            )
        case .off:
            return DeviceState(power: false)
        case .unknown:
            return DeviceState()
        }
    }
    
    // Convert to Core_DeviceState
    public var coreState: Core_DeviceState {
        if power {
            let coreColor = Core_Color(
                red: Double(color.red) / 255.0,
                green: Double(color.green) / 255.0,
                blue: Double(color.blue) / 255.0
            )
            return .on(brightness: brightness, color: coreColor)
        } else {
            return .off
        }
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
            type: .light,
            state: DeviceState(
                power: yeelightDevice.state.power,
                brightness: yeelightDevice.state.brightness,
                colorTemperature: yeelightDevice.state.colorTemperature,
                color: DeviceColor(
                    red: yeelightDevice.state.color.red,
                    green: yeelightDevice.state.color.green,
                    blue: yeelightDevice.state.color.blue
                ),
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