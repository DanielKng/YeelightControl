import Foundation
import Combine
import SwiftUI

// MARK: - State Managing Protocol
protocol StateManaging {
    var deviceStates: [String: DeviceState] { get }
    var stateUpdates: AnyPublisher<DeviceStateUpdate, Never> { get }
    
    func getState(for deviceId: String) -> DeviceState?
    func setState(_ state: DeviceState, for deviceId: String) async throws
    func removeState(for deviceId: String)
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

@MainActor
public final class UnifiedStateManager: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var deviceStates: [String: DeviceState] = [:]
    public let stateUpdates = PassthroughSubject<DeviceStateUpdate, Never>()
    
    // MARK: - Dependencies
    private weak var storageManager: UnifiedStorageManager?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    public static let shared = UnifiedStateManager()
    
    private init() {
        loadStates()
    }
    
    // MARK: - Public Methods
    public func getState(for deviceId: String) -> DeviceState? {
        deviceStates[deviceId]
    }
    
    public func setState(_ state: DeviceState, for deviceId: String) {
        deviceStates[deviceId] = state
        saveStates()
        stateUpdates.send(DeviceStateUpdate(deviceId: deviceId, state: state))
    }
    
    public func removeState(for deviceId: String) {
        deviceStates.removeValue(forKey: deviceId)
        saveStates()
    }
    
    // MARK: - Private Methods
    private func loadStates() {
        do {
            if let states: [String: DeviceState] = try storageManager?.load([String: DeviceState].self, forKey: "device_states") {
                deviceStates = states
            }
        } catch {
            print("Failed to load device states: \(error)")
        }
    }
    
    private func saveStates() {
        do {
            try storageManager?.save(deviceStates, forKey: "device_states")
        } catch {
            print("Failed to save device states: \(error)")
        }
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