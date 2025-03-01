import Foundation
import SwiftUI
import Combine

// MARK: - Theme Types
public enum Core_Theme: String, Codable, CaseIterable {
    case light
    case dark
    case system
    case custom
}

// MARK: - Theme Protocols
@preconcurrency public protocol Core_ThemeManaging: Core_BaseService {
    /// The current theme
    var currentTheme: Core_Theme { get }
    
    /// Publisher for theme updates
    nonisolated var themeUpdates: AnyPublisher<Core_Theme, Never> { get }
    
    /// Set the theme
    func setTheme(_ theme: Core_Theme)
    
    /// Get the theme colors
    func getThemeColors() -> ThemeColors
    
    /// Get the theme fonts
    func getThemeFonts() -> ThemeFonts
    
    /// Get the theme metrics
    func getThemeMetrics() -> ThemeMetrics
} 