import Foundation
import Combine
import SwiftUI

@preconcurrency protocol DeviceManaging: Actor {
    nonisolated var devices: [YeelightDevice] { get }
    nonisolated var deviceUpdates: PassthroughSubject<DeviceStateUpdate, Never> { get }
    nonisolated func getDevice(byId id: String) -> YeelightDevice?
    func addDevice(_ device: YeelightDevice) async
    func removeDevice(_ device: YeelightDevice) async
    func updateDevice(_ device: YeelightDevice) async
    func discoverDevices() async
}

@MainActor
public class UnifiedDeviceManager: ObservableObject, DeviceManaging {
    // MARK: - Published Properties
    @Published public private(set) var devices: [YeelightDevice] = []
    @Published private(set) var discoveredDevices: [YeelightDevice] = []
    
    // MARK: - Publishers
    public let deviceUpdates = PassthroughSubject<DeviceStateUpdate, Never>()
    
    // MARK: - Dependencies
    weak var stateManager: UnifiedStateManager?
    weak var networkManager: UnifiedNetworkManager?
    weak var storageManager: UnifiedStorageManager?
    
    // MARK: - Private Properties
    private var discoveryTask: Task<Void, Never>?
    private var deviceConnections: [String: DeviceConnection] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private struct Configuration {
        var autoReconnectEnabled = true
        var reconnectInterval: TimeInterval = 5
        var maxReconnectAttempts = 3
        var connectionTimeout: TimeInterval = 10
        var keepAliveInterval: TimeInterval = 60
    }
    
    private let config = Configuration()
    
    // MARK: - Singleton
    public static let shared = UnifiedDeviceManager()
    
    private init() {
        setupObservers()
        loadStoredDevices()
    }
    
    // MARK: - Public Methods
    public nonisolated func getDevice(byId id: String) -> YeelightDevice? {
        devices.first { $0.id == id }
    }
    
    public func addDevice(_ device: YeelightDevice) async {
        guard !devices.contains(where: { $0.id == device.id }) else { return }
        devices.append(device)
        await saveDevices()
        await setupDeviceConnection(for: device)
    }
    
    public func removeDevice(_ device: YeelightDevice) async {
        devices.removeAll { $0.id == device.id }
        deviceConnections[device.id]?.disconnect()
        deviceConnections.removeValue(forKey: device.id)
        await saveDevices()
    }
    
    public func updateDevice(_ device: YeelightDevice) async {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }
        devices[index] = device
        await saveDevices()
        deviceUpdates.send(DeviceStateUpdate(deviceId: device.id, state: device.state))
    }
    
    // MARK: - Discovery Methods
    public func discoverDevices() async {
        discoveryTask?.cancel()
        discoveryTask = Task {
            do {
                await networkManager?.startDiscovery()
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                await networkManager?.stopDiscovery()
            } catch {
                print("Device discovery failed: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        networkManager?.isDiscoveryActive
            .sink { [weak self] isActive in
                if !isActive {
                    Task { @MainActor [weak self] in
                        await self?.handleDiscoveryCompleted()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleDiscoveryCompleted() async {
        // Process any newly discovered devices
        let newDevices = discoveredDevices.filter { device in
            !devices.contains { $0.id == device.id }
        }
        
        for device in newDevices {
            await addDevice(device)
        }
    }
    
    private func loadStoredDevices() {
        Task {
            do {
                if let loadedDevices: [YeelightDevice] = try await storageManager?.load([YeelightDevice].self, forKey: "devices") {
                    self.devices = loadedDevices
                    for device in loadedDevices where device.state.isOnline {
                        await setupDeviceConnection(for: device)
                    }
                }
            } catch {
                print("Failed to load devices: \(error)")
            }
        }
    }
    
    private func saveDevices() async {
        do {
            try await storageManager?.save(devices, forKey: "devices")
        } catch {
            print("Failed to save devices: \(error)")
        }
    }
    
    private func setupDeviceConnection(for device: YeelightDevice) async {
        let connection = DeviceConnection(device: device)
        deviceConnections[device.id] = connection
        
        connection.stateUpdates
            .sink { [weak self] state in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if var updatedDevice = self.getDevice(byId: device.id) {
                        updatedDevice.state = state
                        updatedDevice.state.isOnline = true
                        updatedDevice.lastSeen = Date()
                        await self.updateDevice(updatedDevice)
                    }
                }
            }
            .store(in: &cancellables)
        
        await connection.connect()
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