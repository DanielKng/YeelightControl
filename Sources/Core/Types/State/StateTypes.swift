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
// Using CoreDeviceStateUpdate typealias to avoid ambiguity
// Commented out to avoid redeclaration
/*
// Commented out to avoid ambiguity
// // Commented out to avoid ambiguity
// public struct DeviceStateUpdate {
    public let deviceId: String
    public let oldState: CoreDeviceState
    public let newState: CoreDeviceState
    
    public init(deviceId: String, oldState: CoreDeviceState, newState: CoreDeviceState) {
        self.deviceId = deviceId
        self.oldState = oldState
        self.newState = newState
    }
}
*/

// MARK: - App State
// Renamed to Core_AppState to avoid ambiguity
public struct Core_AppState: Codable, Equatable {
    public var deviceStates: [String: Core_DeviceState]
    
    public init(deviceStates: [String: Core_DeviceState] = [:]) {
        self.deviceStates = deviceStates
    }
}

// MARK: - State Update
public enum StateUpdate {
    case deviceState(DeviceStateUpdate)
} 