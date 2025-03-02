import Foundation
import Combine
import SwiftUI

// Use relative imports within the same module
// No need to specify the module name for types in the same module

// Add explicit imports for the types

// MARK: - Device Manager
// Core_DeviceManaging protocol is defined in ServiceProtocols.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Device Manager Implementation

public actor UnifiedDeviceManager: Core_DeviceManaging, Core_BaseService {
    // MARK: - Properties
    
    private var _devices: [Device] = []
    private var _isDiscovering: Bool = false
    private var _isEnabled: Bool = true
    
    private let storageManager: any Core_StorageManaging
    private let deviceSubject = PassthroughSubject<[Device], Never>()
    private var discoveryTask: Task<Void, Never>?
    private var yeelightManager: (any Core_YeelightManaging)?
    private var deviceConnections: [String: DeviceConnection] = [:]
    
    // MARK: - Initialization
    
    public init(storageManager: any Core_StorageManaging) {
        self.storageManager = storageManager
        
        Task {
            await loadDevices()
            await setupYeelightManager()
        }
    }
    
    // MARK: - Core_BaseService
    
    nonisolated public var isEnabled: Bool {
        true
    }
    
    public var serviceIdentifier: String {
        return "core.device"
    }
    
    // MARK: - Core_DeviceManaging
    
    nonisolated public var devices: [Core_Device] {
        // Simplified implementation for nonisolated property
        return []
    }
    
    nonisolated public var deviceUpdates: AnyPublisher<[Core_Device], Never> {
        PassthroughSubject<[Core_Device], Never>().eraseToAnyPublisher()
    }
    
    public func discoverDevices() async throws {
        // Start real device discovery
        _isDiscovering = true
        
        // First, load any stored devices
        let storedDevices: [Device]? = try await storageManager.load(forKey: "devices")
        if let storedDevices = storedDevices {
            _devices = storedDevices
            deviceSubject.send(_devices)
        }
        
        // Then, discover Yeelight devices
        if let yeelightManager = self.yeelightManager {
            do {
                let yeelightDevices = try await yeelightManager.discover()
                
                // Convert YeelightDevices to Devices and add them
                for yeelightDevice in yeelightDevices {
                    // Convert YeelightDevice to Yeelight
                    let yeelight = Yeelight(
                        id: yeelightDevice.id,
                        name: yeelightDevice.name,
                        model: yeelightDevice.model,
                        firmwareVersion: yeelightDevice.firmwareVersion,
                        ipAddress: yeelightDevice.ipAddress,
                        port: yeelightDevice.port,
                        state: yeelightDevice.state,
                        isOnline: yeelightDevice.isOnline,
                        lastSeen: yeelightDevice.lastSeen
                    )
                    let device = Device(yeelight: yeelight)
                    await addDeviceInternal(device)
                }
            } catch {
                print("Error discovering Yeelight devices: \(error.localizedDescription)")
            }
        }
        
        _isDiscovering = false
    }
    
    public func connectToDevice(_ device: Core_Device) async throws {
        guard let index = _devices.firstIndex(where: { $0.id == device.id }) else {
            throw Core_DeviceError.deviceNotFound
        }
        
        var updatedDevice = _devices[index]
        
        // Connect to the physical device based on its type
        switch updatedDevice.type {
        case .yeelight(let yeelight):
            if let yeelightManager = self.yeelightManager {
                // Create a YeelightDevice from the Yeelight struct
                let yeelightDevice = YeelightDevice(
                    id: yeelight.id,
                    name: yeelight.name,
                    model: yeelight.model,
                    firmwareVersion: yeelight.firmwareVersion,
                    ipAddress: yeelight.ipAddress,
                    port: yeelight.port,
                    state: yeelight.state,
                    isOnline: yeelight.isOnline,
                    lastSeen: yeelight.lastSeen
                )
                
                try await yeelightManager.connect(to: yeelightDevice)
                
                // Create a device connection if it doesn't exist
                if deviceConnections[device.id] == nil {
                    let connection = await DeviceConnection(device: yeelightDevice)
                    deviceConnections[device.id] = connection
                    
                    // Start monitoring the device state
                    await connection.connect()
                }
            }
        case .bulb, .strip:
            // For generic devices, we might have different connection logic
            // For now, we'll just update the connection state
            print("Connecting to generic device: \(device.id)")
        }
        
        updatedDevice.isConnected = true
        await updateDeviceInternal(updatedDevice)
    }
    
    public func disconnectFromDevice(_ device: Core_Device) async throws {
        guard let index = _devices.firstIndex(where: { $0.id == device.id }) else {
            throw Core_DeviceError.deviceNotFound
        }
        
        var updatedDevice = _devices[index]
        
        // Disconnect from the physical device based on its type
        switch updatedDevice.type {
        case .yeelight(let yeelight):
            if let yeelightManager = self.yeelightManager {
                // Create a YeelightDevice from the Yeelight struct
                let yeelightDevice = YeelightDevice(
                    id: yeelight.id,
                    name: yeelight.name,
                    model: yeelight.model,
                    firmwareVersion: yeelight.firmwareVersion,
                    ipAddress: yeelight.ipAddress,
                    port: yeelight.port,
                    state: yeelight.state,
                    isOnline: yeelight.isOnline,
                    lastSeen: yeelight.lastSeen
                )
                
                await yeelightManager.disconnect(from: yeelightDevice)
                
                // Remove the device connection
                if let connection = deviceConnections[device.id] {
                    await connection.disconnect()
                    deviceConnections.removeValue(forKey: device.id)
                }
            }
        case .bulb, .strip:
            // For generic devices, we might have different disconnection logic
            // For now, we'll just update the connection state
            print("Disconnecting from generic device: \(device.id)")
        }
        
        updatedDevice.isConnected = false
        await updateDeviceInternal(updatedDevice)
    }
    
    public func updateDevice(_ device: Core_Device) async throws {
        guard let index = _devices.firstIndex(where: { $0.id == device.id }) else {
            throw Core_DeviceError.deviceNotFound
        }
        
        // Create a new Device with updated properties
        let updatedDevice = Device(
            id: device.id,
            name: device.name,
            type: DeviceType.from(coreType: device.type),
            state: device.state != nil ? DeviceState.from(coreState: device.state!) : _devices[index].state,
            isOnline: _devices[index].isOnline,
            lastSeen: device.lastSeen ?? _devices[index].lastSeen,
            isConnected: device.isConnected ?? _devices[index].isConnected,
            manufacturer: device.manufacturer,
            model: device.model,
            firmwareVersion: device.firmwareVersion,
            ipAddress: device.ipAddress,
            macAddress: device.macAddress
        )
        
        await updateDeviceInternal(updatedDevice)
    }
    
    // MARK: - Additional Methods
    
    public nonisolated func getDevice(byId id: String) async -> Core_Device? {
        // Simplified implementation for nonisolated method
        return nil
    }
    
    public nonisolated func getAllDevices() async -> [Core_Device] {
        // Simplified implementation for nonisolated method
        return []
    }
    
    public func updateDeviceState(_ deviceId: String, newState: DeviceState) async throws {
        guard let index = _devices.firstIndex(where: { $0.id == deviceId }) else {
            throw Core_DeviceError.deviceNotFound
        }
        
        var updatedDevice = _devices[index]
        let oldState = updatedDevice.state
        updatedDevice.state = newState
        
        // Send commands to the physical device based on its type
        switch updatedDevice.type {
        case .yeelight(let yeelight):
            if let yeelightManager = self.yeelightManager {
                // Create a YeelightDevice from the Yeelight struct
                let yeelightDevice = YeelightDevice(
                    id: yeelight.id,
                    name: yeelight.name,
                    model: yeelight.model,
                    firmwareVersion: yeelight.firmwareVersion,
                    ipAddress: yeelight.ipAddress,
                    port: yeelight.port,
                    state: oldState, // Use old state as the current device state
                    isOnline: yeelight.isOnline,
                    lastSeen: yeelight.lastSeen
                )
                
                // Send commands to update the device state
                if oldState.power != newState.power {
                    // Power state changed
                    let command = YeelightCommand(
                        id: Int.random(in: 1...1000),
                        method: newState.power ? "set_power" : "set_power",
                        params: [newState.power ? "on" : "off", "smooth", 500]
                    )
                    try await yeelightManager.send(command, to: yeelightDevice)
                }
                
                if oldState.brightness != newState.brightness {
                    // Brightness changed
                    let command = YeelightCommand(
                        id: Int.random(in: 1...1000),
                        method: "set_bright",
                        params: [newState.brightness, "smooth", 500]
                    )
                    try await yeelightManager.send(command, to: yeelightDevice)
                }
                
                if oldState.colorTemperature != newState.colorTemperature {
                    // Color temperature changed
                    let command = YeelightCommand(
                        id: Int.random(in: 1...1000),
                        method: "set_ct_abx",
                        params: [newState.colorTemperature, "smooth", 500]
                    )
                    try await yeelightManager.send(command, to: yeelightDevice)
                }
                
                if oldState.color != newState.color {
                    // Color changed
                    let command = YeelightCommand(
                        id: Int.random(in: 1...1000),
                        method: "set_rgb",
                        params: [
                            (newState.color.red << 16) | (newState.color.green << 8) | newState.color.blue,
                            "smooth",
                            500
                        ]
                    )
                    try await yeelightManager.send(command, to: yeelightDevice)
                }
            }
        case .bulb, .strip:
            // For generic devices, we might have different state update logic
            // For now, we'll just log the state change
            print("Updating state for generic device: \(deviceId)")
        }
        
        await updateDeviceInternal(updatedDevice)
    }
    
    public nonisolated func startDiscovery() async {
        await startDiscoveryInternal()
    }
    
    private func startDiscoveryInternal() async {
        guard discoveryTask == nil else { return }
        
        _isDiscovering = true
        
        discoveryTask = Task {
            do {
                try await discoverDevices()
            } catch {
                print("Discovery error: \(error)")
            }
            
            _isDiscovering = false
            discoveryTask = nil
        }
    }
    
    public nonisolated func stopDiscovery() async {
        await stopDiscoveryInternal()
    }
    
    private func stopDiscoveryInternal() {
        discoveryTask?.cancel()
        discoveryTask = nil
        _isDiscovering = false
    }
    
    public nonisolated func addDevice(_ device: Device) async {
        await addDeviceInternal(device)
    }
    
    private func addDeviceInternal(_ device: Device) async {
        // Check if device already exists
        if let _ = _devices.first(where: { $0.id == device.id }) {
            // Update existing device
            await updateDeviceInternal(device)
            return
        }
        
        // Add new device
        _devices.append(device)
        
        try? await storageManager.save(device, forKey: "device.\(device.id)")
        deviceSubject.send(_devices)
    }
    
    public nonisolated func removeDevice(_ device: Device) async {
        await removeDeviceInternal(device)
    }
    
    private func removeDeviceInternal(_ device: Device) async {
        // Disconnect from the device if it's connected
        if device.isConnected {
            // Create a Core_Device from the Device
            let coreDevice = Core_Device(
                id: device.id,
                name: device.name,
                type: device.type.coreType,
                manufacturer: device.manufacturer,
                model: device.model,
                firmwareVersion: device.firmwareVersion,
                ipAddress: device.ipAddress,
                macAddress: device.macAddress,
                state: device.state.coreState,
                isConnected: device.isConnected,
                lastSeen: device.lastSeen
            )
            try? await disconnectFromDevice(coreDevice)
        }
        
        _devices.removeAll { $0.id == device.id }
        
        try? await storageManager.remove(forKey: "device.\(device.id)")
        deviceSubject.send(_devices)
    }
    
    // MARK: - Private Methods
    
    private func setupYeelightManager() async {
        // Get the network manager from the service container
        self.yeelightManager = ServiceContainer.shared.yeelightManager
    }
    
    private func loadDevices() async {
        do {
            // Load devices from storage
            let deviceDict = try await storageManager.getAll(Device.self, withPrefix: "device.")
            let loadedDevices = deviceDict
            
            if !loadedDevices.isEmpty {
                _devices = loadedDevices
                deviceSubject.send(_devices)
            }
        } catch {
            print("Failed to load devices: \(error.localizedDescription)")
        }
    }
    
    private func updateDeviceInternal(_ device: Device) async {
        if let index = _devices.firstIndex(where: { $0.id == device.id }) {
            _devices[index] = device
        }
        
        try? await storageManager.save(device, forKey: "device.\(device.id)")
        deviceSubject.send(_devices)
    }
}

// MARK: - Device Connection
@MainActor
private class DeviceConnection {
    private let device: YeelightDevice
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts = 0
    
    let stateUpdates = PassthroughSubject<DeviceState, Never>()
    
    init(device: YeelightDevice) {
        self.device = device
    }
    
    func connect() async {
        // Implementation for device connection
        // This would typically involve setting up a connection to the device
        // and monitoring its state
        
        // Start a task to periodically check the device's state
        reconnectTask = Task {
            while !Task.isCancelled {
                do {
                    // Check the device's state
                    // This would typically involve sending a command to the device
                    // and processing the response
                    
                    // For now, we'll just simulate a successful connection
                    reconnectAttempts = 0
                    
                    // Wait for a while before checking again
                    try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                } catch {
                    // If there's an error, increment the reconnect attempts
                    reconnectAttempts += 1
                    
                    // If we've tried too many times, give up
                    if reconnectAttempts > 5 {
                        break
                    }
                    
                    // Wait for a while before trying again
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                }
            }
        }
    }
    
    func disconnect() {
        reconnectTask?.cancel()
    }
} 
