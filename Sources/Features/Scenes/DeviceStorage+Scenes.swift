extension DeviceStorage {
    private let scenesKey = "saved_scenes"
    private let automationsKey = "saved_automations"
    
    struct SavedScene: Codable {
        let id: UUID
        let name: String
        let icon: String
        let scene: YeelightManager.Scene
        let devices: [String] // Device IPs
        var isFavorite: Bool
    }
    
    func saveCustomScene(name: String, scene: YeelightManager.Scene, devices: [String]) {
        var scenes = loadSavedScenes()
        let savedScene = SavedScene(
            id: UUID(),
            name: name,
            icon: iconForScene(scene),
            scene: scene,
            devices: devices,
            isFavorite: false
        )
        scenes.append(savedScene)
        saveScenesArray(scenes)
    }
    
    private func iconForScene(_ scene: YeelightManager.Scene) -> String {
        switch scene {
        case .color: return "paintpalette.fill"
        case .colorTemperature: return "sun.max.fill"
        case .colorFlow: return "waveform.path.ecg"
        case .multiLight: return "lightbulb.2.fill"
        default: return "lightbulb.fill"
        }
    }
    
    func loadSavedScenes() -> [SavedScene] {
        guard let data = defaults.data(forKey: scenesKey),
              let scenes = try? JSONDecoder().decode([SavedScene].self, from: data)
        else {
            return []
        }
        return scenes
    }
    
    private func saveScenesArray(_ scenes: [SavedScene]) {
        if let encoded = try? JSONEncoder().encode(scenes) {
            defaults.set(encoded, forKey: scenesKey)
        }
    }
    
    func saveAutomation(_ automation: Automation) {
        var automations = loadAutomations()
        automations.append(automation)
        if let encoded = try? JSONEncoder().encode(automations) {
            defaults.set(encoded, forKey: automationsKey)
        }
    }
    
    func loadAutomations() -> [Automation] {
        guard let data = defaults.data(forKey: automationsKey),
              let automations = try? JSONDecoder().decode([Automation].self, from: data)
        else {
            return []
        }
        return automations
    }
} 