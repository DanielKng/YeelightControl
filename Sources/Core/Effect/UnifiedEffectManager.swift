import Foundation
import Combine
import SwiftUI

// MARK: - Effect Manager Protocol
// The Core_EffectManaging protocol is defined in ServiceProtocols.swift

// MARK: - Effect Manager Implementation
public final class UnifiedEffectManager: Core_EffectManaging, ObservableObject {
    // MARK: - Properties
    
    @Published private(set) var _effects: [Effect] = []
    public var effects: [Effect] { _effects }
    
    private let storageManager: any Core_StorageManaging
    private let deviceManager: any Core_DeviceManaging
    private let effectSubject = PassthroughSubject<Effect, Never>()
    private var effectTimers: [String: Timer] = [:]
    
    // MARK: - Initialization
    
    public init(storageManager: any Core_StorageManaging, deviceManager: any Core_DeviceManaging) {
        self.storageManager = storageManager
        self.deviceManager = deviceManager
        self._isEnabled = true
        
        Task {
            await loadEffects()
        }
    }
    
    // MARK: - BaseService
    
    public nonisolated var isEnabled: Bool {
        get { _isEnabled }
    }
    private var _isEnabled: Bool
    
    // MARK: - EffectManaging
    
    public var effectUpdates: AnyPublisher<Effect, Never> {
        effectSubject.eraseToAnyPublisher()
    }
    
    private func startEffectTimer(_ effect: Effect) {
        // Implementation for starting effect timer
        // This would typically involve setting up a timer to control the effect
    }
    
    private func stopEffectTimer(_ effect: Effect) {
        // Implementation for stopping effect timer
        if let timer = effectTimers[effect.id] {
            timer.invalidate()
            effectTimers.removeValue(forKey: effect.id)
        }
    }
    
    public func applyEffect(_ effect: Core_Effect, to device: Core_Device) async throws {
        // Convert Core_Effect to Effect and apply it
        if let localEffect = effects.first(where: { $0.id == effect.id }) {
            await applyEffect(localEffect, to: [device.id])
        }
    }
    
    public func getAvailableEffects() -> [Core_Effect] {
        // Convert local effects to Core_Effect
        return effects
    }
    
    public func createEffect(name: String, type: EffectType, parameters: EffectParameters) async -> Effect {
        let effect = Effect(name: name, type: type, parameters: parameters)
        _effects.append(effect)
        
        try? await storageManager.save(effect, withId: effect.id, inCollection: "effects")
        effectSubject.send(effect)
        
        return effect
    }
    
    public func getEffect(withId id: String) async -> Effect? {
        return _effects.first { $0.id == id }
    }
    
    public func getAllEffects() async -> [Effect] {
        return _effects
    }
    
    public func updateEffect(_ effect: Effect) async -> Effect {
        if let index = _effects.firstIndex(where: { $0.id == effect.id }) {
            _effects[index] = effect
            
            try? await storageManager.save(effect, withId: effect.id, inCollection: "effects")
            effectSubject.send(effect)
            
            return effect
        }
        
        return effect
    }
    
    public func deleteEffect(_ effect: Effect) async {
        if let index = _effects.firstIndex(where: { $0.id == effect.id }) {
            _effects.remove(at: index)
            
            try? await storageManager.delete(withId: effect.id, fromCollection: "effects")
            effectSubject.send(effect)
        }
    }
    
    public func startEffect(_ effect: Effect) async {
        var updatedEffect = effect
        updatedEffect.isActive = true
        
        await updateEffect(updatedEffect)
        await applyEffect(updatedEffect, to: [])
        startEffectTimer(updatedEffect)
    }
    
    public func stopEffect(_ effect: Effect) async {
        var updatedEffect = effect
        updatedEffect.isActive = false
        
        await updateEffect(updatedEffect)
        stopEffectTimer(updatedEffect)
    }
    
    public func applyEffect(_ effect: Effect, to deviceIds: [String]) async {
        // Implementation for applying the effect to devices
        // This would typically involve sending commands to the devices
        print("Applying effect \(effect.name) to devices: \(deviceIds)")
        // Actual implementation would go here
    }
    
    // MARK: - Private Methods
    
    private func loadEffects() async {
        do {
            _effects = try await storageManager.getAll(fromCollection: "effects")
        } catch {
            print("Failed to load effects: \(error.localizedDescription)")
        }
    }
}

// MARK: - Queue Extension
extension DispatchQueue {
    func run<T>(_ block: @escaping () async throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            self.async {
                Task {
                    do {
                        let result = try await block()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
