import SwiftUI

struct ScenePreset: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let scene: YeelightManager.Scene
    let description: String
    let tags: [String]
    var isFavorite: Bool
    let isCustom: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        scene: YeelightManager.Scene,
        description: String = "",
        tags: [String] = [],
        isFavorite: Bool = false,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.scene = scene
        self.description = description
        self.tags = tags
        self.isFavorite = isFavorite
        self.isCustom = isCustom
    }
    
    // Preset scenes
    static let presets: [ScenePreset] = [
        ScenePreset(
            name: "Movie Night",
            icon: "film.fill",
            scene: .colorTemperature(temperature: 2700, brightness: 50),
            description: "Warm lighting perfect for movie watching",
            tags: ["entertainment", "relaxation"]
        ),
        ScenePreset(
            name: "Reading",
            icon: "book.fill",
            scene: .colorTemperature(temperature: 4000, brightness: 80),
            description: "Bright, neutral light for reading",
            tags: ["productivity", "focus"]
        ),
        ScenePreset(
            name: "Party Mode",
            icon: "party.popper.fill",
            scene: .colorFlow(params: .partyMode),
            description: "Dynamic colors for parties",
            tags: ["entertainment", "dynamic"]
        ),
        ScenePreset(
            name: "Night Light",
            icon: "moon.fill",
            scene: .colorTemperature(temperature: 2000, brightness: 5),
            description: "Dim, warm light for nighttime",
            tags: ["night", "relaxation"]
        )
    ]
    
    // Mood scenes
    static let moods: [ScenePreset] = [
        ScenePreset(
            name: "Purple Dream",
            icon: "cloud.moon.fill",
            scene: .color(red: 128, green: 0, blue: 128, brightness: 80),
            description: "Calming purple ambiance",
            tags: ["mood", "relaxation"]
        ),
        ScenePreset(
            name: "Ocean Breeze",
            icon: "water.waves",
            scene: .color(red: 0, green: 105, blue: 148, brightness: 70),
            description: "Cool, oceanic atmosphere",
            tags: ["mood", "relaxation"]
        )
    ]
    
    // Dynamic scenes
    static let dynamic: [ScenePreset] = [
        ScenePreset(
            name: "Candlelight",
            icon: "flame.fill",
            scene: .colorFlow(params: .candlelight),
            description: "Flickering candlelight effect",
            tags: ["dynamic", "relaxation"]
        ),
        ScenePreset(
            name: "Aurora",
            icon: "sparkles",
            scene: .colorFlow(params: .aurora),
            description: "Northern lights effect",
            tags: ["dynamic", "entertainment"]
        )
    ]
    
    // Strip effects
    static let stripEffects: [ScenePreset] = [
        ScenePreset(
            name: "Rainbow Wave",
            icon: "rainbow",
            scene: .stripEffect(.rainbowWave),
            description: "Moving rainbow colors",
            tags: ["strip", "dynamic"]
        ),
        ScenePreset(
            name: "Color Chase",
            icon: "bolt.horizontal",
            scene: .stripEffect(.chaseLights),
            description: "Chasing light effect",
            tags: ["strip", "dynamic"]
        )
    ]
    
    var previewColor: Color {
        switch scene {
        case .color(let red, let green, let blue, _):
            return Color(red: Double(red)/255, green: Double(green)/255, blue: Double(blue)/255)
        case .colorTemperature(let temp, _):
            return temp > 4000 ? .blue : .orange
        case .colorFlow:
            return .purple
        case .multiLight:
            return .green
        case .stripEffect:
            return .blue
        default:
            return .gray
        }
    }
} 