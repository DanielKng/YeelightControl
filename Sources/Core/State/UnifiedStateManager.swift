import Foundation
import Combine
import SwiftUI

// MARK: - State Managing Protocol
// Core_StateManaging protocol is defined in StateTypes.swift

// Update DeviceError enum to include invalidState case
extension DeviceError {
    // No need for a static property, we'll use the existing enum cases
}

@MainActor
public final class UnifiedStateManager: ObservableObject, Core_StateManaging {
    private let services: ServiceContainer
    @Published public private(set) var _deviceStates: [String: DeviceState] = [:]
    private let stateSubject = PassthroughSubject<[String: Core_DeviceState], Never>()
    @MainActor private var _isEnabledInternal: Bool = true
    
    // Create a nonisolated publisher that can be accessed from nonisolated contexts
    private nonisolated let nonIsolatedPublisher: AnyPublisher<[String: Core_DeviceState], Never>
    
    // Add a nonisolated cache of core states
    private nonisolated(unsafe) var _nonisolatedDeviceStates: [String: Core_DeviceState] = [:]
    
    // MARK: - Core_BaseService
    public nonisolated var isEnabled: Bool {
        // Simple nonisolated property that always returns true
        true
    }
    
    // MARK: - Core_StateManaging
    public nonisolated var deviceStates: [String: Core_DeviceState] {
        get {
            // Return the nonisolated cache
            return _nonisolatedDeviceStates
        }
    }
    
    public nonisolated var stateUpdates: AnyPublisher<[String: Core_DeviceState], Never> {
        // Use the nonisolated publisher
        return nonIsolatedPublisher
    }
    
    public func updateDeviceState(_ state: Core_DeviceState, forDeviceId deviceId: String) async {
        // Remove the conditional binding since DeviceState.from returns a non-optional
        let deviceState = DeviceState.from(coreState: state)
        _deviceStates[deviceId] = deviceState
        // Update the nonisolated cache
        _nonisolatedDeviceStates[deviceId] = state
        // Publish the update
        let updates = [deviceId: state]
        stateSubject.send(updates)
    }
    
    public nonisolated func getDeviceState(forDeviceId deviceId: String) async -> Core_DeviceState? {
        return await MainActor.run {
            return _deviceStates[deviceId]?.coreState
        }
    }
    
    public init(services: ServiceContainer) {
        self.services = services
        // Initialize the nonisolated publisher
        self.nonIsolatedPublisher = stateSubject.eraseToAnyPublisher()
    }
    
    private func updateDeviceState(_ deviceId: String, newState: DeviceState) throws {
        guard _deviceStates[deviceId] != nil else {
            throw DeviceError.invalidDevice // Use an existing case instead
        }
        
        _deviceStates[deviceId] = newState
        // Publish the update
        let updates = [deviceId: newState.coreState]
        stateSubject.send(updates)
    }
    
    public nonisolated func getState(for deviceId: String) async -> DeviceState? {
        return await MainActor.run {
            return _deviceStates[deviceId]
        }
    }
    
    public nonisolated func setState(_ state: DeviceState, for deviceId: String) async throws {
        try await MainActor.run {
            try updateDeviceState(deviceId, newState: state)
        }
    }
    
    public nonisolated func removeState(for deviceId: String) async {
        _ = await MainActor.run {
            _deviceStates.removeValue(forKey: deviceId)
        }
    }
} 