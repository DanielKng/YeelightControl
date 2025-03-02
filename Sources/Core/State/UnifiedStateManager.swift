import Foundation
import Combine
import SwiftUI

// MARK: - State Managing Protocol
// Core_StateManaging protocol is defined in StateTypes.swift

@MainActor
public final class UnifiedStateManager: ObservableObject, Core_StateManaging {
    private let services: ServiceContainer
    @Published public private(set) var _deviceStates: [String: DeviceState] = [:]
    private let stateSubject = PassthroughSubject<[String: Core_DeviceState], Never>()
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
            var result: [String: Core_DeviceState] = [:]
            for (key, state) in _deviceStates {
                result[key] = state.coreState
            }
            return result
        }
        return (try? task.value) ?? value
    }
    
    public nonisolated var stateUpdates: AnyPublisher<[String: Core_DeviceState], Never> {
        return stateSubject.eraseToAnyPublisher()
    }
    
    public func updateDeviceState(_ state: Core_DeviceState, forDeviceId deviceId: String) async {
        if let deviceState = DeviceState.from(coreState: state) {
            _deviceStates[deviceId] = deviceState
            // Publish the update
            let updates = [deviceId: state]
            stateSubject.send(updates)
        }
    }
    
    public nonisolated func getDeviceState(forDeviceId deviceId: String) async -> Core_DeviceState? {
        return await MainActor.run {
            return _deviceStates[deviceId]?.coreState
        }
    }
    
    public init(services: ServiceContainer) {
        self.services = services
    }
    
    private func updateDeviceState(_ deviceId: String, newState: DeviceState) throws {
        guard let oldState = _deviceStates[deviceId] else {
            throw DeviceError.invalidState
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
        await MainActor.run {
            _deviceStates.removeValue(forKey: deviceId)
        }
    }
} 