import Foundation
import Combine

// MARK: - Device Types
public struct Core_Device: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let type: Core_DeviceType
    public let manufacturer: String
    public let model: String
    public let firmwareVersion: String?
    public let ipAddress: String?
    public let macAddress: String?
    public var state: Core_DeviceState
    public var isConnected: Bool
    public var lastSeen: Date
    
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

public enum Core_DeviceType: String, Codable, CaseIterable {
    case bulb
    case strip
    case lamp
    case ceiling
    case ambient
    case unknown
}

public enum Core_DeviceState: Codable, Hashable {
    case on(brightness: Int, color: Core_Color)
    case off
    case unknown
    
    public var isOn: Bool {
        switch self {
        case .on:
            return true
        case .off, .unknown:
            return false
        }
    }
    
    public var brightness: Int {
        switch self {
        case .on(let brightness, _):
            return brightness
        case .off, .unknown:
            return 0
        }
    }
    
    public var color: Core_Color {
        switch self {
        case .on(_, let color):
            return color
        case .off, .unknown:
            return .white
        }
    }
}

public enum Core_Color: Codable, Hashable {
    case rgb(red: Int, green: Int, blue: Int)
    case temperature(kelvin: Int)
    case white
    
    public var rgbValues: (red: Int, green: Int, blue: Int) {
        switch self {
        case .rgb(let red, let green, let blue):
            return (red, green, blue)
        case .temperature:
            return (255, 255, 255)
        case .white:
            return (255, 255, 255)
        }
    }
    
    public var temperatureValue: Int {
        switch self {
        case .temperature(let kelvin):
            return kelvin
        case .rgb, .white:
            return 4000
        }
    }
}

// MARK: - Device Protocols
@preconcurrency public protocol Core_DeviceManaging: Core_BaseService {
    /// The list of devices
    nonisolated var devices: [Core_Device] { get }
    
    /// Publisher for device updates
    nonisolated var deviceUpdates: AnyPublisher<[Core_Device], Never> { get }
    
    /// Discover devices
    func discoverDevices() async throws
    
    /// Connect to a device
    func connectToDevice(_ device: Core_Device) async throws
    
    /// Disconnect from a device
    func disconnectFromDevice(_ device: Core_Device) async throws
    
    /// Update a device
    func updateDevice(_ device: Core_Device) async throws
} 