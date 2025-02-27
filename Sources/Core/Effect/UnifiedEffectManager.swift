import Foundation
import Combine

// MARK: - Effect Managing Protocol
protocol EffectManaging {
    var effects: [Effect] { get }
    var effectUpdates: AnyPublisher<EffectUpdate, Never> { get }
    
    func getEffect(byId id: String) -> Effect?
    func getAllEffects() -> [Effect]
    func createEffect(_ effect: Effect) async throws
    func updateEffect(_ effect: Effect) async throws
    func deleteEffect(_ effect: Effect) async throws
    func applyEffect(_ effect: Effect, to devices: [String]) async throws
    func stopEffect(on devices: [String]) async throws
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
}

// MARK: - Effect Manager Implementation
final class UnifiedEffectManager: EffectManaging, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var effects: [Effect] = []
    
    // MARK: - Publishers
    private let effectSubject = PassthroughSubject<EffectUpdate, Never>()
    var effectUpdates: AnyPublisher<EffectUpdate, Never> {
        effectSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let services: ServiceContainer
    private let queue = DispatchQueue(label: "de.knng.app.yeelightcontrol.effect", qos: .userInitiated)
    private var activeEffects: [String: Task<Void, Error>] = [:] // deviceId: task
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(services: ServiceContainer = .shared) {
        self.services = services
        loadEffects()
        setupObservers()
    }
    
    // MARK: - Public Methods
    func getEffect(byId id: String) -> Effect? {
        queue.sync {
            effects.first { $0.id == id }
        }
    }
    
    func getAllEffects() -> [Effect] {
        queue.sync {
            effects
        }
    }
    
    func createEffect(_ effect: Effect) async throws {
        try await queue.run {
            // Validate effect
            guard !effects.contains(where: { $0.id == effect.id }) else {
                throw EffectError.alreadyExists
            }
            
            // Add effect
            effects.append(effect)
            effectSubject.send(.created(effect))
            
            // Save effects
            try await saveEffects()
            
            services.logger.info("Created effect: \(effect.name)", category: .effect)
        }
    }
    
    func updateEffect(_ effect: Effect) async throws {
        try await queue.run {
            guard let index = effects.firstIndex(where: { $0.id == effect.id }) else {
                throw EffectError.notFound
            }
            
            // Update effect
            effects[index] = effect
            effectSubject.send(.updated(effect))
            
            // Save effects
            try await saveEffects()
            
            services.logger.info("Updated effect: \(effect.name)", category: .effect)
        }
    }
    
    func deleteEffect(_ effect: Effect) async throws {
        try await queue.run {
            // Validate effect
            guard !effect.isPreset else {
                throw EffectError.cannotDeletePreset
            }
            
            // Remove effect
            effects.removeAll { $0.id == effect.id }
            effectSubject.send(.deleted(effect.id))
            
            // Save effects
            try await saveEffects()
            
            services.logger.info("Deleted effect: \(effect.name)", category: .effect)
        }
    }
    
    func applyEffect(_ effect: Effect, to deviceIds: [String]) async throws {
        try await queue.run {
            // Validate devices
            let devices = deviceIds.compactMap { services.deviceManager.getDevice(byId: $0) }
            guard devices.count == deviceIds.count else {
                throw EffectError.deviceNotFound
            }
            
            // Stop any active effects on these devices
            try await stopEffect(on: deviceIds)
            
            // Apply effect to each device
            for deviceId in deviceIds {
                let task = Task {
                    repeat {
                        try await applyEffectCycle(effect, to: deviceId)
                    } while effect.parameters.repeat && !Task.isCancelled
                }
                activeEffects[deviceId] = task
            }
            
            effectSubject.send(.applied(effect, deviceIds))
            services.logger.info("Applied effect \(effect.name) to \(deviceIds.count) devices", category: .effect)
        }
    }
    
    func stopEffect(on deviceIds: [String]) async throws {
        try await queue.run {
            for deviceId in deviceIds {
                // Cancel active effect task
                activeEffects[deviceId]?.cancel()
                activeEffects.removeValue(forKey: deviceId)
                
                // Reset device state
                if let device = services.deviceManager.getDevice(byId: deviceId) {
                    let defaultState = DeviceState(
                        power: true,
                        brightness: 100,
                        colorTemperature: 4000,
                        lastUpdate: Date(),
                        isOnline: true
                    )
                    try await services.stateManager.setState(defaultState, for: deviceId)
                }
            }
            
            effectSubject.send(.stopped(deviceIds))
            services.logger.info("Stopped effects on \(deviceIds.count) devices", category: .effect)
        }
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Observe device removals
        services.deviceManager.deviceUpdates
            .sink { [weak self] update in
                if case .removed(let deviceId) = update {
                    self?.handleDeviceRemoved(deviceId)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadEffects() {
        Task {
            do {
                var loadedEffects: [Effect] = try await services.storage.load(forKey: .effects)
                
                // Add presets if not present
                for preset in Effect.presets {
                    if !loadedEffects.contains(where: { $0.id == preset.id }) {
                        loadedEffects.append(preset)
                    }
                }
                
                queue.async { [weak self] in
                    self?.effects = loadedEffects
                }
            } catch {
                services.logger.error("Failed to load effects: \(error.localizedDescription)", category: .effect)
                
                // Load presets as fallback
                queue.async { [weak self] in
                    self?.effects = Effect.presets
                }
            }
        }
    }
    
    private func saveEffects() async throws {
        // Only save non-preset effects
        let customEffects = effects.filter { !$0.isPreset }
        try await services.storage.save(customEffects, forKey: .effects)
    }
    
    private func handleDeviceRemoved(_ deviceId: String) {
        Task {
            try? await stopEffect(on: [deviceId])
        }
    }
    
    private func applyEffectCycle(_ effect: Effect, to deviceId: String) async throws {
        let params = effect.parameters
        
        switch effect.type {
        case .smooth, .sudden:
            // Simple transition
            let state = DeviceState(
                power: true,
                brightness: params.brightness[0],
                colorTemperature: params.colorTemperature?.first,
                color: params.colors?.first.map { DeviceState.Color(red: $0[0], green: $0[1], blue: $0[2]) },
                effect: effect.type == .smooth ? .smooth : .sudden,
                lastUpdate: Date(),
                isOnline: true
            )
            try await services.stateManager.setState(state, for: deviceId)
            
        case .strobe, .pulse:
            // Alternating states
            for brightness in params.brightness {
                let state = DeviceState(
                    power: true,
                    brightness: brightness,
                    colorTemperature: params.colorTemperature?.first,
                    lastUpdate: Date(),
                    isOnline: true
                )
                try await services.stateManager.setState(state, for: deviceId)
                try await Task.sleep(nanoseconds: UInt64(params.duration) * 1_000_000)
            }
            
        case .colorFlow:
            // Color sequence
            guard let colors = params.colors else { return }
            for color in colors {
                let state = DeviceState(
                    power: true,
                    brightness: params.brightness[0],
                    color: DeviceState.Color(red: color[0], green: color[1], blue: color[2]),
                    effect: .smooth,
                    lastUpdate: Date(),
                    isOnline: true
                )
                try await services.stateManager.setState(state, for: deviceId)
                try await Task.sleep(nanoseconds: UInt64(params.duration) * 1_000_000)
            }
        }
    }
}

// MARK: - Effect Errors
enum EffectError: LocalizedError {
    case notFound
    case alreadyExists
    case deviceNotFound
    case cannotDeletePreset
    case invalidParameters
    case applicationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Effect not found"
        case .alreadyExists:
            return "Effect already exists"
        case .deviceNotFound:
            return "One or more devices not found"
        case .cannotDeletePreset:
            return "Cannot delete preset effect"
        case .invalidParameters:
            return "Invalid effect parameters"
        case .applicationFailed(let reason):
            return "Failed to apply effect: \(reason)"
        }
    }
} 