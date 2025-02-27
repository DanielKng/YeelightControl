import Foundation
import Combine

protocol EffectManaging {
    func createEffect(_ effect: Effect) async throws
    func updateEffect(_ effect: Effect) async throws
    func deleteEffect(_ id: String) async throws
    func getEffect(_ id: String) async throws -> Effect
    func getAllEffects() async throws -> [Effect]
    func applyEffect(_ id: String, to deviceIds: [String]) async throws
    func stopEffect(on deviceIds: [String]) async throws
    var effectsPublisher: AnyPublisher<[Effect], Never> { get }
}

struct Effect: Codable, Identifiable {
    let id: String
    var name: String
    var type: EffectType
    var parameters: EffectParameters
    var previewColor: String?
    var duration: TimeInterval?
    var isLooping: Bool
    var createdAt: Date
    var updatedAt: Date
}

enum EffectType: String, Codable {
    case pulse
    case breathe
    case flow
    case strobe
    case gradient
    case rainbow
    case music
    case custom
}

struct EffectParameters: Codable {
    var colors: [String]
    var speed: Int
    var brightness: Int
    var transition: TransitionType
    var customProperties: [String: String]?
    
    enum TransitionType: String, Codable {
        case smooth
        case sudden
        case linear
        case easeIn
        case easeOut
        case easeInOut
    }
}

final class EffectManager: EffectManaging {
    private let services: ServiceContainer
    private let storage: StorageManaging
    private let deviceManager: DeviceManaging
    private let effectsSubject = CurrentValueSubject<[Effect], Never>([])
    private var subscriptions = Set<AnyCancellable>()
    private var activeEffects: [String: Effect] = [:] // deviceId: Effect
    
    init(services: ServiceContainer) {
        self.services = services
        self.storage = services.storageManager
        self.deviceManager = services.deviceManager
        
        setupSubscriptions()
        loadEffects()
    }
    
    var effectsPublisher: AnyPublisher<[Effect], Never> {
        effectsSubject.eraseToAnyPublisher()
    }
    
    func createEffect(_ effect: Effect) async throws {
        var effects = effectsSubject.value
        effects.append(effect)
        try await saveEffects(effects)
        effectsSubject.send(effects)
    }
    
    func updateEffect(_ effect: Effect) async throws {
        var effects = effectsSubject.value
        guard let index = effects.firstIndex(where: { $0.id == effect.id }) else {
            throw EffectError.notFound
        }
        effects[index] = effect
        try await saveEffects(effects)
        effectsSubject.send(effects)
        
        // Update active effects if needed
        for (deviceId, activeEffect) in activeEffects where activeEffect.id == effect.id {
            try await applyEffect(effect.id, to: [deviceId])
        }
    }
    
    func deleteEffect(_ id: String) async throws {
        var effects = effectsSubject.value
        guard let index = effects.firstIndex(where: { $0.id == id }) else {
            throw EffectError.notFound
        }
        effects.remove(at: index)
        try await saveEffects(effects)
        effectsSubject.send(effects)
        
        // Stop effect on any devices using it
        let affectedDevices = activeEffects.filter { $0.value.id == id }.map { $0.key }
        if !affectedDevices.isEmpty {
            try await stopEffect(on: affectedDevices)
        }
    }
    
    func getEffect(_ id: String) async throws -> Effect {
        guard let effect = effectsSubject.value.first(where: { $0.id == id }) else {
            throw EffectError.notFound
        }
        return effect
    }
    
    func getAllEffects() async throws -> [Effect] {
        return effectsSubject.value
    }
    
    func applyEffect(_ id: String, to deviceIds: [String]) async throws {
        guard let effect = try? await getEffect(id) else {
            throw EffectError.notFound
        }
        
        for deviceId in deviceIds {
            guard let device = try? await deviceManager.getDevice(deviceId) else {
                continue
            }
            
            // Apply effect parameters to device
            try await applyEffectToDevice(effect, device: device)
            activeEffects[deviceId] = effect
        }
    }
    
    func stopEffect(on deviceIds: [String]) async throws {
        for deviceId in deviceIds {
            guard let device = try? await deviceManager.getDevice(deviceId) else {
                continue
            }
            
            // Reset device to default state
            try await deviceManager.updateDeviceState(deviceId, state: .init(power: true))
            activeEffects.removeValue(forKey: deviceId)
        }
    }
    
    private func setupSubscriptions() {
        deviceManager.deviceStatePublisher
            .sink { [weak self] updates in
                Task {
                    await self?.handleDeviceStateUpdates(updates)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func loadEffects() {
        Task {
            do {
                let effects: [Effect] = try await storage.load(.effects)
                effectsSubject.send(effects)
            } catch {
                print("Failed to load effects: \(error)")
                effectsSubject.send([])
            }
        }
    }
    
    private func saveEffects(_ effects: [Effect]) async throws {
        try await storage.save(effects, for: .effects)
    }
    
    private func applyEffectToDevice(_ effect: Effect, device: Device) async throws {
        let command: DeviceCommand
        
        switch effect.type {
        case .pulse:
            command = .pulse(colors: effect.parameters.colors, speed: effect.parameters.speed)
        case .breathe:
            command = .breathe(colors: effect.parameters.colors, speed: effect.parameters.speed)
        case .flow:
            command = .flow(colors: effect.parameters.colors, speed: effect.parameters.speed)
        case .strobe:
            command = .strobe(colors: effect.parameters.colors, speed: effect.parameters.speed)
        case .gradient:
            command = .gradient(colors: effect.parameters.colors, transition: effect.parameters.transition)
        case .rainbow:
            command = .rainbow(speed: effect.parameters.speed)
        case .music:
            command = .music(sensitivity: effect.parameters.speed)
        case .custom:
            command = .custom(effect.parameters.customProperties ?? [:])
        }
        
        try await deviceManager.sendCommand(device.id, command: command)
    }
    
    private func handleDeviceStateUpdates(_ updates: [DeviceStateUpdate]) async {
        // Handle device state changes that might affect active effects
        for update in updates {
            if update.state.power == false {
                activeEffects.removeValue(forKey: update.deviceId)
            }
        }
    }
}

enum EffectError: LocalizedError {
    case notFound
    case invalidParameters
    case deviceNotSupported
    case applicationFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "Effect not found"
        case .invalidParameters: return "Invalid effect parameters"
        case .deviceNotSupported: return "Device does not support this effect"
        case .applicationFailed: return "Failed to apply effect to device"
        }
    }
} 