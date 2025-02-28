import Foundation
import CoreLocation

public struct DeviceState: Codable, Equatable {
    public var power: Bool
    public var brightness: Int
    public var colorTemperature: Int
    public var rgb: Int
    public var hue: Int
    public var saturation: Int
    public var name: String
    public var location: Location?
    public var lastUpdated: Date
    public var isOnline: Bool
    public var lastSeen: Date
    
    public init(power: Bool = false,
                brightness: Int = 100,
                colorTemperature: Int = 4000,
                rgb: Int = 0xFFFFFF,
                hue: Int = 0,
                saturation: Int = 0,
                name: String = "",
                location: Location? = nil,
                lastUpdated: Date = Date(),
                isOnline: Bool = false,
                lastSeen: Date = Date()) {
        self.power = power
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.rgb = rgb
        self.hue = hue
        self.saturation = saturation
        self.name = name
        self.location = location
        self.lastUpdated = lastUpdated
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
} 