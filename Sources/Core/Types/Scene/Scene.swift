import Foundation

public struct Scene: Codable, Identifiable, Equatable {
    public let id: String
    public var name: String
    public var deviceStates: [String: DeviceState]
    public var isActive: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(id: String = UUID().uuidString,
                name: String,
                deviceStates: [String: DeviceState],
                isActive: Bool = false,
                createdAt: Date = Date(),
                updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.deviceStates = deviceStates
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
} 