import Foundation
import Combine
import SwiftUI

// MARK: - Effect Types
// Core_Effect is defined as a typealias in Effect.swift
// Core_EffectType is defined in EffectType.swift
// Core_EffectParameters is defined in EffectParameters.swift
// Core_EffectUpdate is defined in EffectUpdate.swift

// MARK: - Effect Protocols
// Core_EffectManaging protocol is defined in ServiceProtocols.swift

// MARK: - Effect Type

/// Represents the type of an effect
public enum Core_EffectType: String, Codable, CaseIterable {
    case color
    case brightness
    case temperature
    case flow
    case pulse
    case strobe
    case custom
}

// MARK: - Effect Parameters

/// Parameters for an effect
public struct Core_EffectParameters: Codable, Hashable {
    public var color: Color?
    public var brightness: Int?
    public var temperature: Int?
    public var duration: TimeInterval?
    public var speed: Int?
    public var custom: [String: String]?
    
    public init(
        color: Color? = nil,
        brightness: Int? = nil,
        temperature: Int? = nil,
        duration: TimeInterval? = nil,
        speed: Int? = nil,
        custom: [String: String]? = nil
    ) {
        self.color = color
        self.brightness = brightness
        self.temperature = temperature
        self.duration = duration
        self.speed = speed
        self.custom = custom
    }
    
    // Color extension for Codable
    private enum CodingKeys: String, CodingKey {
        case colorRed, colorGreen, colorBlue, colorOpacity
        case brightness, temperature, duration, speed, custom
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.colorRed) {
            let red = try container.decode(Double.self, forKey: .colorRed)
            let green = try container.decode(Double.self, forKey: .colorGreen)
            let blue = try container.decode(Double.self, forKey: .colorBlue)
            let opacity = try container.decode(Double.self, forKey: .colorOpacity)
            self.color = Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
        } else {
            self.color = nil
        }
        
        self.brightness = try container.decodeIfPresent(Int.self, forKey: .brightness)
        self.temperature = try container.decodeIfPresent(Int.self, forKey: .temperature)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        self.speed = try container.decodeIfPresent(Int.self, forKey: .speed)
        self.custom = try container.decodeIfPresent([String: String].self, forKey: .custom)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let color = self.color {
            // This is a simplification, as extracting RGB components from Color is not straightforward
            // In a real implementation, you would need a proper way to extract these values
            let components = color.cgColor?.components ?? [0, 0, 0, 1]
            try container.encode(Double(components[0]), forKey: .colorRed)
            try container.encode(Double(components[1]), forKey: .colorGreen)
            try container.encode(Double(components[2]), forKey: .colorBlue)
            try container.encode(Double(components[3]), forKey: .colorOpacity)
        }
        
        try container.encodeIfPresent(brightness, forKey: .brightness)
        try container.encodeIfPresent(temperature, forKey: .temperature)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(speed, forKey: .speed)
        try container.encodeIfPresent(custom, forKey: .custom)
    }
}

// MARK: - Effect Update

/// Represents an update to an effect
public struct Core_EffectUpdate {
    public let effect: Core_Effect
    public let timestamp: Date
    
    public init(effect: Core_Effect, timestamp: Date = Date()) {
        self.effect = effect
        self.timestamp = timestamp
    }
} 