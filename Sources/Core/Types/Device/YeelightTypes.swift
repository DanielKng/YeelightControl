import Foundation
import Network

public struct YeelightDevice: Codable, Identifiable, Equatable {
    public let id: String
    public var name: String
    public let model: YeelightModel
    public let firmwareVersion: String
    public let ipAddress: String
    public let port: Int
    public var state: DeviceState
    public var isOnline: Bool
    public var lastSeen: Date
    public var isConnected: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        model: YeelightModel,
        firmwareVersion: String,
        ipAddress: String,
        port: Int = 55443,
        state: DeviceState = .init(),
        isOnline: Bool = false,
        lastSeen: Date = Date(),
        isConnected: Bool = false
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
        self.isConnected = isConnected
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
        case isConnected
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
        isConnected = try container.decodeIfPresent(Bool.self, forKey: .isConnected) ?? isOnline
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
        try container.encode(isConnected, forKey: .isConnected)
    }
    
    public static func == (lhs: YeelightDevice, rhs: YeelightDevice) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.model == rhs.model &&
               lhs.firmwareVersion == rhs.firmwareVersion &&
               lhs.ipAddress == rhs.ipAddress &&
               lhs.port == rhs.port &&
               lhs.state == rhs.state &&
               lhs.isOnline == rhs.isOnline &&
               lhs.lastSeen == rhs.lastSeen &&
               lhs.isConnected == rhs.isConnected
    }
}

public struct YeelightDeviceUpdate: Codable, Equatable {
    public let deviceId: String
    public let state: DeviceState
    public let timestamp: Date
    
    public init(deviceId: String, state: DeviceState, timestamp: Date = Date()) {
        self.deviceId = deviceId
        self.state = state
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case deviceId
        case state
        case timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        state = try container.decode(DeviceState.self, forKey: .state)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(state, forKey: .state)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    public static func == (lhs: YeelightDeviceUpdate, rhs: YeelightDeviceUpdate) -> Bool {
        return lhs.deviceId == rhs.deviceId &&
               lhs.state == rhs.state &&
               lhs.timestamp == rhs.timestamp
    }
}

public enum ConnectionState: String, Codable, Equatable {
    case connected
    case disconnected
    case error
    case unknown
    
    public var displayName: String {
        switch self {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Error"
        case .unknown:
            return "Unknown"
        }
    }
}

public struct YeelightCommand: Codable, Equatable {
    public let id: Int
    public let method: String
    public let params: [Any]
    
    public init(id: Int, method: String, params: [Any]) {
        self.id = id
        self.method = method
        self.params = params
    }
    
    public static func == (lhs: YeelightCommand, rhs: YeelightCommand) -> Bool {
        return lhs.id == rhs.id && lhs.method == rhs.method
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case method
        case params
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        method = try container.decode(String.self, forKey: .method)
        params = try container.decode([AnyCodable].self, forKey: .params).map { $0.value }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(method, forKey: .method)
        try container.encode(params.map { AnyCodable($0) }, forKey: .params)
    }
}

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

public enum YeelightError: Error {
    case deviceNotFound
    case connectionFailed
    case invalidResponse
    case commandFailed(String)
    case invalidState
    case networkError(Error)
    
    public var localizedDescription: String {
        switch self {
        case .deviceNotFound:
            return "Device not found"
        case .connectionFailed:
            return "Failed to connect to device"
        case .invalidResponse:
            return "Invalid response from device"
        case .commandFailed(let message):
            return "Command failed: \(message)"
        case .invalidState:
            return "Device is in an invalid state"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - YeelightCommand Helpers

extension YeelightCommand {
    public static func setPower(on: Bool, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        return YeelightCommand(
            id: Int.random(in: 1...1000),
            method: "set_power",
            params: [on ? "on" : "off", effect, duration]
        )
    }
    
    public static func setBrightness(_ brightness: Int, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        return YeelightCommand(
            id: Int.random(in: 1...1000),
            method: "set_bright",
            params: [brightness, effect, duration]
        )
    }
    
    public static func setColorTemperature(_ temperature: Int, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        return YeelightCommand(
            id: Int.random(in: 1...1000),
            method: "set_ct_abx",
            params: [temperature, effect, duration]
        )
    }
    
    public static func setRGB(red: Int, green: Int, blue: Int, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        let rgb = (red << 16) + (green << 8) + blue
        return YeelightCommand(
            id: Int.random(in: 1...1000),
            method: "set_rgb",
            params: [rgb, effect, duration]
        )
    }
    
    public static func setHSV(hue: Int, saturation: Int, effect: String = "smooth", duration: Int = 500) -> YeelightCommand {
        return YeelightCommand(
            id: Int.random(in: 1...1000),
            method: "set_hsv",
            params: [hue, saturation, effect, duration]
        )
    }
    
    public static func toggle() -> YeelightCommand {
        return YeelightCommand(
            id: Int.random(in: 1...1000),
            method: "toggle",
            params: []
        )
    }
    
    public static func startColorFlow(count: Int, action: Int, flowExpression: String) -> YeelightCommand {
        return YeelightCommand(
            id: Int.random(in: 1...1000),
            method: "start_cf",
            params: [count, action, flowExpression]
        )
    }
    
    public static func stopColorFlow() -> YeelightCommand {
        return YeelightCommand(
            id: Int.random(in: 1...1000),
            method: "stop_cf",
            params: []
        )
    }
}

// MARK: - YeelightColor

public typealias YeelightColor = DeviceColor

// MARK: - YeelightMode

public enum YeelightMode: String, Codable, Equatable {
    case normal
    case colorFlow
    case colorTemperature
    case hsv
    case rgb
    
    public var displayName: String {
        switch self {
        case .normal:
            return "Normal"
        case .colorFlow:
            return "Color Flow"
        case .colorTemperature:
            return "Color Temperature"
        case .hsv:
            return "HSV"
        case .rgb:
            return "RGB"
        }
    }
} 