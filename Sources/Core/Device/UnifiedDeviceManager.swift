import Foundation
import Combine
import SwiftUI

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
    private let queue = DispatchQueue(label: "de.knng.app.yeelightcontrol.device", qos: .userInitiated)
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
    public func getDevice(byId id: String) -> YeelightDevice? {
        devices.first { $0.id == id }
    }
    
    public func addDevice(_ device: YeelightDevice) {
        guard !devices.contains(where: { $0.id == device.id }) else { return }
        devices.append(device)
        saveDevices()
        setupDeviceConnection(for: device)
    }
    
    public func removeDevice(_ device: YeelightDevice) {
        devices.removeAll { $0.id == device.id }
        deviceConnections[device.id]?.disconnect()
        deviceConnections.removeValue(forKey: device.id)
        saveDevices()
    }
    
    public func updateDevice(_ device: YeelightDevice) {
        guard let index = devices.firstIndex(where: { $0.id == device.id }) else { return }
        devices[index] = device
        saveDevices()
        deviceUpdates.send(DeviceStateUpdate(deviceId: device.id, state: device.state))
    }
    
    // MARK: - Discovery Methods
    public func discoverDevices() {
        discoveryTask?.cancel()
        discoveryTask = Task {
            do {
                networkManager?.startDiscovery()
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                networkManager?.stopDiscovery()
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
                    self?.handleDiscoveryCompleted()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleDiscoveryCompleted() {
        // Process any newly discovered devices
        Task { @MainActor in
            let newDevices = discoveredDevices.filter { device in
                !devices.contains { $0.id == device.id }
            }
            
            for device in newDevices {
                addDevice(device)
            }
        }
    }
    
    private func loadStoredDevices() {
        do {
            if let loadedDevices: [YeelightDevice] = try storageManager?.load([YeelightDevice].self, forKey: "devices") {
                devices = loadedDevices
                for device in loadedDevices where device.state.isOnline {
                    setupDeviceConnection(for: device)
                }
            }
        } catch {
            print("Failed to load devices: \(error)")
        }
    }
    
    private func saveDevices() {
        do {
            try storageManager?.save(devices, forKey: "devices")
        } catch {
            print("Failed to save devices: \(error)")
        }
    }
    
    private func setupDeviceConnection(for device: YeelightDevice) {
        let connection = DeviceConnection(device: device)
        deviceConnections[device.id] = connection
        
        connection.stateUpdates
            .sink { [weak self] state in
                guard let self = self else { return }
                if var updatedDevice = self.getDevice(byId: device.id) {
                    updatedDevice.state = state
                    updatedDevice.state.isOnline = true
                    updatedDevice.lastSeen = Date()
                    self.updateDevice(updatedDevice)
                }
            }
            .store(in: &cancellables)
        
        connection.connect()
    }
}

// MARK: - Device Connection
private class DeviceConnection {
    private let device: YeelightDevice
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts = 0
    
    let stateUpdates = PassthroughSubject<DeviceState, Never>()
    
    init(device: YeelightDevice) {
        self.device = device
    }
    
    func connect() {
        // Implementation for device connection
    }
    
    func disconnect() {
        reconnectTask?.cancel()
    }
}

// MARK: - Device Errors
enum DeviceError: LocalizedError {
    case notFound
    case alreadyExists
    case connectionFailed
    case timeout
    case invalidResponse
    case unsupportedOperation
    case offline
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Device not found"
        case .alreadyExists:
            return "Device already exists"
        case .connectionFailed:
            return "Failed to connect to device"
        case .timeout:
            return "Device operation timed out"
        case .invalidResponse:
            return "Invalid response from device"
        case .unsupportedOperation:
            return "Operation not supported by device"
        case .offline:
            return "Device is offline"
        }
    }
} 