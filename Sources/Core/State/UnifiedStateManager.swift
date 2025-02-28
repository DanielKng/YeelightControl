import Foundation
import Combine
import SwiftUI

// MARK: - State Managing Protocol
@preconcurrency public protocol StateManaging: Actor {
    nonisolated var deviceStates: [String: DeviceState] { get }
    nonisolated var stateUpdates: AnyPublisher<DeviceStateUpdate, Never> { get }
    
    func getState(for deviceId: String) -> DeviceState?
    func setState(_ state: DeviceState, for deviceId: String) async throws
    func removeState(for deviceId: String)
}

@MainActor
public final class UnifiedStateManager: ObservableObject, StateManaging {
    private let services: ServiceContainer
    @Published private(set) var deviceStates: [String: DeviceState] = [:]
    private let stateSubject = PassthroughSubject<DeviceStateUpdate, Never>()
    
    public init(services: ServiceContainer) {
        self.services = services
    }
    
    private func updateDeviceState(_ deviceId: String, newState: DeviceState) throws {
        guard let oldState = deviceStates[deviceId] else {
            throw DeviceError.invalidState
        }
        
        deviceStates[deviceId] = newState
        let update = DeviceStateUpdate(deviceId: deviceId, oldState: oldState, newState: newState)
        stateSubject.send(update)
    }
    
    public func getState(for deviceId: String) -> DeviceState? {
        return deviceStates[deviceId]
    }
    
    public func setState(_ state: DeviceState, for deviceId: String) async throws {
        try updateDeviceState(deviceId, newState: state)
    }
    
    public func removeState(for deviceId: String) {
        deviceStates.removeValue(forKey: deviceId)
    }
    
    public nonisolated var stateUpdates: AnyPublisher<DeviceStateUpdate, Never> {
        stateSubject.eraseToAnyPublisher()
    }
} 