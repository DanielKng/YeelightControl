import Foundation

public struct SceneUpdate: Codable, Equatable {
    public let scene: Scene
    public let type: UpdateType
    public let timestamp: Date
    
    public enum UpdateType: String, Codable {
        case created
        case updated
        case deleted
        case activated
        case deactivated
    }
    
    public init(scene: Scene, type: UpdateType, timestamp: Date = Date()) {
        self.scene = scene
        self.type = type
        self.timestamp = timestamp
    }
} 