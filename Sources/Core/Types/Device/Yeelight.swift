import SwiftUI
import Foundation

public struct Yeelight: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let model: YeelightModel
    public let firmwareVersion: String
    public let ipAddress: String
    public let port: Int
    public var state: DeviceState
    public var isOnline: Bool
    public var lastSeen: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        model: YeelightModel,
        firmwareVersion: String,
        ipAddress: String,
        port: Int,
        state: DeviceState = .init(),
        isOnline: Bool = false,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.ipAddress = ipAddress
        self.port = port
        self.state = state
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case model
        case firmwareVersion
        case ipAddress
        case port
        case state
        case isOnline
        case lastSeen
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        model = try container.decode(YeelightModel.self, forKey: .model)
        firmwareVersion = try container.decode(String.self, forKey: .firmwareVersion)
        ipAddress = try container.decode(String.self, forKey: .ipAddress)
        port = try container.decode(Int.self, forKey: .port)
        state = try container.decode(DeviceState.self, forKey: .state)
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        lastSeen = try container.decode(Date.self, forKey: .lastSeen)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(model, forKey: .model)
        try container.encode(firmwareVersion, forKey: .firmwareVersion)
        try container.encode(ipAddress, forKey: .ipAddress)
        try container.encode(port, forKey: .port)
        try container.encode(state, forKey: .state)
        try container.encode(isOnline, forKey: .isOnline)
        try container.encode(lastSeen, forKey: .lastSeen)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(model)
        hasher.combine(firmwareVersion)
        hasher.combine(ipAddress)
        hasher.combine(port)
        hasher.combine(state)
        hasher.combine(isOnline)
        hasher.combine(lastSeen)
    }
    
    public static func == (lhs: Yeelight, rhs: Yeelight) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.model == rhs.model &&
               lhs.firmwareVersion == rhs.firmwareVersion &&
               lhs.ipAddress == rhs.ipAddress &&
               lhs.port == rhs.port &&
               lhs.state == rhs.state &&
               lhs.isOnline == rhs.isOnline &&
               lhs.lastSeen == rhs.lastSeen
    }
}

public enum YeelightModel: String, Codable, Hashable, CaseIterable {
    case colorLEDBulb = "color"
    case monoLEDBulb = "mono"
    case colorLEDStrip = "strip"
    case ceilingLight = "ceiling"
    case deskLamp = "desklamp"
    case bedSideLight = "bedside"
    
    public var displayName: String {
        switch self {
        case .colorLEDBulb:
            return "Color LED Bulb"
        case .monoLEDBulb:
            return "Mono LED Bulb"
        case .colorLEDStrip:
            return "Color LED Strip"
        case .ceilingLight:
            return "Ceiling Light"
        case .deskLamp:
            return "Desk Lamp"
        case .bedSideLight:
            return "Bedside Light"
        }
    }
    
    public var capabilities: YeelightCapabilities {
        switch self {
        case .colorLEDBulb, .colorLEDStrip:
            return YeelightCapabilities(
                supportsBrightness: true,
                supportsColorTemperature: true,
                supportsColor: true,
                supportsEffects: true
            )
        case .monoLEDBulb:
            return YeelightCapabilities(
                supportsBrightness: true,
                supportsColorTemperature: false,
                supportsColor: false,
                supportsEffects: true
            )
        case .ceilingLight:
            return YeelightCapabilities(
                supportsBrightness: true,
                supportsColorTemperature: true,
                supportsColor: false,
                supportsEffects: true
            )
        case .deskLamp, .bedSideLight:
            return YeelightCapabilities(
                supportsBrightness: true,
                supportsColorTemperature: true,
                supportsColor: false,
                supportsEffects: false
            )
        }
    }
}

public struct YeelightCapabilities: Codable, Hashable {
    public let supportsBrightness: Bool
    public let supportsColorTemperature: Bool
    public let supportsColor: Bool
    public let supportsEffects: Bool
    
    public init(
        supportsBrightness: Bool,
        supportsColorTemperature: Bool,
        supportsColor: Bool,
        supportsEffects: Bool
    ) {
        self.supportsBrightness = supportsBrightness
        self.supportsColorTemperature = supportsColorTemperature
        self.supportsColor = supportsColor
        self.supportsEffects = supportsEffects
    }
} 