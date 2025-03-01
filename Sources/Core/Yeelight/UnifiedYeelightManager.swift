import Foundation
import Combine
import Network
import SwiftUI

// MARK: - Color Type
public struct Core_Color: Codable, Equatable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double
    
    public init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
    
    public static let clear = Core_Color(red: 0, green: 0, blue: 0, opacity: 0)
    public static let black = Core_Color(red: 0, green: 0, blue: 0)
    public static let white = Core_Color(red: 1, green: 1, blue: 1)
    public static let red = Core_Color(red: 1, green: 0, blue: 0)
    public static let green = Core_Color(red: 0, green: 1, blue: 0)
    public static let blue = Core_Color(red: 0, green: 0, blue: 1)
    public static let yellow = Core_Color(red: 1, green: 1, blue: 0)
    public static let orange = Core_Color(red: 1, green: 0.5, blue: 0)
    public static let purple = Core_Color(red: 0.5, green: 0, blue: 0.5)
    public static let pink = Core_Color(red: 1, green: 0.75, blue: 0.8)
}

// MARK: - Yeelight Managing Protocol
// This protocol is already defined in YeelightProtocols.swift
// public protocol Core_YeelightManaging: AnyObject {
//     var isEnabled: Bool { get }
//     var devices: [Core_Device] { get }
//     var deviceUpdates: AnyPublisher<[Core_Device], Never> { get }
//     
//     func startDiscovery() async
//     func stopDiscovery() async
//     func connectToDevice(_ device: Core_Device) async throws
//     func disconnectFromDevice(_ device: Core_Device) async
//     func getAllDevices() async -> [Core_Device]
//     func getDevice(withId id: String) async -> Core_Device?
//     func updateDevice(_ device: Core_Device) async throws
//     func deleteDevice(_ device: Core_Device) async throws
//     func setDevicePower(_ device: Core_Device, isOn: Bool) async throws
//     func setDeviceBrightness(_ device: Core_Device, brightness: Int) async throws
//     func setDeviceColor(_ device: Core_Device, color: Core_Color) async throws
//     func setDeviceColorTemperature(_ device: Core_Device, temperature: Int) async throws
// }

// MARK: - Unified Yeelight Manager Implementation
public final class UnifiedYeelightManager: ObservableObject, Core_YeelightManaging {
    // MARK: - Properties
    @Published public private(set) var isEnabled: Bool = true
    @Published public private(set) var devices: [Core_Device] = []
    
    private let deviceSubject = PassthroughSubject<[Core_Device], Never>()
    private let storageManager: any Core_StorageManaging
    private let networkManager: any Core_NetworkManaging
    
    // MARK: - Initialization
    public init(storageManager: any Core_StorageManaging, networkManager: any Core_NetworkManaging) {
        self.storageManager = storageManager
        self.networkManager = networkManager
        
        Task {
            await loadDevices()
        }
    }
    
    // MARK: - Public API
    public var deviceUpdates: AnyPublisher<[Core_Device], Never> {
        deviceSubject.eraseToAnyPublisher()
    }
    
    public func startDiscovery() async {
        // Implementation for starting device discovery
        print("Starting Yeelight device discovery")
        
        // Simulate finding devices
        await simulateDeviceDiscovery()
    }
    
    public func stopDiscovery() async {
        // Implementation for stopping device discovery
        print("Stopping Yeelight device discovery")
    }
    
    public func connectToDevice(_ device: Core_Device) async throws {
        print("Connecting to device: \(device.name)")
        
        // Simulate connection logic
        var updatedDevice = device
        updatedDevice.isConnected = true
        
        // Update device in the list
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = updatedDevice
            deviceSubject.send(devices)
            
            // Save updated device list
            await saveDevices()
        } else {
            throw Core_YeelightError.deviceNotFound
        }
    }
    
    public func disconnectFromDevice(_ device: Core_Device) async {
        print("Disconnecting from device: \(device.name)")
        
        // Simulate disconnection logic
        var updatedDevice = device
        updatedDevice.isConnected = false
        
        // Update device in the list
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = updatedDevice
            deviceSubject.send(devices)
            
            // Save updated device list
            await saveDevices()
        }
    }
    
    public func getAllDevices() async -> [Core_Device] {
        return devices
    }
    
    public func getDevice(withId id: String) async -> Core_Device? {
        return devices.first(where: { $0.id == id })
    }
    
    public func updateDevice(_ device: Core_Device) async throws {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index] = device
            deviceSubject.send(devices)
            
            // Save updated device list
            await saveDevices()
        } else {
            throw Core_YeelightError.deviceNotFound
        }
    }
    
    public func deleteDevice(_ device: Core_Device) async throws {
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices.remove(at: index)
            deviceSubject.send(devices)
            
            // Save updated device list
            await saveDevices()
        } else {
            throw Core_YeelightError.deviceNotFound
        }
    }
    
    public func setDevicePower(_ device: Core_Device, isOn: Bool) async throws {
        print("Setting power for device \(device.name) to \(isOn)")
        
        // Simulate power command
        var updatedDevice = device
        updatedDevice.isPoweredOn = isOn
        
        // Update device in the list
        try await updateDevice(updatedDevice)
        
        // In a real implementation, you would send a command to the physical device
        // await sendCommand(to: device, command: "set_power", params: [isOn ? "on" : "off"])
    }
    
    public func setDeviceBrightness(_ device: Core_Device, brightness: Int) async throws {
        print("Setting brightness for device \(device.name) to \(brightness)")
        
        // Validate brightness value
        guard brightness >= 1 && brightness <= 100 else {
            throw Core_YeelightError.invalidParameter("Brightness must be between 1 and 100")
        }
        
        // Simulate brightness command
        var updatedDevice = device
        updatedDevice.brightness = brightness
        
        // Update device in the list
        try await updateDevice(updatedDevice)
        
        // In a real implementation, you would send a command to the physical device
        // await sendCommand(to: device, command: "set_bright", params: [brightness])
    }
    
    public func setDeviceColor(_ device: Core_Device, color: Core_Color) async throws {
        print("Setting color for device \(device.name) to RGB(\(color.red), \(color.green), \(color.blue))")
        
        // Simulate color command
        var updatedDevice = device
        updatedDevice.color = color
        
        // Update device in the list
        try await updateDevice(updatedDevice)
        
        // In a real implementation, you would send a command to the physical device
        // let rgb = color.red * 65536 + color.green * 256 + color.blue
        // await sendCommand(to: device, command: "set_rgb", params: [rgb])
    }
    
    public func setDeviceColorTemperature(_ device: Core_Device, temperature: Int) async throws {
        print("Setting color temperature for device \(device.name) to \(temperature)K")
        
        // Validate temperature value (1700K-6500K is typical range for Yeelight)
        guard temperature >= 1700 && temperature <= 6500 else {
            throw Core_YeelightError.invalidParameter("Color temperature must be between 1700K and 6500K")
        }
        
        // Simulate color temperature command
        var updatedDevice = device
        updatedDevice.colorTemperature = temperature
        
        // Update device in the list
        try await updateDevice(updatedDevice)
        
        // In a real implementation, you would send a command to the physical device
        // await sendCommand(to: device, command: "set_ct_abx", params: [temperature])
    }
    
    // MARK: - Private Methods
    private func loadDevices() async {
        do {
            let storedDevices: [Core_Device] = try await storageManager.load(forKey: "yeelight_devices")
            devices = storedDevices
            deviceSubject.send(devices)
        } catch {
            print("Error loading devices: \(error)")
            // Start with empty device list
            devices = []
            deviceSubject.send(devices)
        }
    }
    
    private func saveDevices() async {
        do {
            try await storageManager.save(devices, forKey: "yeelight_devices")
        } catch {
            print("Error saving devices: \(error)")
        }
    }
    
    private func simulateDeviceDiscovery() async {
        // Simulate finding new devices
        let newDevice = Core_Device(
            id: UUID().uuidString,
            name: "Yeelight Bulb \(Int.random(in: 100...999))",
            ipAddress: "192.168.1.\(Int.random(in: 2...254))",
            port: 55443,
            type: .bulb,
            model: "YLDP13YL",
            firmwareVersion: "1.0.0",
            isPoweredOn: Bool.random(),
            brightness: Int.random(in: 1...100),
            color: Core_Color(red: Int.random(in: 0...255), green: Int.random(in: 0...255), blue: Int.random(in: 0...255)),
            colorTemperature: Int.random(in: 1700...6500),
            isConnected: false
        )
        
        // Add the new device if it doesn't already exist
        if !devices.contains(where: { $0.id == newDevice.id }) {
            devices.append(newDevice)
            deviceSubject.send(devices)
            
            // Save updated device list
            await saveDevices()
        }
    }
}

// MARK: - Yeelight Error
public enum Core_YeelightError: Error {
    case deviceNotFound
    case connectionFailed
    case commandFailed
    case invalidParameter(String)
    case notConnected
    case timeout
    case unsupportedOperation
}

// MARK: - Device Model
public struct Core_Device: Identifiable, Codable, Equatable {
    public var id: String
    public var name: String
    public var ipAddress: String
    public var port: Int
    public var type: Core_DeviceType
    public var model: String
    public var firmwareVersion: String
    public var isPoweredOn: Bool
    public var brightness: Int
    public var color: Core_Color
    public var colorTemperature: Int
    public var isConnected: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        ipAddress: String,
        port: Int,
        type: Core_DeviceType,
        model: String,
        firmwareVersion: String,
        isPoweredOn: Bool = false,
        brightness: Int = 100,
        color: Core_Color = Core_Color(red: 255, green: 255, blue: 255),
        colorTemperature: Int = 4000,
        isConnected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.port = port
        self.type = type
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.isPoweredOn = isPoweredOn
        self.brightness = brightness
        self.color = color
        self.colorTemperature = colorTemperature
        self.isConnected = isConnected
    }
    
    // Explicit implementation of Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        ipAddress = try container.decode(String.self, forKey: .ipAddress)
        port = try container.decode(Int.self, forKey: .port)
        type = try container.decode(Core_DeviceType.self, forKey: .type)
        model = try container.decode(String.self, forKey: .model)
        firmwareVersion = try container.decode(String.self, forKey: .firmwareVersion)
        isPoweredOn = try container.decode(Bool.self, forKey: .isPoweredOn)
        brightness = try container.decode(Int.self, forKey: .brightness)
        color = try container.decode(Core_Color.self, forKey: .color)
        colorTemperature = try container.decode(Int.self, forKey: .colorTemperature)
        isConnected = try container.decode(Bool.self, forKey: .isConnected)
    }
    
    // Explicit implementation of Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(ipAddress, forKey: .ipAddress)
        try container.encode(port, forKey: .port)
        try container.encode(type, forKey: .type)
        try container.encode(model, forKey: .model)
        try container.encode(firmwareVersion, forKey: .firmwareVersion)
        try container.encode(isPoweredOn, forKey: .isPoweredOn)
        try container.encode(brightness, forKey: .brightness)
        try container.encode(color, forKey: .color)
        try container.encode(colorTemperature, forKey: .colorTemperature)
        try container.encode(isConnected, forKey: .isConnected)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, ipAddress, port, type, model, firmwareVersion
        case isPoweredOn, brightness, color, colorTemperature, isConnected
    }
}

// MARK: - Device Type
public enum Core_DeviceType: String, Codable, Hashable {
    case bulb
    case strip
    case ceiling
    case desk
    case ambient
    case unknown
}
