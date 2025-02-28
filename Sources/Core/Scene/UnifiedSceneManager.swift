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
                throw SceneError.invalidDevices
            }
            
            // Add scene
            scenes.append(scene)
            sceneSubject.send(.init(scene: scene, type: .created))
            
            // Save scenes
            try await saveScenes()
            
            services.logger.info("Created scene: \(scene.name)", category: .scene)
        }
    }
    
    func updateScene(_ scene: Scene) async throws {
        try await queue.run {
            guard let index = scenes.firstIndex(where: { $0.id == scene.id }) else {
                throw SceneError.unknown
            }
            
            // Update scene
            scenes[index] = scene
            sceneSubject.send(.init(scene: scene, type: .updated))
            
            // Save scenes
            try await saveScenes()
            
            services.logger.info("Updated scene: \(scene.name)", category: .scene)
        }
    }
    
    func deleteScene(_ scene: Scene) async throws {
        try await queue.run {
            // Remove scene
            scenes.removeAll { $0.id == scene.id }
            sceneSubject.send(.init(scene: scene, type: .deleted))
            
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
                throw SceneError.activationFailed
            }
            
            // Apply scene to each device
            for deviceId in deviceIds {
                if let state = scene.deviceStates[deviceId] {
                    try await services.deviceManager.updateDeviceState(devices.first { $0.id == deviceId }!, newState: state)
                } else {
                    // Use default state if not specified
                    let defaultState = DeviceState(
                        power: true,
                        brightness: 100
                    )
                    try await services.deviceManager.updateDeviceState(devices.first { $0.id == deviceId }!, newState: defaultState)
                }
            }
            
            sceneSubject.send(.init(scene: scene, type: .activated))
            services.logger.info("Applied scene \(scene.name) to \(deviceIds.count) devices", category: .scene)
        }
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Add any necessary observers here
    }
    
    private func loadScenes() {
        do {
            if let data = try services.storageManager.load(Data.self, forKey: "scenes") {
                scenes = try JSONDecoder().decode([Scene].self, from: data)
            }
        } catch {
            services.logger.error("Failed to load scenes: \(error)")
        }
    }
    
    private func saveScenes() async throws {
        do {
            let data = try JSONEncoder().encode(scenes)
            try services.storageManager.save(data, forKey: "scenes")
        } catch {
            services.logger.error("Failed to save scenes: \(error)")
            throw error
        }
    }
} 