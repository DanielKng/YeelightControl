import Foundation
import Combine
import SwiftUI

// MARK: - State Managing Protocol
// Core_StateManaging protocol is defined in StateTypes.swift

@MainActor
public final class UnifiedStateManager: ObservableObject, Core_StateManaging {
    private let services: ServiceContainer
    @Published public private(set) var _deviceStates: [String: DeviceState] = [:]
    private let stateSubject = PassthroughSubject<DeviceStateUpdate, Never>()
    private var _isEnabled: Bool = true
    
    // MARK: - Core_BaseService
    public nonisolated var isEnabled: Bool {
        let value = false // Default value
        let task = Task { @MainActor in
            return _isEnabled
        }
        return (try? task.value) ?? value
    }
    
    // MARK: - Core_StateManaging
    public nonisolated var deviceStates: [String: Core_DeviceState] {
        let value: [String: Core_DeviceState] = [:] // Default empty dictionary
        let task = Task { @MainActor in
            return _deviceStates as [String: Core_DeviceState]
        }
        return (try? task.value) ?? value
    }
    
    public nonisolated var stateUpdates: AnyPublisher<[String: Core_DeviceState], Never> {
        return stateSubject.map { update in
            // Create a dictionary with just the updated device state
            return [update.deviceId: update.newState as Core_DeviceState]
        }.eraseToAnyPublisher()
    }
    
    public func updateDeviceState(_ state: Core_DeviceState, forDeviceId deviceId: String) async {
        if let deviceState = state as? DeviceState {
            _deviceStates[deviceId] = deviceState
        }
    }
    
    public nonisolated func getDeviceState(forDeviceId deviceId: String) -> Core_DeviceState? {
        let task = Task { @MainActor in
            return _deviceStates[deviceId]
        }
        return try? task.value
    }
    
    public init(services: ServiceContainer) {
        self.services = services
    }
    
    private func updateDeviceState(_ deviceId: String, newState: DeviceState) throws {
        guard let oldState = _deviceStates[deviceId] else {
            throw DeviceError.invalidState
        }
        
        _deviceStates[deviceId] = newState
        let update = DeviceStateUpdate(deviceId: deviceId, oldState: oldState, newState: newState)
        stateSubject.send(update)
    }
    
    public nonisolated func getState(for deviceId: String) -> DeviceState? {
        Task { @MainActor in
            return _deviceStates[deviceId]
        }.result.value
    }
    
    public nonisolated func setState(_ state: DeviceState, for deviceId: String) async throws {
        try await MainActor.run {
            try updateDeviceState(deviceId, newState: state)
        }
    }
    
    public nonisolated func removeState(for deviceId: String) {
        Task { @MainActor in
            _deviceStates.removeValue(forKey: deviceId)
        }
    }
} 