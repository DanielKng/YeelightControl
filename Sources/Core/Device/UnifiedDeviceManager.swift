import Foundation
import Combine
import SwiftUI

// Use relative imports within the same module
// No need to specify the module name for types in the same module

// Add explicit imports for the types

// MARK: - Device Manager Implementation

public actor UnifiedDeviceManager: Core_DeviceManaging, ObservableObject {
    // MARK: - Properties
    
    @MainActor @Published private(set) var devices: [Device] = []
    @MainActor @Published private(set) var isDiscovering: Bool = false
    
    private let storageManager: any StorageManaging
    private let deviceSubject = PassthroughSubject<Device, Never>()
    private var discoveryTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    public init(storageManager: any StorageManaging) {
        self.storageManager = storageManager
        self.isEnabled = true
        
        Task {
            await loadDevices()
        }
    }
    
    // MARK: - BaseService
    
    public var isEnabled: Bool
    
    // MARK: - DeviceManaging
    
    public nonisolated var deviceUpdates: AnyPublisher<Device, Never> {
        deviceSubject.eraseToAnyPublisher()
    }
    
    public func getDevice(byId id: String) async -> Device? {
        return await MainActor.run {
            devices.first { $0.id == id }
        }
    }
    
    public func getAllDevices() async -> [Device] {
        return await MainActor.run {
            devices
        }
    }
    
    public func startDiscovery() async {
        guard discoveryTask == nil else { return }
        
        await MainActor.run {
            isDiscovering = true
        }
        
        discoveryTask = Task {
            // Simulate discovery process
            do {
                // In a real implementation, this would use network discovery
                // For now, we'll simulate finding devices after a delay
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                // Create sample devices if none exist
                if await MainActor.run({ devices.isEmpty }) {
                    let sampleDevices = createSampleDevices()
                    for device in sampleDevices {
                        await addDevice(device)
                    }
                }
                
                await MainActor.run {
                    isDiscovering = false
                }
                discoveryTask = nil
            } catch {
                await MainActor.run {
                    isDiscovering = false
                }
                discoveryTask = nil
            }
        }
    }
    
    public func stopDiscovery() async {
        discoveryTask?.cancel()
        discoveryTask = nil
        
        await MainActor.run {
            isDiscovering = false
        }
    }
    
    public func addDevice(_ device: Device) async {
        // Check if device already exists
        if let existingDevice = await getDevice(byId: device.id) {
            // Update existing device
            await updateDevice(device)
            return
        }
        
        // Add new device
        await MainActor.run {
            devices.append(device)
        }
        
        try? await storageManager.save(device, withId: device.id, inCollection: "devices")
        deviceSubject.send(device)
    }
    
    public func updateDevice(_ device: Device) async {
        await MainActor.run {
            if let index = devices.firstIndex(where: { $0.id == device.id }) {
                devices[index] = device
            }
        }
        
        try? await storageManager.save(device, withId: device.id, inCollection: "devices")
        deviceSubject.send(device)
    }
    
    public func removeDevice(_ device: Device) async {
        await MainActor.run {
            devices.removeAll { $0.id == device.id }
        }
        
        try? await storageManager.delete(withId: device.id, fromCollection: "devices")
        deviceSubject.send(device)
    }
    
    public func updateDeviceState(_ device: Device, newState: DeviceState) async throws {
        var updatedDevice = device
        updatedDevice.state = newState
        
        // In a real implementation, this would send commands to the physical device
        // For now, we'll just update our local state
        
        await updateDevice(updatedDevice)
    }
    
    // MARK: - Private Methods
    
    private func loadDevices() async {
        do {
            let loadedDevices: [Device] = try await storageManager.getAll(fromCollection: "devices")
            await MainActor.run {
                devices = loadedDevices
            }
        } catch {
            print("Failed to load devices: \(error.localizedDescription)")
            
            // Create sample devices if none were loaded
            if await MainActor.run({ devices.isEmpty }) {
                let sampleDevices = createSampleDevices()
                for device in sampleDevices {
                    await addDevice(device)
                }
            }
        }
    }
    
    private func createSampleDevices() -> [Device] {
        return [
            Device(
                id: UUID().uuidString,
                name: "Living Room Light",
                type: .bulb,
                ipAddress: "192.168.1.100",
                port: 55443,
                firmwareVersion: "1.0.0",
                model: "YLDP13YL",
                state: DeviceState(
                    power: true,
                    brightness: 80,
                    color: Color.orange,
                    colorTemperature: 3500
                )
            ),
            Device(
                id: UUID().uuidString,
                name: "Bedroom Light",
                type: .bulb,
                ipAddress: "192.168.1.101",
                port: 55443,
                firmwareVersion: "1.0.0",
                model: "YLDP13YL",
                state: DeviceState(
                    power: false,
                    brightness: 50,
                    color: Color.blue,
                    colorTemperature: 4000
                )
            ),
            Device(
                id: UUID().uuidString,
                name: "Kitchen Strip",
                type: .strip,
                ipAddress: "192.168.1.102",
                port: 55443,
                firmwareVersion: "1.0.0",
                model: "YLDD01YL",
                state: DeviceState(
                    power: true,
                    brightness: 100,
                    color: Color.green,
                    colorTemperature: 6500
                )
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
