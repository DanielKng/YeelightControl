import Foundation
import SwiftUI

// MARK: - Effect Parameters

public struct EffectParameters: Codable, Hashable {
    public var duration: TimeInterval
    public var colors: [Color]
    public var brightness: Int
    public var temperature: Int
    public var speed: Int
    public var shouldRepeat: Bool
    public var customProperties: [String: String]
    
    public init(
        duration: TimeInterval = 30,
        colors: [Color] = [.red, .green, .blue],
        brightness: Int = 100,
        temperature: Int = 4000,
        speed: Int = 50,
        shouldRepeat: Bool = true,
        customProperties: [String: String] = [:]
    ) {
        self.duration = duration
        self.colors = colors
        self.brightness = brightness
        self.temperature = temperature
        self.speed = speed
        self.shouldRepeat = shouldRepeat
        self.customProperties = customProperties
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case duration
        case colors
        case brightness
        case temperature
        case speed
        case shouldRepeat = "repeat"
        case customProperties
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        brightness = try container.decode(Int.self, forKey: .brightness)
        temperature = try container.decode(Int.self, forKey: .temperature)
        speed = try container.decode(Int.self, forKey: .speed)
        shouldRepeat = try container.decode(Bool.self, forKey: .shouldRepeat)
        customProperties = try container.decode([String: String].self, forKey: .customProperties)
        
        // Decode colors from hex strings
        let colorStrings = try container.decode([String].self, forKey: .colors)
        colors = colorStrings.compactMap { hexString in
            Color(hex: hexString)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        try container.encode(brightness, forKey: .brightness)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(speed, forKey: .speed)
        try container.encode(shouldRepeat, forKey: .shouldRepeat)
        try container.encode(customProperties, forKey: .customProperties)
        
        // Encode colors as hex strings
        let colorStrings = colors.map { $0.toHex() ?? "#000000" }
        try container.encode(colorStrings, forKey: .colors)
    }
}

// MARK: - Color Extensions

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0,
            opacity: 1.0
        )
    }
    
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let hexString = String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        return hexString
    }
} 