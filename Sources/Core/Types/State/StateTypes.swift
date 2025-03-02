import Foundation
import Combine

// MARK: - State Protocols
@preconcurrency public protocol Core_StateManaging: Core_BaseService {
    /// The device states
    nonisolated var deviceStates: [String: Core_DeviceState] { get }
    
    /// Publisher for state updates
    nonisolated var stateUpdates: AnyPublisher<[String: Core_DeviceState], Never> { get }
    
    /// Update a device state
    func updateDeviceState(_ state: Core_DeviceState, forDeviceId deviceId: String) async
    
    /// Get a device state - making this async to properly handle actor isolation
    nonisolated func getDeviceState(forDeviceId deviceId: String) async -> Core_DeviceState?
}

// MARK: - Device State Update
public struct DeviceStateUpdate {
    public let deviceId: String
    public let oldState: DeviceState
    public let newState: DeviceState
    
    public init(deviceId: String, oldState: DeviceState, newState: DeviceState) {
        self.deviceId = deviceId
        self.oldState = oldState
        self.newState = newState
    }
}

// MARK: - App State
public struct AppState: Codable, Equatable {
    public var deviceStates: [String: DeviceState]
    
    public init(deviceStates: [String: DeviceState] = [:]) {
        self.deviceStates = deviceStates
    }
}

// MARK: - State Update
public enum StateUpdate {
    case deviceState(DeviceStateUpdate)
} 