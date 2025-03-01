import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - Theme Colors Protocol
public protocol Core_ThemeColors {
    var primary: Color { get }
    var secondary: Color { get }
    var accent: Color { get }
    var background: Color { get }
    var surface: Color { get }
    var text: Color { get }
    var error: Color { get }
}

// MARK: - Concrete Theme Colors
public struct ConcreteThemeColors: Core_ThemeColors {
    public var primary: Color
    public var secondary: Color
    public var accent: Color
    public var background: Color
    public var surface: Color
    public var text: Color
    public var error: Color
    
    public init(
        primary: Color = .blue,
        secondary: Color = .green,
        accent: Color = .orange,
        background: Color = Color(.systemBackground),
        surface: Color = Color(.secondarySystemBackground),
        text: Color = .primary,
        error: Color = .red
    ) {
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.background = background
        self.surface = surface
        self.text = text
        self.error = error
    }
}

// MARK: - Theme Fonts Protocol
public protocol Core_ThemeFonts {
    var title: Font { get }
    var headline: Font { get }
    var body: Font { get }
    var caption: Font { get }
    var button: Font { get }
}

// MARK: - Concrete Theme Fonts
public struct ConcreteThemeFonts: Core_ThemeFonts {
    public var title: Font
    public var headline: Font
    public var body: Font
    public var caption: Font
    public var button: Font
    
    public init(
        title: Font = .title,
        headline: Font = .headline,
        body: Font = .body,
        caption: Font = .caption,
        button: Font = .headline
    ) {
        self.title = title
        self.headline = headline
        self.body = body
        self.caption = caption
        self.button = button
    }
}

// MARK: - Theme Metrics Protocol
public protocol Core_ThemeMetrics {
    var spacing: CGFloat { get }
    var padding: CGFloat { get }
    var cornerRadius: CGFloat { get }
    var iconSize: CGFloat { get }
    var borderWidth: CGFloat { get }
}

// MARK: - Concrete Theme Metrics
public struct ConcreteThemeMetrics: Core_ThemeMetrics {
    public var spacing: CGFloat
    public var padding: CGFloat
    public var cornerRadius: CGFloat
    public var iconSize: CGFloat
    public var borderWidth: CGFloat
    
    public init(
        spacing: CGFloat = 8,
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 8,
        iconSize: CGFloat = 24,
        borderWidth: CGFloat = 1
    ) {
        self.spacing = spacing
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.iconSize = iconSize
        self.borderWidth = borderWidth
    }
}

// MARK: - Theme Managing Protocol
// Core_ThemeManaging protocol is defined in ThemeTypes.swift

// MARK: - Theme
// Core_Theme enum is defined in ThemeTypes.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Unified Theme Manager Implementation
public final class UnifiedThemeManager: ObservableObject, Core_ThemeManaging, Core_BaseService {
    // MARK: - Properties
    private var _currentTheme: Core_Theme = .system
    public private(set) var currentTheme: Core_Theme {
        get { _currentTheme }
        set {
            _currentTheme = newValue
            objectWillChange.send()
        }
    }
    @Published public private(set) var colors: ConcreteThemeColors = ConcreteThemeColors()
    @Published public private(set) var fonts: ConcreteThemeFonts = ConcreteThemeFonts()
    @Published public private(set) var metrics: ConcreteThemeMetrics = ConcreteThemeMetrics()
    
    private let storageManager: any Core_StorageManaging
    private let themeSubject = PassthroughSubject<Core_Theme, Never>()
    private var _isEnabled: Bool = true
    
    // MARK: - Core_BaseService Conformance
    nonisolated public var isEnabled: Bool {
        _isEnabled
    }
    
    // MARK: - Core_ThemeManaging Conformance
    
    nonisolated public var themeUpdates: AnyPublisher<Core_Theme, Never> {
        themeSubject.eraseToAnyPublisher()
    }
    
    nonisolated public func setTheme(_ theme: Core_Theme) {
        Task {
            await setThemeInternal(theme)
        }
    }
    
    public func getThemeColors() -> any ThemeColors {
        return colors as any ThemeColors
    }
    
    public func getThemeFonts() -> any ThemeFonts {
        return fonts as any ThemeFonts
    }
    
    public func getThemeMetrics() -> any ThemeMetrics {
        return metrics as any ThemeMetrics
    }
    
    // MARK: - Initialization
    public init(storageManager: any Core_StorageManaging) {
        self.storageManager = storageManager
        
        Task {
            await loadTheme()
        }
    }
    
    // MARK: - Private Methods
    private func updateThemeComponents() {
        switch currentTheme {
        case .light:
            colors = ConcreteThemeColors(
                primary: .blue,
                secondary: .green,
                accent: .orange,
                background: Color(.systemBackground),
                surface: Color(.secondarySystemBackground),
                text: .black,
                error: .red
            )
        case .dark:
            colors = ConcreteThemeColors(
                primary: .blue,
                secondary: .green,
                accent: .orange,
                background: Color(.systemBackground),
                surface: Color(.secondarySystemBackground),
                text: .white,
                error: .red
            )
        case .system:
            // Use system colors
            colors = ConcreteThemeColors()
        case .custom:
            // Custom theme would be loaded from storage
            break
        }
    }
    
    private func loadTheme() async {
        do {
            if let savedTheme = try await storageManager.load(Core_Theme.self, forKey: "app_theme") {
                await MainActor.run {
                    currentTheme = savedTheme
                    updateThemeComponents()
                }
            } else {
                await MainActor.run {
                    currentTheme = .system
                    updateThemeComponents()
                }
            }
        } catch {
            print("Error loading theme: \(error)")
            
            await MainActor.run {
                currentTheme = .system
                updateThemeComponents()
            }
        }
    }
    
    private func saveTheme() async {
        do {
            try await storageManager.save(currentTheme, forKey: "app_theme")
        } catch {
            print("Error saving theme: \(error)")
        }
    }
    
    private func setThemeInternal(_ theme: Core_Theme) async {
        currentTheme = theme
        updateThemeComponents()
        themeSubject.send(theme)
        
        Task {
            await saveTheme()
        }
    }
} 


