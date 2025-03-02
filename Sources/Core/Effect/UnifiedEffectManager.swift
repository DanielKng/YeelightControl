import Foundation
import Combine
import SwiftUI

// MARK: - Effect Manager Protocol
// The Core_EffectManaging protocol is defined in ServiceProtocols.swift

// MARK: - Effect Manager Implementation
public actor UnifiedEffectManager: Core_EffectManaging, Core_BaseService {
    // MARK: - Properties
    
    private var _effects: [Effect] = []
    private var _isEnabled: Bool = true
    
    private let storageManager: any Core_StorageManaging
    private let deviceManager: any Core_DeviceManaging
    private let effectSubject = PassthroughSubject<Effect, Never>()
    private var effectTimers: [String: Timer] = [:]
    
    // MARK: - Initialization
    
    public init(storageManager: any Core_StorageManaging, deviceManager: any Core_DeviceManaging) {
        self.storageManager = storageManager
        self.deviceManager = deviceManager
        
        Task {
            await loadEffects()
        }
    }
    
    // MARK: - Core_BaseService
    
    public nonisolated var isEnabled: Bool {
        let task = Task { await _isEnabled }
        return (try? task.value) ?? false
    }
    
    public var serviceIdentifier: String {
        return "core.effect"
    }
    
    // MARK: - Core_EffectManaging
    
    public nonisolated var effects: [Core_Effect] {
        get async {
            await _effects
        }
    }
    
    public nonisolated var effectUpdates: AnyPublisher<Core_Effect, Never> {
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
        guard let localEffect = await getEffect(withId: effect.id) else {
            throw NSError(domain: "EffectError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Effect not found"])
        }
        
        await applyEffect(localEffect, to: [device.id])
    }
    
    public nonisolated func getAvailableEffects() -> [Core_Effect] {
        let task = Task { await _effects }
        return (try? task.value) ?? []
    }
    
    public func createEffect(name: String, type: Core_EffectType, parameters: Core_EffectParameters) async throws -> Core_Effect {
        let effect = Effect(
            name: name,
            type: type,
            parameters: parameters
        )
        _effects.append(effect)
        
        try await storageManager.save(effect, forKey: "effects.\(effect.id)")
        effectSubject.send(effect)
        
        return effect as Core_Effect
    }
    
    public nonisolated func getEffect(withId id: String) async -> Effect? {
        let allEffects = await _effects
        return allEffects.first { $0.id == id }
    }
    
    public nonisolated func getAllEffects() async -> [Core_Effect] {
        let allEffects = await _effects
        return allEffects.map { $0 as Core_Effect }
    }
    
    public func updateEffect(_ effect: Core_Effect) async throws -> Core_Effect {
        guard let localEffect = effect as? Effect else {
            throw NSError(domain: "EffectError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid effect type"])
        }
        
        if let index = _effects.firstIndex(where: { $0.id == localEffect.id }) {
            _effects[index] = localEffect
            
            try await storageManager.save(localEffect, forKey: "effects.\(localEffect.id)")
            effectSubject.send(localEffect)
            
            return localEffect as Core_Effect
        }
        
        throw NSError(domain: "EffectError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Effect not found"])
    }
    
    public func deleteEffect(_ effect: Core_Effect) async throws {
        guard let localEffect = effect as? Effect else {
            throw NSError(domain: "EffectError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid effect type"])
        }
        
        if let index = _effects.firstIndex(where: { $0.id == localEffect.id }) {
            _effects.remove(at: index)
            
            try await storageManager.remove(forKey: "effects.\(localEffect.id)")
            effectSubject.send(localEffect)
        } else {
            throw NSError(domain: "EffectError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Effect not found"])
        }
    }
    
    public func startEffect(_ effect: Core_Effect) async throws {
        guard let localEffect = effect as? Effect else {
            throw NSError(domain: "EffectError", code: 7, userInfo: [NSLocalizedDescriptionKey: "Invalid effect type"])
        }
        
        var updatedEffect = localEffect
        updatedEffect.isActive = true
        
        _ = try await updateEffect(updatedEffect as Core_Effect)
        await applyEffect(updatedEffect, to: [])
        startEffectTimer(updatedEffect)
    }
    
    public func stopEffect(_ effect: Core_Effect) async throws {
        guard let localEffect = effect as? Effect else {
            throw NSError(domain: "EffectError", code: 8, userInfo: [NSLocalizedDescriptionKey: "Invalid effect type"])
        }
        
        var updatedEffect = localEffect
        updatedEffect.isActive = false
        
        _ = try await updateEffect(updatedEffect as Core_Effect)
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
            let effects = try await storageManager.getAll(Effect.self, withPrefix: "effects.")
            _effects = effects
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

