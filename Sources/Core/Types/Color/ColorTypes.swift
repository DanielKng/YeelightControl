import Foundation
import SwiftUI

// MARK: - Color Type
public struct Core_Color: Codable, Equatable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double
    
    public init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
    
    public static let clear = Core_Color(red: 0, green: 0, blue: 0, opacity: 0)
    public static let black = Core_Color(red: 0, green: 0, blue: 0)
    public static let white = Core_Color(red: 1, green: 1, blue: 1)
    public static let red = Core_Color(red: 1, green: 0, blue: 0)
    public static let green = Core_Color(red: 0, green: 1, blue: 0)
    public static let blue = Core_Color(red: 0, green: 0, blue: 1)
    public static let yellow = Core_Color(red: 1, green: 1, blue: 0)
    public static let orange = Core_Color(red: 1, green: 0.5, blue: 0)
    public static let purple = Core_Color(red: 0.5, green: 0, blue: 0.5)
    public static let pink = Core_Color(red: 1, green: 0.75, blue: 0.8)
    
    // Convert to SwiftUI Color
    public var uiColor: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    // Convert from SwiftUI Color
    public static func from(uiColor: Color) -> Core_Color {
        // This is a simplification as extracting RGB components from SwiftUI Color is not straightforward
        // In a real implementation, you would need a more robust conversion
        return Core_Color(red: 0, green: 0, blue: 0)
    }
} 