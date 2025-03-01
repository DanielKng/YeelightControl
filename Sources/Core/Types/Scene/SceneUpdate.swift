import Foundation

public struct SceneUpdate: Codable, Equatable {
    public let scene: Scene
    public let action: SceneAction
    public let timestamp: Date
    
    public init(
        scene: Scene,
        action: SceneAction,
        timestamp: Date = Date()
    ) {
        self.scene = scene
        self.action = action
        self.timestamp = timestamp
    }
}

public enum SceneAction: String, Codable {
    case created
    case updated
    case deleted
    case activated
    case deactivated
    case applied
} 