import SwiftUI
import Foundation
import CoreLocation

// MARK: - Unified Device State

/// The main device state struct used throughout the app
public struct Core_DeviceState: Codable, Equatable, Hashable {
    public var power: Bool
    public var brightness: Int
    public var colorTemperature: Int
    public var color: Core_DeviceColor
    public var effect: Effect?
    public var isOnline: Bool
    public var lastSeen: Date
    public var mode: YeelightMode?
    
    public init(
        power: Bool = false,
        brightness: Int = 100,
        colorTemperature: Int = 4000,
        color: Core_DeviceColor = .white,
        effect: Effect? = nil,
        isOnline: Bool = false,
        lastSeen: Date = Date(),
        mode: YeelightMode? = .normal
    ) {
        self.power = power
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.color = color
        self.effect = effect
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.mode = mode
    }
    
    // Convert to UI DeviceState
    public var uiState: UI_DeviceState {
        UI_DeviceState(
            isOn: power,
            brightness: Double(brightness),
            colorTemperature: Double(colorTemperature),
            color: Color(red: Double(color.red) / 255.0, 
                         green: Double(color.green) / 255.0, 
                         blue: Double(color.blue) / 255.0),
            mode: mode?.rawValue ?? (effect != nil ? "effect" : "normal"),
            activeEffect: effect?.name
        )
    }
    
    // Convert from Core_YeelightDeviceState
    public static func from(coreState: Core_YeelightDeviceState) -> DeviceState {
        let mode: YeelightMode?
        switch coreState.colorMode {
        case .rgb:
            mode = .rgb
        case .temperature:
            mode = .colorTemperature
        case .hsv:
            mode = .hsv
        }
        
        return DeviceState(
            power: coreState.power,
            brightness: coreState.brightness,
            colorTemperature: coreState.colorTemperature,
            color: DeviceColor(
                red: coreState.rgb.red,
                green: coreState.rgb.green,
                blue: coreState.rgb.blue
            )
        )
    }
    
    // Convert to Core_YeelightDeviceState
    public var coreYeelightState: Core_YeelightDeviceState {
        let colorMode: Core_ColorMode
        if let mode = mode {
            switch mode {
            case .rgb:
                colorMode = .rgb
            case .colorTemperature:
                colorMode = .temperature
            case .hsv:
                colorMode = .hsv
            case .normal, .colorFlow:
                colorMode = .temperature // Default
            }
        } else {
            colorMode = .temperature // Default
        }
        
        return Core_YeelightDeviceState(
            power: power,
            brightness: brightness,
            colorTemperature: colorTemperature,
            colorMode: colorMode,
            rgb: Core_RGB(
                red: color.red,
                green: color.green,
                blue: color.blue
            ),
            hue: 0, // Default
            saturation: 0, // Default
            name: "",
            location: nil,
            lastUpdated: Date(),
            isOnline: isOnline,
            lastSeen: lastSeen
        )
    }
    
    // Convert to Core_DeviceState
    public var coreDeviceState: Core_DeviceState {
        return Core_DeviceState(
            power: power,
            brightness: brightness,
            colorTemperature: colorTemperature,
            color: Core_DeviceColor(
                red: color.red,
                green: color.green,
                blue: color.blue
            ),
            effect: effect
        )
    }
}

// MARK: - Device Color

public struct Core_DeviceColor: Codable, Hashable {
    public var red: Int
    public var green: Int
    public var blue: Int
    
    public static let white = Core_DeviceColor(red: 255, green: 255, blue: 255)
    public static let black = Core_DeviceColor(red: 0, green: 0, blue: 0)
    public static let red = Core_DeviceColor(red: 255, green: 0, blue: 0)
    public static let green = Core_DeviceColor(red: 0, green: 255, blue: 0)
    public static let blue = Core_DeviceColor(red: 0, green: 0, blue: 255)
    
    public init(red: Int = 255, green: Int = 255, blue: Int = 255) {
        self.red = red
        self.green = green
        self.blue = blue
    }
    
    // Convert to SwiftUI Color
    public var uiColor: Color {
        Color(red: Double(red) / 255.0, 
              green: Double(green) / 255.0, 
              blue: Double(blue) / 255.0)
    }
    
    // Convert from SwiftUI Color
    public static func from(uiColor: Color) -> Core_DeviceColor {
        // Extract RGB components from SwiftUI Color
        // This is a simplified implementation that works for basic colors
        
        // Check for common colors first
        if uiColor == .white { return .white }
        if uiColor == .black { return .black }
        if uiColor == .red { return .red }
        if uiColor == .green { return .green }
        if uiColor == .blue { return .blue }
        
        // For other colors, we need to use UIColor/NSColor to extract components
        #if canImport(UIKit)
        let uiColorRepresentation = UIColor(uiColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColorRepresentation.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return Core_DeviceColor(
            red: Int(red * 255),
            green: Int(green * 255),
            blue: Int(blue * 255)
        )
        #elseif canImport(AppKit)
        let nsColorRepresentation = NSColor(uiColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColorRepresentation.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return Core_DeviceColor(
            red: Int(red * 255),
            green: Int(green * 255),
            blue: Int(blue * 255)
        )
        #else
        // Fallback for other platforms
        return Core_DeviceColor(red: 255, green: 255, blue: 255)
        #endif
    }
}

// MARK: - Legacy Types (for compatibility)

// Create typealiases to disambiguate types
public typealias CoreYeelightDeviceState = Core_YeelightDeviceState
public typealias CoreRGB = Core_RGB
public typealias CoreColorMode = Core_ColorMode
public typealias CoreYeelightDeviceStateUpdate = Core_YeelightDeviceStateUpdate

public struct Core_YeelightDeviceState: Codable, Equatable {
    public var power: Bool
    public var brightness: Int
    public var colorTemperature: Int
    public var colorMode: Core_ColorMode
    public var rgb: Core_RGB
    public var hue: Int
    public var saturation: Int
    public var name: String
    public var location: Location?
    public var lastUpdated: Date
    public var isOnline: Bool
    public var lastSeen: Date
    
    public init(
        power: Bool = false,
        brightness: Int = 100,
        colorTemperature: Int = 4000,
        colorMode: Core_ColorMode = .temperature,
        rgb: Core_RGB = Core_RGB(),
        hue: Int = 0,
        saturation: Int = 0,
        name: String = "",
        location: Location? = nil,
        lastUpdated: Date = Date(),
        isOnline: Bool = false,
        lastSeen: Date = Date()
    ) {
        self.power = power
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.colorMode = colorMode
        self.rgb = rgb
        self.hue = hue
        self.saturation = saturation
        self.name = name
        self.location = location
        self.lastUpdated = lastUpdated
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
    
    public static func == (lhs: Core_YeelightDeviceState, rhs: Core_YeelightDeviceState) -> Bool {
        return lhs.power == rhs.power &&
            lhs.brightness == rhs.brightness &&
            lhs.colorMode == rhs.colorMode &&
            lhs.colorTemperature == rhs.colorTemperature &&
            lhs.rgb == rhs.rgb &&
            lhs.hue == rhs.hue &&
            lhs.saturation == rhs.saturation
    }
}

public struct Core_RGB: Codable, Equatable {
    public var red: Int
    public var green: Int
    public var blue: Int
    
    public init(red: Int = 255, green: Int = 255, blue: Int = 255) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

public enum Core_ColorMode: Int, Codable {
    case rgb = 1
    case temperature = 2
    case hsv = 3
    
    public var displayName: String {
        switch self {
        case .rgb:
            return "RGB"
        case .temperature:
            return "Temperature"
        case .hsv:
            return "HSV"
        }
    }
}

public struct Core_YeelightDeviceStateUpdate: Codable, Equatable {
    public let deviceId: String
    public let state: Core_YeelightDeviceState
    public let timestamp: Date
    
    public init(deviceId: String, state: Core_YeelightDeviceState, timestamp: Date = Date()) {
        self.deviceId = deviceId
        self.state = state
        self.timestamp = timestamp
    }
}

// MARK: - UI Device State

/// A simplified device state for UI components
public struct UI_DeviceState: Equatable, Codable {
    public var isOn: Bool
    public var brightness: Double
    public var colorTemperature: Double
    public var color: Color
    public var mode: String
    public var activeEffect: String?
    
    public init(
        isOn: Bool = false,
        brightness: Double = 100.0,
        colorTemperature: Double = 4000.0,
        color: Color = .white,
        mode: String = "normal",
        activeEffect: String? = nil
    ) {
        self.isOn = isOn
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.color = color
        self.mode = mode
        self.activeEffect = activeEffect
    }
    
    // Codable conformance for Color
    enum CodingKeys: String, CodingKey {
        case isOn, brightness, colorTemperature, mode, activeEffect
        case colorRed, colorGreen, colorBlue, colorOpacity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isOn = try container.decode(Bool.self, forKey: .isOn)
        brightness = try container.decode(Double.self, forKey: .brightness)
        colorTemperature = try container.decode(Double.self, forKey: .colorTemperature)
        mode = try container.decode(String.self, forKey: .mode)
        activeEffect = try container.decodeIfPresent(String.self, forKey: .activeEffect)
        
        let red = try container.decode(Double.self, forKey: .colorRed)
        let green = try container.decode(Double.self, forKey: .colorGreen)
        let blue = try container.decode(Double.self, forKey: .colorBlue)
        let opacity = try container.decode(Double.self, forKey: .colorOpacity)
        
        color = Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isOn, forKey: .isOn)
        try container.encode(brightness, forKey: .brightness)
        try container.encode(colorTemperature, forKey: .colorTemperature)
        try container.encode(mode, forKey: .mode)
        try container.encodeIfPresent(activeEffect, forKey: .activeEffect)
        
        // Extract color components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0
        
        #if os(iOS) || os(macOS)
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        #else
        // Default values for other platforms
        red = 1.0
        green = 1.0
        blue = 1.0
        opacity = 1.0
        #endif
        
        try container.encode(red, forKey: .colorRed)
        try container.encode(green, forKey: .colorGreen)
        try container.encode(blue, forKey: .colorBlue)
        try container.encode(opacity, forKey: .colorOpacity)
    }
}

// MARK: - Core Device State
public enum Core_DeviceStateEnum: Codable, Equatable, Hashable {
    case on(brightness: Int, color: Core_Color)
    case off
    case unknown
    
    // Add computed properties for easier access
    public var isOn: Bool {
        switch self {
        case .on:
            return true
        case .off, .unknown:
            return false
        }
    }
    
    public var brightness: Int {
        switch self {
        case .on(let brightness, _):
            return brightness
        case .off, .unknown:
            return 0
        }
    }
    
    public var color: Core_Color {
        switch self {
        case .on(_, let color):
            return color
        case .off, .unknown:
            return Core_Color(red: 1.0, green: 1.0, blue: 1.0)
        }
    }
    
    // Codable conformance
    private enum CodingKeys: String, CodingKey {
        case type, brightness, color
    }
    
    private enum StateType: String, Codable {
        case on, off, unknown
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(StateType.self, forKey: .type)
        
        switch type {
        case .on:
            let brightness = try container.decode(Int.self, forKey: .brightness)
            let color = try container.decode(Core_Color.self, forKey: .color)
            self = .on(brightness: brightness, color: color)
        case .off:
            self = .off
        case .unknown:
            self = .unknown
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .on(let brightness, let color):
            try container.encode(StateType.on, forKey: .type)
            try container.encode(brightness, forKey: .brightness)
            try container.encode(color, forKey: .color)
        case .off:
            try container.encode(StateType.off, forKey: .type)
        case .unknown:
            try container.encode(StateType.unknown, forKey: .type)
        }
    }
}

public struct Core_Color: Codable, Equatable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    
    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
    
    public static let white = Core_Color(red: 1.0, green: 1.0, blue: 1.0)
    public static let black = Core_Color(red: 0.0, green: 0.0, blue: 0.0)
    public static let red = Core_Color(red: 1.0, green: 0.0, blue: 0.0)
    public static let green = Core_Color(red: 0.0, green: 1.0, blue: 0.0)
    public static let blue = Core_Color(red: 0.0, green: 0.0, blue: 1.0)
} 