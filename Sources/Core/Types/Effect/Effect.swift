import Foundation
import SwiftUI

// MARK: - Effect Model

public struct Effect: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public var name: String
    public var type: EffectType
    public var parameters: EffectParameters
    public var isActive: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: EffectType,
        parameters: EffectParameters,
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.parameters = parameters
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Effect, rhs: Effect) -> Bool {
        lhs.id == rhs.id
    }
    
    public static let presets: [Effect] = [
        Effect(
            name: "Pulse",
            type: .pulse,
            parameters: .init(
                duration: 1000,
                colors: [],
                brightness: 50,
                temperature: 4000,
                speed: 50,
                shouldRepeat: true
            ),
            isActive: true
        ),
        Effect(
            name: "Rainbow",
            type: .colorFlow,
            parameters: .init(
                duration: 2000,
                colors: [
                    Color.red,
                    Color.orange,
                    Color.yellow,
                    Color.green,
                    Color.blue,
                    Color.purple,
                    Color.init(red: 148/255, green: 0, blue: 211/255)
                ],
                brightness: 80,
                temperature: 4000,
                speed: 50,
                shouldRepeat: true
            ),
            isActive: true
        ),
        Effect(
            name: "Strobe",
            type: .strobe,
            parameters: .init(
                duration: 100,
                colors: [],
                brightness: 50,
                temperature: 4000,
                speed: 50,
                shouldRepeat: true
            ),
            isActive: true
        )
    ]
} 