import Foundation
import Combine

// MARK: - Device Managing Protocol
protocol DeviceManaging {
    var discoveredDevices: [YeelightDevice] { get }
    var deviceUpdates: AnyPublisher<DeviceUpdate, Never> { get }
    
    func getDevice(byId id: String) -> YeelightDevice?
    func getAllDevices() -> [YeelightDevice]
    func discoverDevices() async
    func addDevice(_ device: YeelightDevice) async throws
    func removeDevice(_ device: YeelightDevice) async throws
    func updateDevice(_ device: YeelightDevice) async throws
}

// MARK: - Device Update Type
enum DeviceUpdate {
    case added(YeelightDevice)
    case updated(YeelightDevice)
    case removed(String)
    case discovered([YeelightDevice])
}

// MARK: - Device Model
struct YeelightDevice: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var model: String
    var firmwareVersion: String
    var ipAddress: String
    var port: Int
    var capabilities: Set<Capability>
    var supportedEffects: Set<Effect>
    var supportedScenes: Set<Scene>
    var isOnline: Bool
    var lastSeen: Date
    
    enum Capability: String, Codable {
        case power
        case brightness
        case colorTemperature
        case color
        case scene
        case effect
        case music
        case flow
    }
    
    enum Effect: String, Codable {
        case smooth
        case sudden
        case strobe
        case pulse
        case colorFlow
    }
    
    enum Scene: String, Codable {
        case bright
        case tv
        case reading
        case night
        case custom
    }
}

// MARK: - Device Manager Implementation
final class UnifiedDeviceManager: DeviceManaging, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var discoveredDevices: [YeelightDevice] = []
    
    // MARK: - Publishers
    private let deviceSubject = PassthroughSubject<DeviceUpdate, Never>()
    var deviceUpdates: AnyPublisher<DeviceUpdate, Never> {
        deviceSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let services: ServiceContainer
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
    
    // MARK: - Initialization
    init(services: ServiceContainer = .shared) {
        self.services = services
        setupObservers()
        loadStoredDevices()
    }
    
    // MARK: - Public Methods
    func getDevice(byId id: String) -> YeelightDevice? {
        queue.sync {
            discoveredDevices.first { $0.id == id }
        }
    }
    
    func getAllDevices() -> [YeelightDevice] {
        queue.sync {
            discoveredDevices
        }
    }
    
    func discoverDevices() async {
        discoveryTask?.cancel()
        
        discoveryTask = Task {
            do {
                // Start network discovery
                await services.networkManager.startDiscovery()
                
                // Wait for discovery completion
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                
                // Process discovered devices
                let newDevices = services.networkManager.discoveredDevices.map { discovered in
                    YeelightDevice(
                        id: discovered.id,
                        name: "Yeelight \(discovered.model)",
                        model: discovered.model,
                        firmwareVersion: "1.0",
                        ipAddress: discovered.ipAddress,
                        port: discovered.port,
                        capabilities: [.power, .brightness],
                        supportedEffects: [.smooth, .sudden],
                        supportedScenes: [.bright, .night],
                        isOnline: true,
                        lastSeen: Date()
                    )
                }
                
                // Update devices
                await updateDiscoveredDevices(newDevices)
                
            } catch {
                services.logger.error("Device discovery failed: \(error.localizedDescription)", category: .device)
            }
            
            services.networkManager.stopDiscovery()
        }
    }
    
    func addDevice(_ device: YeelightDevice) async throws {
        try await queue.run {
            // Validate device
            guard !discoveredDevices.contains(where: { $0.id == device.id }) else {
                throw DeviceError.alreadyExists
            }
            
            // Add device
            discoveredDevices.append(device)
            deviceSubject.send(.added(device))
            
            // Save devices
            try await saveDevices()
            
            // Create connection
            setupDeviceConnection(for: device)
            
            services.logger.info("Added device: \(device.name)", category: .device)
        }
    }
    
    func removeDevice(_ device: YeelightDevice) async throws {
        try await queue.run {
            // Remove device
            discoveredDevices.removeAll { $0.id == device.id }
            deviceSubject.send(.removed(device.id))
            
            // Remove connection
            deviceConnections[device.id]?.disconnect()
            deviceConnections.removeValue(forKey: device.id)
            
            // Save devices
            try await saveDevices()
            
            services.logger.info("Removed device: \(device.name)", category: .device)
        }
    }
    
    func updateDevice(_ device: YeelightDevice) async throws {
        try await queue.run {
            guard let index = discoveredDevices.firstIndex(where: { $0.id == device.id }) else {
                throw DeviceError.notFound
            }
            
            // Update device
            discoveredDevices[index] = device
            deviceSubject.send(.updated(device))
            
            // Save devices
            try await saveDevices()
            
            services.logger.info("Updated device: \(device.name)", category: .device)
        }
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Observe network status changes
        services.networkManager.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.handleNetworkConnected()
                } else {
                    self?.handleNetworkDisconnected()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadStoredDevices() {
        Task {
            do {
                let devices: [YeelightDevice] = try await services.storage.load(forKey: .devices)
                await updateDiscoveredDevices(devices)
            } catch {
                services.logger.error("Failed to load stored devices: \(error.localizedDescription)", category: .device)
            }
        }
    }
    
    private func saveDevices() async throws {
        try await services.storage.save(discoveredDevices, forKey: .devices)
    }
    
    private func updateDiscoveredDevices(_ devices: [YeelightDevice]) async {
        await queue.run {
            // Update devices list
            discoveredDevices = devices
            
            // Notify about discovered devices
            deviceSubject.send(.discovered(devices))
            
            // Setup connections for online devices
            for device in devices where device.isOnline {
                setupDeviceConnection(for: device)
            }
            
            services.logger.info("Updated discovered devices: \(devices.count) devices", category: .device)
        }
    }
    
    private func setupDeviceConnection(for device: YeelightDevice) {
        let connection = DeviceConnection(device: device, services: services)
        deviceConnections[device.id] = connection
        
        connection.stateUpdates
            .sink { [weak self] state in
                self?.handleDeviceStateUpdate(deviceId: device.id, state: state)
            }
            .store(in: &cancellables)
        
        connection.connect()
    }
    
    private func handleDeviceStateUpdate(deviceId: String, state: DeviceState) {
        Task {
            do {
                // Update device online status
                if var device = getDevice(byId: deviceId) {
                    device.isOnline = true
                    device.lastSeen = Date()
                    try await updateDevice(device)
                }
                
                // Save device state
                try await services.stateManager.setState(state, for: deviceId)
            } catch {
                services.logger.error("Failed to handle device state update: \(error.localizedDescription)", category: .device)
            }
        }
    }
    
    private func handleNetworkConnected() {
        Task {
            await discoverDevices()
        }
    }
    
    private func handleNetworkDisconnected() {
        // Mark all devices as offline
        Task {
            for var device in discoveredDevices {
                device.isOnline = false
                try? await updateDevice(device)
            }
        }
    }
}

// MARK: - Device Connection
private class DeviceConnection {
    private let device: YeelightDevice
    private let services: ServiceContainer
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts = 0
    
    let stateUpdates = PassthroughSubject<DeviceState, Never>()
    
    init(device: YeelightDevice, services: ServiceContainer) {
        self.device = device
        self.services = services
    }
    
    func connect() {
        // Implementation for device connection
        // This would include:
        // 1. Establishing TCP connection
        // 2. Setting up command queue
        // 3. Starting keep-alive timer
        // 4. Handling reconnection
    }
    
    func disconnect() {
        reconnectTask?.cancel()
        // Implementation for device disconnection
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