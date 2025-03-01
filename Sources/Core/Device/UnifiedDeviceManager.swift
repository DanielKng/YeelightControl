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
    private let deviceSubject = PassthroughSubject<Device, Never>()
    private var discoveryTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(storageManager: any Core_StorageManaging) {
        self.storageManager = storageManager
        
        Task {
            await loadDevices()
        }
    }
    
    // MARK: - Core_BaseService
    
    nonisolated public var isEnabled: Bool {
        get {
            let task = Task { await _isEnabled }
            return (try? task.value) ?? false
        }
    }
    
    public var serviceIdentifier: String {
        return "core.device"
    }
    
    // MARK: - Core_DeviceManaging
    
    nonisolated public var devices: [Core_Device] {
        get {
            let task = Task { await _devices.map { $0 as Core_Device } }
            return (try? task.result.get()) ?? []
        }
    }
    
    nonisolated public var deviceUpdates: AnyPublisher<Core_Device, Never> {
        deviceSubject.map { $0 as Core_Device }.eraseToAnyPublisher()
    }
    
    public func discoverDevices() async throws {
        await startDiscoveryInternal()
    }
    
    public func connectToDevice(_ device: Core_Device) async throws {
        guard let device = device as? Device else {
            throw NSError(domain: "DeviceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid device type"])
        }
        
        // Implementation for connecting to device
        print("Connecting to device: \(device.id)")
        
        var updatedDevice = device
        updatedDevice.isConnected = true
        
        if let index = _devices.firstIndex(where: { $0.id == device.id }) {
            _devices[index] = updatedDevice
            deviceSubject.send(updatedDevice)
        }
    }
    
    public func disconnectFromDevice(_ device: Core_Device) async throws {
        guard let device = device as? Device else {
            throw NSError(domain: "DeviceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid device type"])
        }
        
        // Implementation for disconnecting from device
        print("Disconnecting from device: \(device.id)")
        
        var updatedDevice = device
        updatedDevice.isConnected = false
        
        if let index = _devices.firstIndex(where: { $0.id == device.id }) {
            _devices[index] = updatedDevice
            deviceSubject.send(updatedDevice)
        }
    }
    
    public func updateDevice(_ device: Core_Device) async throws {
        guard let device = device as? Device else {
            throw NSError(domain: "DeviceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid device type"])
        }
        
        await updateDeviceInternal(device)
    }
    
    public nonisolated func getDevice(byId id: String) async -> Core_Device? {
        let device = await getDeviceInternal(byId: id)
        return device as Core_Device?
    }
    
    private func getDeviceInternal(byId id: String) -> Device? {
        return _devices.first { $0.id == id }
    }
    
    public nonisolated func getAllDevices() async -> [Core_Device] {
        let allDevices = await _devices
        return allDevices.map { $0 as Core_Device }
    }
    
    public nonisolated func startDiscovery() async {
        await startDiscoveryInternal()
    }
    
    private func startDiscoveryInternal() async {
        guard discoveryTask == nil else { return }
        
        _isDiscovering = true
        
        discoveryTask = Task {
            // Simulate discovery process
            do {
                // In a real implementation, this would use network discovery
                // For now, we'll simulate finding devices after a delay
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                // Create sample devices if none exist
                if _devices.isEmpty {
                    let sampleDevices = createSampleDevices()
                    for device in sampleDevices {
                        _devices.append(device)
                        try? await storageManager.save(device, forKey: "device.\(device.id)")
                        deviceSubject.send(device)
                    }
                }
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
        deviceSubject.send(device)
    }
    
    public nonisolated func updateDeviceState(_ device: Device, newState: DeviceState) async throws {
        var updatedDevice = device
        updatedDevice.state = newState
        
        // In a real implementation, this would send commands to the physical device
        // For now, we'll just update our local state
        
        await updateDeviceInternal(updatedDevice)
    }
    
    public nonisolated func updateDevice(_ device: Device) async {
        await updateDeviceInternal(device)
    }
    
    private func updateDeviceInternal(_ device: Device) async {
        if let index = _devices.firstIndex(where: { $0.id == device.id }) {
            _devices[index] = device
        }
        
        try? await storageManager.save(device, forKey: "device.\(device.id)")
        deviceSubject.send(device)
    }
    
    public nonisolated func removeDevice(_ device: Device) async {
        await removeDeviceInternal(device)
    }
    
    private func removeDeviceInternal(_ device: Device) async {
        _devices.removeAll { $0.id == device.id }
        
        try? await storageManager.remove(forKey: "device.\(device.id)")
        deviceSubject.send(device)
    }
    
    // MARK: - Private Methods
    
    private func loadDevices() async {
        do {
            // Load devices from storage
            let deviceDict: [String: Device] = try await storageManager.getAll(withPrefix: "device.")
            let loadedDevices = Array(deviceDict.values)
            
            // In a real implementation, we would load all devices from storage
            // For now, we'll just create sample devices
            if loadedDevices.isEmpty {
                let sampleDevices = createSampleDevices()
                for device in sampleDevices {
                    await addDeviceInternal(device)
                }
            } else {
                _devices = loadedDevices
            }
        } catch {
            print("Failed to load devices: \(error.localizedDescription)")
            
            // Create sample devices if none were loaded
            if _devices.isEmpty {
                let sampleDevices = createSampleDevices()
                for device in sampleDevices {
                    await addDeviceInternal(device)
                }
            }
        }
    }
    
    private func createSampleDevices() -> [Device] {
        return [
            Device(
                id: "device1",
                name: "Living Room Light",
                type: .bulb,
                manufacturer: "Yeelight",
                model: "Color Bulb",
                firmwareVersion: "1.5.2",
                ipAddress: "192.168.1.100",
                macAddress: "AA:BB:CC:DD:EE:FF",
                state: DeviceState(
                    isOn: true,
                    brightness: 80,
                    color: .white,
                    colorTemperature: 4000,
                    isOnline: true
                ),
                isConnected: true
            ),
            Device(
                id: "device2",
                name: "Bedroom Light",
                type: .bulb,
                manufacturer: "Yeelight",
                model: "White Bulb",
                firmwareVersion: "1.4.0",
                ipAddress: "192.168.1.101",
                macAddress: "AA:BB:CC:DD:EE:00",
                state: DeviceState(
                    isOn: false,
                    brightness: 50,
                    color: .white,
                    colorTemperature: 3000,
                    isOnline: true
                ),
                isConnected: false
            ),
            Device(
                id: "device3",
                name: "Kitchen Strip",
                type: .strip,
                manufacturer: "Yeelight",
                model: "Light Strip",
                firmwareVersion: "1.6.1",
                ipAddress: "192.168.1.102",
                macAddress: "AA:BB:CC:DD:EE:11",
                state: DeviceState(
                    isOn: true,
                    brightness: 100,
                    color: .red,
                    colorTemperature: 2700,
                    isOnline: true
                ),
                isConnected: true
            )
        ]
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
    }
    
    func disconnect() {
        reconnectTask?.cancel()
    }
} 
