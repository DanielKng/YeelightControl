import Foundation
import Combine
import SwiftUI

@preconcurrency protocol EffectManaging: Actor {
    nonisolated var effects: [Effect] { get }
    nonisolated var effectUpdates: PassthroughSubject<EffectUpdate, Never> { get }
    func getEffect(byId id: String) -> Effect?
    func getAllEffects() -> [Effect]
    func createEffect(_ effect: Effect) async throws
    func updateEffect(_ effect: Effect) async throws
    func deleteEffect(_ effect: Effect) async throws
    func applyEffect(_ effect: Effect, to deviceIds: [String]) async throws
}

@MainActor
public final class UnifiedEffectManager: ObservableObject, EffectManaging {
    // MARK: - Published Properties
    @Published public private(set) var effects: [Effect] = []
    public let effectUpdates = PassthroughSubject<EffectUpdate, Never>()
    
    // MARK: - Dependencies
    private weak var deviceManager: UnifiedDeviceManager?
    private weak var storageManager: UnifiedStorageManager?
    
    // MARK: - Private Properties
    private var activeEffects: [String: Effect] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    public static let shared = UnifiedEffectManager()
    
    private init() {
        loadEffects()
    }
    
    // MARK: - Public Methods
    public nonisolated func getEffect(byId id: String) -> Effect? {
        effects.first { $0.id == id }
    }
    
    public nonisolated func getAllEffects() -> [Effect] {
        effects
    }
    
    public func createEffect(_ effect: Effect) async throws {
        guard !effects.contains(where: { $0.id == effect.id }) else {
            throw EffectError.alreadyExists
        }
        effects.append(effect)
        try await saveEffects()
        effectUpdates.send(.created(effect))
    }
    
    public func updateEffect(_ effect: Effect) async throws {
        guard let index = effects.firstIndex(where: { $0.id == effect.id }) else {
            throw EffectError.notFound
        }
        effects[index] = effect
        try await saveEffects()
        effectUpdates.send(.updated(effect))
        
        // Update active effects if needed
        for deviceId in activeEffects.keys where activeEffects[deviceId]?.id == effect.id {
            try await applyEffect(effect, to: [deviceId])
        }
    }
    
    public func deleteEffect(_ effect: Effect) async throws {
        guard effects.contains(where: { $0.id == effect.id }) else {
            throw EffectError.notFound
        }
        effects.removeAll { $0.id == effect.id }
        try await saveEffects()
        effectUpdates.send(.deleted(effect.id))
        
        // Stop effect on all devices where it's active
        for deviceId in activeEffects.keys where activeEffects[deviceId]?.id == effect.id {
            try await stopEffect(on: deviceId)
        }
    }
    
    public func applyEffect(_ effect: Effect, to deviceIds: [String]) async throws {
        guard let effect = getEffect(byId: effect.id) else {
            throw EffectError.notFound
        }
        
        for deviceId in deviceIds {
            guard let device = await deviceManager?.getDevice(byId: deviceId) else {
                throw EffectError.deviceNotFound
            }
            
            guard device.state.isOnline else {
                throw EffectError.activationFailed(deviceId: deviceId, error: NetworkError.deviceOffline)
            }
            
            // Store active effect
            activeEffects[deviceId] = effect
            
            // Apply effect parameters
            // Implementation would depend on the specific effect type and device capabilities
        }
        
        effectUpdates.send(.applied(effect, deviceIds))
    }
    
    // MARK: - Private Methods
    private func loadEffects() {
        Task {
            do {
                if let loadedEffects: [Effect] = try await storageManager?.load([Effect].self, forKey: "effects") {
                    self.effects = loadedEffects
                }
            } catch {
                print("Failed to load effects: \(error)")
            }
        }
    }
    
    private func saveEffects() async throws {
        try await storageManager?.save(effects, forKey: "effects")
    }
    
    private func stopEffect(on deviceId: String) async throws {
        guard let device = await deviceManager?.getDevice(byId: deviceId) else {
            throw EffectError.deviceNotFound
        }
        
        // Stop the effect
        activeEffects.removeValue(forKey: deviceId)
        
        // Reset device to default state
        var updatedDevice = device
        updatedDevice.state.brightness = 100
        updatedDevice.state.colorTemperature = 4000
        await deviceManager?.updateDevice(updatedDevice)
    }
} 