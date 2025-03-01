import SwiftUI
import Foundation
import CoreLocation

// Create typealiases to disambiguate types
public typealias CoreYeelightDeviceState = Core_YeelightDeviceState
public typealias CoreRGB = Core_RGB
public typealias CoreColorMode = Core_ColorMode
public typealias CoreYeelightDeviceStateUpdate = Core_YeelightDeviceStateUpdate

public struct Core_YeelightDeviceState: Codable, Equatable {
    public var power: Bool
    public var brightness: Int
    public var colorTemperature: Int
    public var colorMode: Core_ColorMode
    public var rgb: Core_RGB
    public var hue: Int
    public var saturation: Int
    public var name: String
    public var location: Location?
    public var lastUpdated: Date
    public var isOnline: Bool
    public var lastSeen: Date
    
    public init(
        power: Bool = false,
        brightness: Int = 100,
        colorTemperature: Int = 4000,
        colorMode: Core_ColorMode = .temperature,
        rgb: Core_RGB = Core_RGB(),
        hue: Int = 0,
        saturation: Int = 0,
        name: String = "",
        location: Location? = nil,
        lastUpdated: Date = Date(),
        isOnline: Bool = false,
        lastSeen: Date = Date()
    ) {
        self.power = power
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.colorMode = colorMode
        self.rgb = rgb
        self.hue = hue
        self.saturation = saturation
        self.name = name
        self.location = location
        self.lastUpdated = lastUpdated
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
    
    public static func == (lhs: Core_YeelightDeviceState, rhs: Core_YeelightDeviceState) -> Bool {
        return lhs.power == rhs.power &&
            lhs.brightness == rhs.brightness &&
            lhs.colorMode == rhs.colorMode &&
            lhs.colorTemperature == rhs.colorTemperature &&
            lhs.rgb == rhs.rgb &&
            lhs.hue == rhs.hue &&
            lhs.saturation == rhs.saturation
    }
}

public struct Core_RGB: Codable, Equatable {
    public var red: Int
    public var green: Int
    public var blue: Int
    
    public init(red: Int = 255, green: Int = 255, blue: Int = 255) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public enum Core_ColorMode: Int, Codable {
    case rgb = 1
    case temperature = 2
    case hsv = 3
    
    public var displayName: String {
        switch self {
        case .rgb:
            return "RGB"
        case .temperature:
            return "Temperature"
        case .hsv:
            return "HSV"
        }
    }
}

public struct Core_YeelightDeviceStateUpdate: Codable, Equatable {
    public let deviceId: String
    public let state: Core_YeelightDeviceState
    public let timestamp: Date
    
    public init(deviceId: String, state: Core_YeelightDeviceState, timestamp: Date = Date()) {
        self.deviceId = deviceId
        self.state = state
        self.timestamp = timestamp
    }
} 