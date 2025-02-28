import Foundation

public enum EffectType: String, Codable, Hashable, Equatable {
    case smooth
    case sudden
    case strobe
    case pulse
    case colorFlow
    case colorCycle
    case breathe
    case flash
    case sunrise
    case sunset
    case custom
} 