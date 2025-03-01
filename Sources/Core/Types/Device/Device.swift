import SwiftUI
import Foundation

public struct Device: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public var state: DeviceState
    public var isOnline: Bool
    public var lastSeen: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: DeviceType,
        state: DeviceState = .init(),
        isOnline: Bool = false,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.state = state
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
    
    public init(yeelight: Yeelight) {
        self.id = yeelight.id
        self.name = yeelight.name
        self.type = .yeelight(yeelight)
        self.state = yeelight.state
        self.isOnline = yeelight.isOnline
        self.lastSeen = yeelight.lastSeen
    }
}

public enum DeviceType: Codable, Hashable {
    case yeelight(Yeelight)
    
    public var displayName: String {
        switch self {
        case .yeelight:
            return "Yeelight"
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
}

public struct DeviceColor: Codable, Hashable {
    public var red: Int
    public var green: Int
    public var blue: Int
    
    public static let white = DeviceColor(red: 255, green: 255, blue: 255)
    
    public init(red: Int = 255, green: Int = 255, blue: Int = 255) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public struct DeviceStateUpdate: Codable, Hashable {
    public let deviceId: String
    public let state: DeviceState
    
    public init(deviceId: String, state: DeviceState) {
        self.deviceId = deviceId
        self.state = state
    }
} 