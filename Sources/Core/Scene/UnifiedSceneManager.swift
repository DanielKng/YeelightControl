import Foundation
import Combine

// MARK: - Scene Managing Protocol
protocol SceneManaging {
    var scenes: [Scene] { get }
    var sceneUpdates: AnyPublisher<SceneUpdate, Never> { get }
    
    func getScene(byId id: String) -> Scene?
    func getAllScenes() -> [Scene]
    func createScene(_ scene: Scene) async throws
    func updateScene(_ scene: Scene) async throws
    func deleteScene(_ scene: Scene) async throws
    func applyScene(_ scene: Scene, to devices: [String]) async throws
}

// MARK: - Scene Model
struct Scene: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var icon: String
    var deviceStates: [String: DeviceState]
    var isPreset: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        icon: String = "lightbulb",
        deviceStates: [String: DeviceState] = [:],
        isPreset: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.deviceStates = deviceStates
        self.isPreset = isPreset
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    static let presets: [Scene] = [
        Scene(name: "Bright", icon: "sun.max", isPreset: true),
        Scene(name: "TV", icon: "tv", isPreset: true),
        Scene(name: "Reading", icon: "book", isPreset: true),
        Scene(name: "Night", icon: "moon", isPreset: true)
    ]
}

// MARK: - Scene Update Type
enum SceneUpdate {
    case created(Scene)
    case updated(Scene)
    case deleted(String)
    case applied(Scene, [String])
}

// MARK: - Scene Manager Implementation
final class UnifiedSceneManager: SceneManaging, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var scenes: [Scene] = []
    
    // MARK: - Publishers
    private let sceneSubject = PassthroughSubject<SceneUpdate, Never>()
    var sceneUpdates: AnyPublisher<SceneUpdate, Never> {
        sceneSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let services: ServiceContainer
    private let queue = DispatchQueue(label: "de.knng.app.yeelightcontrol.scene", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(services: ServiceContainer = .shared) {
        self.services = services
        loadScenes()
        setupObservers()
    }
    
    // MARK: - Public Methods
    func getScene(byId id: String) -> Scene? {
        queue.sync {
            scenes.first { $0.id == id }
        }
    }
    
    func getAllScenes() -> [Scene] {
        queue.sync {
            scenes
        }
    }
    
    func createScene(_ scene: Scene) async throws {
        try await queue.run {
            // Validate scene
            guard !scenes.contains(where: { $0.id == scene.id }) else {
                throw SceneError.alreadyExists
            }
            
            // Add scene
            scenes.append(scene)
            sceneSubject.send(.created(scene))
            
            // Save scenes
            try await saveScenes()
            
            services.logger.info("Created scene: \(scene.name)", category: .scene)
        }
    }
    
    func updateScene(_ scene: Scene) async throws {
        try await queue.run {
            guard let index = scenes.firstIndex(where: { $0.id == scene.id }) else {
                throw SceneError.notFound
            }
            
            // Update scene
            scenes[index] = scene
            sceneSubject.send(.updated(scene))
            
            // Save scenes
            try await saveScenes()
            
            services.logger.info("Updated scene: \(scene.name)", category: .scene)
        }
    }
    
    func deleteScene(_ scene: Scene) async throws {
        try await queue.run {
            // Validate scene
            guard !scene.isPreset else {
                throw SceneError.cannotDeletePreset
            }
            
            // Remove scene
            scenes.removeAll { $0.id == scene.id }
            sceneSubject.send(.deleted(scene.id))
            
            // Save scenes
            try await saveScenes()
            
            services.logger.info("Deleted scene: \(scene.name)", category: .scene)
        }
    }
    
    func applyScene(_ scene: Scene, to deviceIds: [String]) async throws {
        try await queue.run {
            // Validate devices
            let devices = deviceIds.compactMap { services.deviceManager.getDevice(byId: $0) }
            guard devices.count == deviceIds.count else {
                throw SceneError.deviceNotFound
            }
            
            // Apply scene to each device
            for deviceId in deviceIds {
                if let state = scene.deviceStates[deviceId] {
                    try await services.stateManager.setState(state, for: deviceId)
                } else {
                    // Use default state if not specified
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
            
            sceneSubject.send(.applied(scene, deviceIds))
            services.logger.info("Applied scene \(scene.name) to \(deviceIds.count) devices", category: .scene)
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
    
    private func loadScenes() {
        Task {
            do {
                var loadedScenes: [Scene] = try await services.storage.load(forKey: .scenes)
                
                // Add presets if not present
                for preset in Scene.presets {
                    if !loadedScenes.contains(where: { $0.id == preset.id }) {
                        loadedScenes.append(preset)
                    }
                }
                
                queue.async { [weak self] in
                    self?.scenes = loadedScenes
                }
            } catch {
                services.logger.error("Failed to load scenes: \(error.localizedDescription)", category: .scene)
                
                // Load presets as fallback
                queue.async { [weak self] in
                    self?.scenes = Scene.presets
                }
            }
        }
    }
    
    private func saveScenes() async throws {
        // Only save non-preset scenes
        let customScenes = scenes.filter { !$0.isPreset }
        try await services.storage.save(customScenes, forKey: .scenes)
    }
    
    private func handleDeviceRemoved(_ deviceId: String) {
        Task {
            do {
                // Remove device from all scenes
                for var scene in scenes where !scene.isPreset {
                    if scene.deviceStates[deviceId] != nil {
                        scene.deviceStates.removeValue(forKey: deviceId)
                        try await updateScene(scene)
                    }
                }
            } catch {
                services.logger.error("Failed to handle device removal: \(error.localizedDescription)", category: .scene)
            }
        }
    }
}

// MARK: - Scene Errors
enum SceneError: LocalizedError {
    case notFound
    case alreadyExists
    case deviceNotFound
    case cannotDeletePreset
    case invalidState
    case applicationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Scene not found"
        case .alreadyExists:
            return "Scene already exists"
        case .deviceNotFound:
            return "One or more devices not found"
        case .cannotDeletePreset:
            return "Cannot delete preset scene"
        case .invalidState:
            return "Invalid scene state"
        case .applicationFailed(let reason):
            return "Failed to apply scene: \(reason)"
        }
    }
} 