import Foundation
import Combine
import SwiftUI

// MARK: - Effect Manager Protocol
public protocol EffectManaging: AnyObject {
    var isEnabled: Bool { get set }
    var effects: [Effect] { get }
    
    var effectUpdates: AnyPublisher<Effect, Never> { get }
    
    func getEffect(withId id: String) async -> Effect?
    func getAllEffects() async -> [Effect]
    func createEffect(name: String, type: EffectType, parameters: EffectParameters) async -> Effect
    func updateEffect(_ effect: Effect) async -> Effect
    func deleteEffect(_ effect: Effect) async
    func startEffect(_ effect: Effect) async
    func stopEffect(_ effect: Effect) async
    func applyEffect(_ effect: Effect, to deviceIds: [String]) async
}

// MARK: - Effect Manager Implementation
public final class UnifiedEffectManager: EffectManaging, ObservableObject {
    // MARK: - Properties
    
    @Published private(set) var _effects: [Effect] = []
    public var effects: [Effect] { _effects }
    
    private let storageManager: any StorageManaging
    private let deviceManager: any DeviceManaging
    private let effectSubject = PassthroughSubject<Effect, Never>()
    private var effectTimers: [String: Timer] = [:]
    
    // MARK: - Initialization
    
    public init(storageManager: any StorageManaging, deviceManager: any DeviceManaging) {
        self.storageManager = storageManager
        self.deviceManager = deviceManager
        self.isEnabled = true
        
        Task {
            await loadEffects()
        }
    }
    
    // MARK: - BaseService
    
    public var isEnabled: Bool
    
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
    
    public func applyEffect(_ effect: Effect, to deviceIds: [String]) async {
        // Implementation for applying the effect to devices
        // This would typically involve sending commands to the devices
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
