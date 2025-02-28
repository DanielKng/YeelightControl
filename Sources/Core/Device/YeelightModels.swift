import Foundation
import SwiftUI
import CoreLocation

// MARK: - Device Models
public struct Device: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var ipAddress: String
    public var port: Int
    public var model: String
    public var firmwareVersion: String
    public var power: Bool
    public var brightness: Int
    public var colorTemperature: Int
    public var colorMode: Int
    public var rgb: Int
    
    public init(id: UUID = UUID(), name: String, ipAddress: String, port: Int = 55443,
               model: String = "", firmwareVersion: String = "", power: Bool = false,
               brightness: Int = 100, colorTemperature: Int = 4000, colorMode: Int = 1, rgb: Int = 0xFFFFFF) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.port = port
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.power = power
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.colorMode = colorMode
        self.rgb = rgb
    }
}

// MARK: - Scene Models
public struct YeelightScene: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var devices: [Device]
    public var states: [DeviceState]
    
    public init(id: UUID = UUID(), name: String, devices: [Device] = [], states: [DeviceState] = []) {
        self.id = id
        self.name = name
        self.devices = devices
        self.states = states
    }
}

// MARK: - Effect Models
public struct YeelightEffect: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var type: YeelightEffectType
    public var parameters: YeelightEffectParameters
    
    public init(id: UUID = UUID(), name: String, type: YeelightEffectType, parameters: YeelightEffectParameters) {
        self.id = id
        self.name = name
        self.type = type
        self.parameters = parameters
    }
}

public enum YeelightEffectType: String, Codable {
    case color
    case temperature
    case flow
    case custom
}

public struct YeelightEffectParameters: Codable, Hashable {
    public var duration: TimeInterval
    public var brightness: Int
    public var colorTemperature: Int?
    public var rgb: Int?
    public var flowTransitions: [FlowTransition]?
    
    public init(duration: TimeInterval = 1.0, brightness: Int = 100,
                colorTemperature: Int? = nil, rgb: Int? = nil,
                flowTransitions: [FlowTransition]? = nil) {
        self.duration = duration
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.rgb = rgb
        self.flowTransitions = flowTransitions
    }
}

// MARK: - Flow Models
public struct FlowTransition: Codable, Hashable {
    public var duration: TimeInterval
    public var mode: Int
    public var value: Int
    public var brightness: Int
    
    public init(duration: TimeInterval = 1000, mode: Int = 1,
                value: Int = 0xFFFFFF, brightness: Int = 100) {
        self.duration = duration
        self.mode = mode
        self.value = value
        self.brightness = brightness
    }
}

// MARK: - Device State
public struct DeviceState: Codable, Hashable {
    public var power: Bool
    public var brightness: Int
    public var colorTemperature: Int
    public var rgb: Int
    
    public init(power: Bool = false, brightness: Int = 100,
                colorTemperature: Int = 4000, rgb: Int = 0xFFFFFF) {
        self.power = power
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.rgb = rgb
    }
}

// MARK: - Location
public struct Location: Codable, Hashable {
    public var coordinate: CLLocationCoordinate2D
    public var radius: Double
    public var name: String
    
    public init(coordinate: CLLocationCoordinate2D, radius: Double = 100, name: String) {
        self.coordinate = coordinate
        self.radius = radius
        self.name = name
    }
}

// MARK: - Location Models
extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// MARK: - Network
public enum NetworkError: Error {
    case connectionFailed
    case timeout
    case invalidResponse
    case deviceNotFound
    case invalidCommand
    case custom(String)
}

// MARK: - Device Updates
public struct DeviceStateUpdate {
    public let deviceId: UUID
    public let state: DeviceState
    public let timestamp: Date
    
    public init(deviceId: UUID, state: DeviceState, timestamp: Date = Date()) {
        self.deviceId = deviceId
        self.state = state
        self.timestamp = timestamp
    }
} 