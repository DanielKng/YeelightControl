import Foundation

struct SharedScene: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let scene: YeelightManager.Scene
    let createdBy: String
    let description: String
    let tags: [String]
    let version: Int
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        scene: YeelightManager.Scene,
        createdBy: String,
        description: String,
        tags: [String],
        version: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.scene = scene
        self.createdBy = createdBy
        self.description = description
        self.tags = tags
        self.version = version
        self.createdAt = createdAt
    }
    
    // Convert to URL for sharing
    var shareURL: URL? {
        guard let data = try? JSONEncoder().encode(self),
              let base64 = String(data: data, encoding: .utf8)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        
        return URL(string: "yeelight://scene/import/\(base64)")
    }
    
    // Create from shared URL
    static func from(url: URL) -> SharedScene? {
        guard url.scheme == "yeelight",
              url.host == "scene",
              url.path.hasPrefix("/import/"),
              let base64 = url.path.replacingOccurrences(of: "/import/", with: "")
                .removingPercentEncoding,
              let data = Data(base64Encoded: base64),
              let scene = try? JSONDecoder().decode(SharedScene.self, from: data)
        else { return nil }
        
        return scene
    }
    
    // Convert to ScenePreset
    func toPreset() -> ScenePreset {
        ScenePreset(
            name: name,
            icon: icon,
            scene: scene,
            description: description,
            tags: tags,
            isCustom: true
        )
    }
    
    // Sample scenes for testing
    static let samples: [SharedScene] = [
        SharedScene(
            name: "Cozy Evening",
            icon: "sunset.fill",
            scene: .color(red: 255, green: 147, blue: 41, brightness: 50),
            createdBy: "Sarah",
            description: "Perfect for relaxing evenings",
            tags: ["mood", "relaxation"]
        ),
        SharedScene(
            name: "Focus Time",
            icon: "lightbulb.fill",
            scene: .colorTemperature(temperature: 5500, brightness: 100),
            createdBy: "Mike",
            description: "Bright, cool light for productivity",
            tags: ["productivity", "focus"]
        )
    ]
} 