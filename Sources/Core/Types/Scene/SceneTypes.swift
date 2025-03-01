import Foundation
import Combine

// MARK: - Scene Types
public struct Core_Scene: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let deviceIds: [String]
    public let states: [String: Core_DeviceState]
    public let schedule: Core_SceneSchedule?
    public let isActive: Bool
    public let lastActivated: Date?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        deviceIds: [String],
        states: [String: Core_DeviceState],
        schedule: Core_SceneSchedule? = nil,
        isActive: Bool = false,
        lastActivated: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.deviceIds = deviceIds
        self.states = states
        self.schedule = schedule
        self.isActive = isActive
        self.lastActivated = lastActivated
    }
}

public struct Core_SceneSchedule: Codable, Hashable {
    public let days: [Core_Weekday]
    public let startTime: Date
    public let endTime: Date?
    public let isRepeating: Bool
    
    public init(
        days: [Core_Weekday],
        startTime: Date,
        endTime: Date? = nil,
        isRepeating: Bool = false
    ) {
        self.days = days
        self.startTime = startTime
        self.endTime = endTime
        self.isRepeating = isRepeating
    }
}

public enum Core_Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

public struct Core_SceneUpdate: Codable, Hashable {
    public let sceneId: String
    public let name: String?
    public let deviceIds: [String]?
    public let states: [String: Core_DeviceState]?
    public let schedule: Core_SceneSchedule?
    
    public init(
        sceneId: String,
        name: String? = nil,
        deviceIds: [String]? = nil,
        states: [String: Core_DeviceState]? = nil,
        schedule: Core_SceneSchedule? = nil
    ) {
        self.sceneId = sceneId
        self.name = name
        self.deviceIds = deviceIds
        self.states = states
        self.schedule = schedule
    }
}

// MARK: - Scene Protocols
@preconcurrency public protocol Core_SceneManaging: Core_BaseService {
    /// The list of scenes
    var scenes: [Core_Scene] { get }
    
    /// Publisher for scene updates
    nonisolated var sceneUpdates: AnyPublisher<[Core_Scene], Never> { get }
    
    /// Activate a scene
    func activateScene(_ scene: Core_Scene) async throws
    
    /// Deactivate a scene
    func deactivateScene(_ scene: Core_Scene) async throws
    
    /// Create a scene
    func createScene(_ scene: Core_Scene) async throws
    
    /// Update a scene
    func updateScene(_ scene: Core_Scene) async throws
    
    /// Delete a scene
    func deleteScene(_ scene: Core_Scene) async throws
} 