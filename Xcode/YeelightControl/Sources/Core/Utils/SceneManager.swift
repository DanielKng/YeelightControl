import Foundation
import Combine

class SceneManager: ObservableObject {
    static let shared = SceneManager()
    
    @Published private(set) var scenes: [ScenePreset] = []
    @Published private(set) var favoriteScenes: Set<UUID> = []
    
    private let storage = DeviceStorage.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadScenes()
        setupObservers()
    }
    
    private func setupObservers() {
        // Monitor for scene changes
        NotificationCenter.default.publisher(for: .sceneDidChange)
            .sink { [weak self] _ in
                self?.loadScenes()
            }
            .store(in: &cancellables)
    }
    
    func loadScenes() {
        // Load built-in presets
        var allScenes = ScenePreset.presets
        
        // Load mood scenes
        allScenes.append(contentsOf: ScenePreset.moods)
        
        // Load dynamic scenes
        allScenes.append(contentsOf: ScenePreset.dynamic)
        
        // Load strip effects
        allScenes.append(contentsOf: ScenePreset.stripEffects)
        
        // Load custom scenes
        allScenes.append(contentsOf: storage.loadSavedScenes())
        
        // Update scenes
        scenes = allScenes
        
        // Load favorites
        if let data = UserDefaults.standard.data(forKey: "favoriteScenes"),
           let favorites = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            favoriteScenes = favorites
        }
    }
    
    func saveScene(_ scene: ScenePreset) {
        storage.saveCustomScene(
            name: scene.name,
            scene: scene.scene,
            devices: []  // Device selection will be handled at runtime
        )
        NotificationCenter.default.post(name: .sceneDidChange, object: nil)
    }
    
    func deleteScene(_ scene: ScenePreset) {
        storage.deleteScene(scene.id)
        favoriteScenes.remove(scene.id)
        saveFavorites()
        NotificationCenter.default.post(name: .sceneDidChange, object: nil)
    }
    
    func toggleFavorite(_ scene: ScenePreset) {
        if favoriteScenes.contains(scene.id) {
            favoriteScenes.remove(scene.id)
        } else {
            favoriteScenes.insert(scene.id)
        }
        saveFavorites()
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favoriteScenes) {
            UserDefaults.standard.set(data, forKey: "favoriteScenes")
        }
    }
    
    func getFavoriteScenes() -> [ScenePreset] {
        return scenes.filter { favoriteScenes.contains($0.id) }
    }
    
    func getScenesByCategory(_ category: String) -> [ScenePreset] {
        return scenes.filter { $0.tags.contains(category.lowercased()) }
    }
    
    func searchScenes(_ query: String) -> [ScenePreset] {
        guard !query.isEmpty else { return scenes }
        
        return scenes.filter { scene in
            scene.name.localizedCaseInsensitiveContains(query) ||
            scene.description.localizedCaseInsensitiveContains(query) ||
            scene.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let sceneDidChange = Notification.Name("sceneDidChange")
} 