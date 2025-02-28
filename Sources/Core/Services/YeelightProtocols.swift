import Foundation
import Combine
import CoreLocation
import SwiftUI
import Network
import UniformTypeIdentifiers
import WidgetKit

// MARK: - Public Types
public protocol YeelightDevice {
    var id: String { get }
    var name: String { get }
    var ipAddress: String { get }
    var port: Int { get }
    var isOnline: Bool { get }
    var state: DeviceState { get }
}

public struct DeviceState: Codable {
    public let isOn: Bool
    public let brightness: Int
    public let colorTemperature: Int
    public let color: Color?
    
    public init(isOn: Bool, brightness: Int, colorTemperature: Int, color: Color? = nil) {
        self.isOn = isOn
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.color = color
    }
}

public enum NetworkError: LocalizedError {
    case deviceNotFound
    case connectionFailed
    case invalidResponse
    case timeout
    case networkUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Device not found"
        case .connectionFailed:
            return "Failed to connect to device"
        case .invalidResponse:
            return "Invalid response from device"
        case .timeout:
            return "Connection timed out"
        case .networkUnavailable:
            return "Network is unavailable"
        }
    }
}

public enum SceneError: LocalizedError {
    case invalidScene
    case sceneNotFound
    case activationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidScene:
            return "Invalid scene configuration"
        case .sceneNotFound:
            return "Scene not found"
        case .activationFailed:
            return "Failed to activate scene"
        }
    }
}

public enum EffectError: LocalizedError {
    case invalidEffect
    case effectNotFound
    case activationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidEffect:
            return "Invalid effect configuration"
        case .effectNotFound:
            return "Effect not found"
        case .activationFailed:
            return "Failed to activate effect"
        }
    }
}

public enum LogCategory: String, Codable {
    case system
    case network
    case device
    case scene
    case effect
    case automation
    case security
    case analytics
    case background
    case error
}

public struct LogEntry: Codable {
    public let timestamp: Date
    public let category: LogCategory
    public let level: LogLevel
    public let message: String
    
    public init(timestamp: Date = Date(), category: LogCategory, level: LogLevel, message: String) {
        self.timestamp = timestamp
        self.category = category
        self.level = level
        self.message = message
    }
}

public enum LogLevel: String, Codable {
    case debug
    case info
    case warning
    case error
    case critical
}

// MARK: - Core Types
public struct YeelightDevice: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var ipAddress: String
    public var port: Int
    public var model: String
    public var firmwareVersion: String
    public var state: DeviceState
    public var supportedFeatures: Set<String>
    public var lastSeen: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        ipAddress: String,
        port: Int = 55443,
        model: String = "unknown",
        firmwareVersion: String = "unknown",
        state: DeviceState = DeviceState(),
        supportedFeatures: Set<String> = [],
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.port = port
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.state = state
        self.supportedFeatures = supportedFeatures
        self.lastSeen = lastSeen
    }
}

public struct Scene: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var icon: String
    public var deviceStates: [String: DeviceState]
    public var isPreset: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        icon: String = "lightbulb",
        deviceStates: [String: DeviceState] = [:],
        isPreset: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.deviceStates = deviceStates
        self.isPreset = isPreset
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Effect: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var type: EffectType
    public var parameters: EffectParameters
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: EffectType,
        parameters: EffectParameters,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.parameters = parameters
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum EffectType: String, Codable {
    case colorFlow
    case pulse
    case strobe
    case custom
}

public struct EffectParameters: Codable, Equatable, Hashable {
    public var duration: TimeInterval
    public var brightness: Int
    public var colorTemperature: Int
    public var rgb: Int
    
    public init(
        duration: TimeInterval = 1.0,
        brightness: Int = 100,
        colorTemperature: Int = 4000,
        rgb: Int = 0xFFFFFF
    ) {
        self.duration = duration
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.rgb = rgb
    }
}

// MARK: - Device Management
public protocol DeviceManaging: AnyObject {
    var devices: [Device] { get }
    var deviceUpdates: AnyPublisher<DeviceStateUpdate, Never> { get }
    
    func addDevice(_ device: Device)
    func removeDevice(_ device: Device)
    func updateDevice(_ device: Device)
    func getDevice(byId id: UUID) -> Device?
}

// MARK: - Scene Management
public protocol SceneManaging: AnyObject {
    var scenes: [Scene] { get }
    var sceneUpdates: AnyPublisher<SceneUpdate, Never> { get }
    
    func getScene(byId id: String) -> Scene?
    func getAllScenes() -> [Scene]
    func createScene(_ scene: Scene) async throws
    func updateScene(_ scene: Scene) async throws
    func deleteScene(_ scene: Scene) async throws
    func applyScene(_ scene: Scene, to devices: [String]) async throws
}

// MARK: - Effect Management
public protocol EffectManaging: AnyObject {
    var effects: [Effect] { get }
    var effectUpdates: AnyPublisher<EffectUpdate, Never> { get }
    
    func getEffect(byId id: String) -> Effect?
    func getAllEffects() -> [Effect]
    func createEffect(_ effect: Effect) async throws
    func updateEffect(_ effect: Effect) async throws
    func deleteEffect(_ effect: Effect) async throws
    func applyEffect(_ effect: Effect, to devices: [String]) async throws
}

// MARK: - Network Management
public protocol NetworkMessageHandler: AnyObject {
    func handleMessage(_ message: Data, from device: Device)
    func handleError(_ error: Error, for device: Device)
}

public protocol NetworkManaging: AnyObject {
    var isDiscoveryActive: Bool { get }
    var messageHandler: NetworkMessageHandler? { get set }
    
    func startDiscovery()
    func stopDiscovery()
    func connect(to device: Device)
    func disconnect(from device: Device)
    func send(_ command: String, to device: Device)
}

// MARK: - Storage Management
public protocol StorageManaging: AnyObject {
    func save<T: Encodable>(_ object: T, forKey key: String) throws
    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T
    func remove(forKey key: String)
    func clearAll()
}

// MARK: - Configuration Management
public protocol ConfigurationManaging: AnyObject {
    var configuration: [String: Any] { get }
    
    func getValue<T>(forKey key: String) -> T?
    func setValue<T>(_ value: T, forKey key: String)
    func removeValue(forKey key: String)
    func clearConfiguration()
}

// MARK: - Update Types
public enum SceneUpdate {
    case created(Scene)
    case updated(Scene)
    case deleted(String)
    case applied(Scene, [String])
}

public enum EffectUpdate {
    case created(Effect)
    case updated(Effect)
    case deleted(String)
    case applied(Effect, [String])
}

public struct DeviceStateUpdate {
    public let deviceId: String
    public let state: DeviceState
    
    public init(deviceId: String, state: DeviceState) {
        self.deviceId = deviceId
        self.state = state
    }
}

// MARK: - Theme Management
public protocol ThemeManaging: AnyObject {
    var currentTheme: Theme { get set }
    var isDarkMode: Bool { get set }
    
    func applyTheme(_ theme: Theme)
}

public enum Theme: String {
    case system
    case light
    case dark
    case custom
}

// MARK: - Connection Management
public protocol ConnectionManaging: AnyObject {
    var isNetworkReachable: Bool { get }
    var connectionStatus: ConnectionStatus { get }
    
    func startMonitoring()
    func stopMonitoring()
}

public enum ConnectionStatus {
    case connected
    case disconnected
    case connecting
    case error(Error)
}

// MARK: - Logger
public protocol Logging {
    func log(_ message: String, category: LogCategory, level: LogLevel)
    func getEntries(for category: LogCategory?) -> [LogEntry]
    func clearLogs()
} 