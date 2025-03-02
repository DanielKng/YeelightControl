import Foundation
import SwiftUI

// MARK: - Effect Type

// Make Effect conform to Core_Effect
public typealias Core_Effect = Effect

public struct Effect: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public var type: EffectType
    public var parameters: EffectParameters
    public var isActive: Bool
    public let createdAt: Date
    public var updatedAt: Date
    public let isBuiltIn: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: EffectType,
        parameters: EffectParameters,
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.parameters = parameters
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isBuiltIn = isBuiltIn
    }
    
    // Initialize from Core_EffectType and Core_EffectParameters
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: Core_EffectType,
        parameters: Core_EffectParameters,
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = EffectType.from(coreType: type)
        self.parameters = EffectParameters.from(coreParameters: parameters)
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isBuiltIn = isBuiltIn
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Effect, rhs: Effect) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Preset Effects
    
    public static let pulse = Effect(
        name: "Pulse",
        type: .pulse,
        parameters: EffectParameters(
            duration: 10,
            colors: [.red, .blue],
            brightness: 80,
            speed: 70,
            shouldRepeat: true
        ),
        isBuiltIn: true
    )
    
    public static let rainbow = Effect(
        name: "Rainbow",
        type: .colorFlow,
        parameters: EffectParameters(
            duration: 30,
            colors: [.red, .orange, .yellow, .green, .blue, .purple],
            brightness: 100,
            speed: 50,
            shouldRepeat: true
        ),
        isBuiltIn: true
    )
    
    public static let strobe = Effect(
        name: "Strobe",
        type: .strobe,
        parameters: EffectParameters(
            duration: 5,
            colors: [.white],
            brightness: 100,
            speed: 90,
            shouldRepeat: true
        ),
        isBuiltIn: true
    )
    
    public static let candle = Effect(
        name: "Candle",
        type: .candle,
        parameters: EffectParameters(
            duration: 60,
            colors: [Color(hex: "#FF9800") ?? .orange],
            brightness: 60,
            temperature: 2700,
            speed: 30,
            shouldRepeat: true
        ),
        isBuiltIn: true
    )
    
    public static let nightLight = Effect(
        name: "Night Light",
        type: .nightLight,
        parameters: EffectParameters(
            duration: 480,
            colors: [Color(hex: "#FFF8E1") ?? .white],
            brightness: 20,
            temperature: 2200,
            speed: 10,
            shouldRepeat: false
        ),
        isBuiltIn: true
    )
}

// MARK: - Type Conversion Extensions

extension Effect {
    // Convert between Core_EffectType and EffectType
    public var coreType: Core_EffectType {
        switch type {
        case .colorFlow: return .flow
        case .pulse: return .pulse
        case .strobe: return .strobe
        case .candle: return .custom
        case .music: return .custom
        case .sunrise: return .custom
        case .sunset: return .custom
        case .nightLight: return .custom
        case .movie: return .custom
        case .gaming: return .custom
        case .reading: return .custom
        case .party: return .custom
        case .custom: return .custom
        }
    }
    
    // Convert between Core_EffectParameters and EffectParameters
    public var coreParameters: Core_EffectParameters {
        let color = parameters.colors.first
        return Core_EffectParameters(
            color: color,
            brightness: parameters.brightness,
            temperature: parameters.temperature,
            duration: parameters.duration,
            speed: parameters.speed,
            custom: parameters.customProperties
        )
    }
}

// Add extension to EffectType for conversion from Core_EffectType
extension EffectType {
    public static func from(coreType: Core_EffectType) -> EffectType {
        switch coreType {
        case .flow: return .colorFlow
        case .pulse: return .pulse
        case .strobe: return .strobe
        case .color, .brightness, .temperature, .custom: return .custom
        }
    }
}

// Add extension to EffectParameters for conversion from Core_EffectParameters
extension EffectParameters {
    public static func from(coreParameters: Core_EffectParameters) -> EffectParameters {
        var colors: [Color] = []
        if let color = coreParameters.color {
            colors.append(color)
        }
        
        return EffectParameters(
            duration: coreParameters.duration ?? 0,
            colors: colors,
            brightness: coreParameters.brightness ?? 100,
            temperature: coreParameters.temperature ?? 4000,
            speed: coreParameters.speed ?? 50,
            shouldRepeat: false,
            customProperties: coreParameters.custom ?? [:]
        )
    }
} 