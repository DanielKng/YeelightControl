import SwiftUI
import Foundation

// MARK: - Effect Type

public enum EffectType: String, Codable, CaseIterable {
    case colorFlow
    case pulse
    case strobe
    case candle
    case music
    case sunrise
    case sunset
    case nightLight
    case movie
    case gaming
    case reading
    case party
    case custom
    
    public var displayName: String {
        switch self {
        case .colorFlow: return "Color Flow"
        case .pulse: return "Pulse"
        case .strobe: return "Strobe"
        case .candle: return "Candle"
        case .music: return "Music Sync"
        case .sunrise: return "Sunrise"
        case .sunset: return "Sunset"
        case .nightLight: return "Night Light"
        case .movie: return "Movie Mode"
        case .gaming: return "Gaming Mode"
        case .reading: return "Reading Mode"
        case .party: return "Party Mode"
        case .custom: return "Custom"
        }
    }
    
    public var description: String {
        switch self {
        case .colorFlow: return "Smooth transition between colors"
        case .pulse: return "Pulsating light effect"
        case .strobe: return "Rapid flashing effect"
        case .candle: return "Flickering candle simulation"
        case .music: return "Synchronize with music"
        case .sunrise: return "Gradual brightening like sunrise"
        case .sunset: return "Gradual dimming like sunset"
        case .nightLight: return "Soft, dim light for nighttime"
        case .movie: return "Optimized for movie watching"
        case .gaming: return "Dynamic lighting for gaming"
        case .reading: return "Comfortable light for reading"
        case .party: return "Colorful party lighting"
        case .custom: return "Custom effect"
        }
    }
    
    public static func == (lhs: EffectType, rhs: EffectType) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
} 