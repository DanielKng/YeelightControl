import Foundation

public struct Effect: Identifiable, Codable, Hashable, Equatable {
    public let id: String
    public var name: String
    public var icon: String
    public var type: EffectType
    public var parameters: EffectParameters
    public var isPreset: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        icon: String = "sparkles",
        type: EffectType,
        parameters: EffectParameters,
        isPreset: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.type = type
        self.parameters = parameters
        self.isPreset = isPreset
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public static let presets: [Effect] = [
        Effect(
            name: "Pulse",
            type: .pulse,
            parameters: .init(
                duration: 1000,
                brightness: [20, 100],
                colorTemperature: nil,
                colors: nil,
                repeat: true
            ),
            isPreset: true
        ),
        Effect(
            name: "Rainbow",
            type: .colorFlow,
            parameters: .init(
                duration: 2000,
                brightness: [80],
                colorTemperature: nil,
                colors: [
                    [255, 0, 0],
                    [255, 127, 0],
                    [255, 255, 0],
                    [0, 255, 0],
                    [0, 0, 255],
                    [75, 0, 130],
                    [148, 0, 211]
                ],
                repeat: true
            ),
            isPreset: true
        ),
        Effect(
            name: "Strobe",
            type: .strobe,
            parameters: .init(
                duration: 100,
                brightness: [0, 100],
                colorTemperature: nil,
                colors: nil,
                repeat: true
            ),
            isPreset: true
        )
    ]
} 