import Foundation
import Combine

// MARK: - Effect Managing Protocol
@preconcurrency
public protocol EffectManaging {
    var effectUpdates: AnyPublisher<EffectUpdate, Never> { get }
    
    func createEffect(name: String, type: EffectType, parameters: EffectParameters) async -> Effect
    func getEffect(withId id: String) async -> Effect?
    func getAllEffects() async -> [Effect]
    func updateEffect(_ effect: Effect) async -> Effect
    func deleteEffect(_ effect: Effect) async
    func startEffect(_ effect: Effect) async
    func stopEffect(_ effect: Effect) async
    func stopAllEffects() async
}

// MARK: - Effect Model
struct Effect: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var icon: String
    var type: EffectType
    var parameters: EffectParameters
    var isPreset: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String = "sparkles",
        type: EffectType,
        parameters: EffectParameters,
        isPreset: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.type = type
        self.parameters = parameters
        self.isPreset = isPreset
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static let presets: [Effect] = [
        Effect(
            name: "Pulse",
            type: .pulse,
            parameters: .init(
                duration: 1000,
                brightness: [20, 100],
                colorTemperature: nil,
                colors: nil,
                repeat: true
            ),
            isPreset: true
        ),
        Effect(
            name: "Rainbow",
            type: .colorFlow,
            parameters: .init(
                duration: 2000,
                brightness: [80],
                colorTemperature: nil,
                colors: [
                    [255, 0, 0],
                    [255, 127, 0],
                    [255, 255, 0],
                    [0, 255, 0],
                    [0, 0, 255],
                    [75, 0, 130],
                    [148, 0, 211]
                ],
                repeat: true
            ),
            isPreset: true
        ),
        Effect(
            name: "Strobe",
            type: .strobe,
            parameters: .init(
                duration: 100,
                brightness: [0, 100],
                colorTemperature: nil,
                colors: nil,
                repeat: true
            ),
            isPreset: true
        )
    ]
}

// MARK: - Effect Types
enum EffectType: String, Codable {
    case smooth
    case sudden
    case strobe
    case pulse
    case colorFlow
}

struct EffectParameters: Codable, Equatable {
    var duration: Int // milliseconds
    var brightness: [Int]
    var colorTemperature: [Int]?
    var colors: [[Int]]? // RGB arrays
    var `repeat`: Bool
}

// MARK: - Effect Update Type
enum EffectUpdate {
    case created(Effect)
    case updated(Effect)
    case deleted(String)
    case applied(Effect, [String])
    case stopped([String])
    case allStopped
}

// MARK: - Effect Manager Implementation
@MainActor
public final class UnifiedEffectManager: ObservableObject {
    private let effectSubject = PassthroughSubject<EffectUpdate, Never>()
    private var effects: [String: Effect] = [:]
    private var activeEffects: Set<String> = []
    private var effectTimers: [String: Timer] = [:]
    
    public static let shared = UnifiedEffectManager()
    
    private init() {
        // Load preset effects
        for preset in Effect.presets {
            effects[preset.id] = preset
        }
    }
    
    private func startEffectTimer(_ effect: Effect) {
        guard !effectTimers.keys.contains(effect.id) else { return }
        
        let timer = Timer.scheduledTimer(withTimeInterval: Double(effect.parameters.duration) / 1000.0, repeats: effect.parameters.repeat) { [weak self] _ in
            self?.applyEffect(effect)
        }
        effectTimers[effect.id] = timer
    }
    
    private func stopEffectTimer(_ effect: Effect) {
        effectTimers[effect.id]?.invalidate()
        effectTimers.removeValue(forKey: effect.id)
    }
    
    private func applyEffect(_ effect: Effect) {
        // Implementation for applying the effect to devices
        // This would involve sending commands to the Yeelight devices
        // based on the effect parameters
    }
}

extension UnifiedEffectManager: EffectManaging {
    public var effectUpdates: AnyPublisher<EffectUpdate, Never> {
        effectSubject.eraseToAnyPublisher()
    }
    
    public func createEffect(name: String, type: EffectType, parameters: EffectParameters) async -> Effect {
        let effect = Effect(name: name, type: type, parameters: parameters)
        effects[effect.id] = effect
        effectSubject.send(.created(effect))
        return effect
    }
    
    public func getEffect(withId id: String) async -> Effect? {
        effects[id]
    }
    
    public func getAllEffects() async -> [Effect] {
        Array(effects.values)
    }
    
    public func updateEffect(_ effect: Effect) async -> Effect {
        effects[effect.id] = effect
        effectSubject.send(.updated(effect))
        return effect
    }
    
    public func deleteEffect(_ effect: Effect) async {
        if activeEffects.contains(effect.id) {
            await stopEffect(effect)
        }
        effects.removeValue(forKey: effect.id)
        effectSubject.send(.deleted(effect.id))
    }
    
    public func startEffect(_ effect: Effect) async {
        guard !activeEffects.contains(effect.id) else { return }
        
        activeEffects.insert(effect.id)
        startEffectTimer(effect)
        effectSubject.send(.started(effect))
    }
    
    public func stopEffect(_ effect: Effect) async {
        guard activeEffects.contains(effect.id) else { return }
        
        activeEffects.remove(effect.id)
        stopEffectTimer(effect)
        effectSubject.send(.stopped(effect))
    }
    
    public func stopAllEffects() async {
        let activeEffectsCopy = activeEffects
        for effectId in activeEffectsCopy {
            if let effect = effects[effectId] {
                await stopEffect(effect)
            }
        }
        effectSubject.send(.allStopped)
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