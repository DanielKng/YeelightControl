import SwiftUI
import Core

// MARK: - Theme Environment

/// Theme structure for UI customization
public struct Theme {
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let textColor: Color
    let accentColor: Color
    
    static let `default` = Theme(
        primaryColor: .blue,
        secondaryColor: .gray,
        backgroundColor: Color(.systemBackground),
        textColor: Color(.label),
        accentColor: .orange
    )
    
    static let dark = Theme(
        primaryColor: .blue,
        secondaryColor: .gray,
        backgroundColor: Color(.systemBackground),
        textColor: Color(.label),
        accentColor: .orange
    )
}

/// Environment key for theme
struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = .default
}

/// Extension to add theme to environment values
extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Type Aliases

/// Type aliases to help with migration
public typealias YeelightManager = UnifiedYeelightManager
public typealias YeelightDevice = YeelightDevice
public typealias DeviceManager = UnifiedDeviceManager
public typealias SceneManager = UnifiedSceneManager
public typealias RoomManager = UnifiedRoomManager
public typealias NetworkMonitor = UnifiedNetworkManager
public typealias Logger = UnifiedLogger
public typealias DeviceID = String
public typealias DeviceConnectionState = Core_DeviceConnectionState

// MARK: - Extensions for Tab Enum

extension MainView.Tab: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "lights": self = .lights
        case "scenes": self = .scenes
        case "rooms": self = .rooms
        case "automations": self = .automations
        default: return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .lights: return "lights"
        case .scenes: return "scenes"
        case .rooms: return "rooms"
        case .automations: return "automations"
        }
    }
}

// MARK: - Debouncer for Search

/// Simple debouncer for search functionality
public class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    public init(delay: TimeInterval) {
        self.delay = delay
    }
    
    public func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
} 