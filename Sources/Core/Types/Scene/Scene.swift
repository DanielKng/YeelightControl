import SwiftUI
import Foundation

// MARK: - Scene Model

public struct Scene: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var deviceIds: [String]
    public var effectId: String?
    public var isActive: Bool
    public var schedule: SceneSchedule?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        deviceIds: [String],
        effectId: String? = nil,
        isActive: Bool = false,
        schedule: SceneSchedule? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.deviceIds = deviceIds
        self.effectId = effectId
        self.isActive = isActive
        self.schedule = schedule
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Scene, rhs: Scene) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Scene Schedule

public struct SceneSchedule: Codable, Equatable, Hashable {
    public enum ScheduleType: String, Codable {
        case daily
        case weekly
        case once
        case sunset
        case sunrise
        case location
    }
    
    public let id: String
    public let type: ScheduleType
    public let time: Date?
    public let days: [Int]?
    public let isEnabled: Bool
    
    public init(
        id: String = UUID().uuidString,
        type: ScheduleType,
        time: Date? = nil,
        days: [Int]? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.type = type
        self.time = time
        self.days = days
        self.isEnabled = isEnabled
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: SceneSchedule, rhs: SceneSchedule) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Scene Update

public struct Core_SceneUpdate {
    public let scene: Scene
    public let updateType: UpdateType
    
    public init(scene: Scene, updateType: UpdateType) {
        self.scene = scene
        self.updateType = updateType
    }
    
    public enum UpdateType {
        case added
        case updated
        case removed
        case activated
        case deactivated
        case scheduled
    }
}

public struct SceneDevice: Codable, Equatable {
    public let deviceId: String
    public let brightness: Int?
    public let colorTemperature: Int?
    public let color: SceneColor?
    
    public init(
        deviceId: String,
        brightness: Int? = nil,
        colorTemperature: Int? = nil,
        color: SceneColor? = nil
    ) {
        self.deviceId = deviceId
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.color = color
    }
}

public enum WeekDay: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    public var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

public struct SceneColor: Codable, Equatable {
    public let red: Int
    public let green: Int
    public let blue: Int
    
    public init(red: Int, green: Int, blue: Int) {
        self.red = min(max(red, 0), 255)
        self.green = min(max(green, 0), 255)
        self.blue = min(max(blue, 0), 255)
    }
} 