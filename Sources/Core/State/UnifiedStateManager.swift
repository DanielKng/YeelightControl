import Foundation
import Combine

// MARK: - State Managing Protocol
protocol StateManaging {
    var stateUpdates: AnyPublisher<DeviceState, Never> { get }
    
    func getState(for deviceId: String) -> DeviceState?
    func setState(_ state: DeviceState, for deviceId: String) async throws
    func syncState(for deviceId: String) async throws
    func resetState(for deviceId: String)
}

// MARK: - Device State
struct DeviceState: Codable, Equatable {
    var power: Bool
    var brightness: Int
    var colorTemperature: Int
    var color: Color?
    var effect: Effect?
    var scene: Scene?
    var lastUpdate: Date
    var isOnline: Bool
    
    struct Color: Codable, Equatable {
        var red: Int
        var green: Int
        var blue: Int
        
        init(red: Int, green: Int, blue: Int) {
            self.red = max(0, min(255, red))
            self.green = max(0, min(255, green))
            self.blue = max(0, min(255, blue))
        }
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

// MARK: - State Manager Implementation
final class UnifiedStateManager: StateManaging, ObservableObject {
    // MARK: - Publishers
    private let stateSubject = PassthroughSubject<DeviceState, Never>()
    var stateUpdates: AnyPublisher<DeviceState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let services: ServiceContainer
    private let queue = DispatchQueue(label: "de.knng.app.yeelightcontrol.state", qos: .userInitiated)
    private var states: [String: DeviceState] = [:]
    private var syncTasks: [String: Task<Void, Error>] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private struct Configuration {
        var syncInterval: TimeInterval = 5
        var maxRetryAttempts = 3
        var retryDelay: TimeInterval = 1
        var stateTimeout: TimeInterval = 10
    }
    
    // MARK: - Initialization
    init(services: ServiceContainer = .shared) {
        self.services = services
        setupStateObservers()
    }
    
    // MARK: - Public Methods
    func getState(for deviceId: String) -> DeviceState? {
        queue.sync {
            states[deviceId]
        }
    }
    
    func setState(_ state: DeviceState, for deviceId: String) async throws {
        try await queue.run {
            guard let device = services.deviceManager.getDevice(byId: deviceId) else {
                throw StateError.deviceNotFound
            }
            
            // Update device state
            try await device.updateState(state)
            
            // Update local state
            states[deviceId] = state
            stateSubject.send(state)
            
            // Save state
            try await saveState(state, for: deviceId)
            
            services.logger.info("Updated state for device \(deviceId)", category: .device)
        }
    }
    
    func syncState(for deviceId: String) async throws {
        // Cancel existing sync task if any
        syncTasks[deviceId]?.cancel()
        
        let task = Task {
            try await queue.run {
                guard let device = services.deviceManager.getDevice(byId: deviceId) else {
                    throw StateError.deviceNotFound
                }
                
                // Get device state
                let state = try await device.getState()
                
                // Update local state
                states[deviceId] = state
                stateSubject.send(state)
                
                // Save state
                try await saveState(state, for: deviceId)
                
                services.logger.info("Synced state for device \(deviceId)", category: .device)
            }
        }
        
        syncTasks[deviceId] = task
        try await task.value
    }
    
    func resetState(for deviceId: String) {
        queue.async {
            self.states.removeValue(forKey: deviceId)
            self.syncTasks[deviceId]?.cancel()
            self.syncTasks.removeValue(forKey: deviceId)
            services.logger.info("Reset state for device \(deviceId)", category: .device)
        }
    }
    
    // MARK: - Private Methods
    private func setupStateObservers() {
        // Observe device removals
        services.deviceManager.deviceUpdates
            .sink { [weak self] update in
                switch update {
                case .removed(let deviceId):
                    self?.resetState(for: deviceId)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe network status
        services.networkManager.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.syncAllStates()
                }
            }
            .store(in: &cancellables)
    }
    
    private func syncAllStates() {
        Task {
            let devices = services.deviceManager.getAllDevices()
            for device in devices {
                try? await syncState(for: device.id)
            }
        }
    }
    
    private func saveState(_ state: DeviceState, for deviceId: String) async throws {
        let key = StorageKey.deviceState(deviceId)
        try await services.storage.save(state, forKey: key)
    }
}

// MARK: - State Errors
enum StateError: LocalizedError {
    case deviceNotFound
    case invalidState
    case syncFailed
    case timeout
    case updateFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Device not found"
        case .invalidState:
            return "Invalid device state"
        case .syncFailed:
            return "Failed to sync device state"
        case .timeout:
            return "State operation timed out"
        case .updateFailed(let reason):
            return "Failed to update state: \(reason)"
        }
    }
} 