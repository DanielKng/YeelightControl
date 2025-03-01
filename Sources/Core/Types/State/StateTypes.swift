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
    
    /// Get a device state
    func getDeviceState(forDeviceId deviceId: String) -> Core_DeviceState?
} 