import SwiftUI
import Foundation
import CoreLocation

// MARK: - Unified Device State

/// The main device state struct used throughout the app
public struct DeviceState: Codable, Equatable, Hashable {
    public var power: Bool
    public var brightness: Int
    public var colorTemperature: Int
    public var color: DeviceColor
    public var effect: Effect?
    public var isOnline: Bool
    public var lastSeen: Date
    public var mode: YeelightMode?
    
    public init(
        power: Bool = false,
        brightness: Int = 100,
        colorTemperature: Int = 4000,
        color: DeviceColor = .white,
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
            ),
            isOnline: coreState.isOnline,
            lastSeen: coreState.lastSeen,
            mode: mode
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
        if power {
            let coreColor = Core_Color(
                red: Double(color.red) / 255.0,
                green: Double(color.green) / 255.0,
                blue: Double(color.blue) / 255.0
            )
            return .on(brightness: brightness, color: coreColor)
        } else {
            return .off
        }
    }
}

// MARK: - Device Color

public struct DeviceColor: Codable, Hashable {
    public var red: Int
    public var green: Int
    public var blue: Int
    
    public static let white = DeviceColor(red: 255, green: 255, blue: 255)
    public static let black = DeviceColor(red: 0, green: 0, blue: 0)
    public static let red = DeviceColor(red: 255, green: 0, blue: 0)
    public static let green = DeviceColor(red: 0, green: 255, blue: 0)
    public static let blue = DeviceColor(red: 0, green: 0, blue: 255)
    
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
    public static func from(uiColor: Color) -> DeviceColor {
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
        
        return DeviceColor(
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
        
        return DeviceColor(
            red: Int(red * 255),
            green: Int(green * 255),
            blue: Int(blue * 255)
        )
        #else
        // Fallback for other platforms
        return DeviceColor(red: 255, green: 255, blue: 255)
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

// MARK: - UI Device State (for UI layer)

/// Device state for UI components
public struct UI_DeviceState: Equatable, Codable {
    public var isOn: Bool
    public var brightness: Double?
    public var colorTemperature: Double?
    public var color: Color?
    public var mode: String?
    public var activeEffect: String?
    
    public init(
        isOn: Bool = true,
        brightness: Double? = nil,
        colorTemperature: Double? = nil,
        color: Color? = nil,
        mode: String? = nil,
        activeEffect: String? = nil
    ) {
        self.isOn = isOn
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.color = color
        self.mode = mode
        self.activeEffect = activeEffect
    }
    
    // Convert to DeviceState
    public func toDeviceState() -> DeviceState {
        DeviceState(
            power: isOn,
            brightness: Int(brightness ?? 100),
            colorTemperature: Int(colorTemperature ?? 4000),
            color: DeviceColor.white, // Default
            effect: nil,
            isOnline: true,
            lastSeen: Date()
        )
    }
}

// MARK: - Core Device State
public enum Core_DeviceState {
    case on(brightness: Int, color: Core_Color)
    case off
}

public struct Core_Color {
    public var red: Double
    public var green: Double
    public var blue: Double
    
    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }
} 