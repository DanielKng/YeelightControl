import Foundation
import Combine

// MARK: - Effect Types
public struct Core_Effect: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let type: Core_EffectType
    public let parameters: Core_EffectParameters
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: Core_EffectType,
        parameters: Core_EffectParameters
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.parameters = parameters
    }
}

public enum Core_EffectType: String, Codable, CaseIterable {
    case pulse
    case flow
    case transition
    case strobe
    case custom
}

public struct Core_EffectParameters: Codable, Hashable {
    public let duration: TimeInterval
    public let colors: [Core_Color]
    public let brightness: [Int]
    public let speed: Int
    public let repeat: Bool
    public let customData: [String: String]?
    
    public init(
        duration: TimeInterval,
        colors: [Core_Color],
        brightness: [Int],
        speed: Int,
        repeat: Bool = false,
        customData: [String: String]? = nil
    ) {
        self.duration = duration
        self.colors = colors
        self.brightness = brightness
        self.speed = speed
        self.repeat = `repeat`
        self.customData = customData
    }
}

public struct Core_EffectUpdate: Codable, Hashable {
    public let effectId: String
    public let name: String?
    public let parameters: Core_EffectParameters?
    
    public init(
        effectId: String,
        name: String? = nil,
        parameters: Core_EffectParameters? = nil
    ) {
        self.effectId = effectId
        self.name = name
        self.parameters = parameters
    }
}

// MARK: - Effect Protocols
@preconcurrency public protocol Core_EffectManaging: Core_BaseService {
    /// Apply an effect to a device
    func applyEffect(_ effect: Core_Effect, to device: Core_Device) async throws
    
    /// Get available effects
    func getAvailableEffects() -> [Core_Effect]
} 