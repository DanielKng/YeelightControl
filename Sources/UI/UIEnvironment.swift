import SwiftUI
import Core

// MARK: - Theme Environment

/// Theme structure for UI customization
public struct Theme: Equatable {
    public let primary: Color
    public let secondary: Color
    public let accent: Color
    public let background: Color
    public let surface: Color
    public let text: Color
    public let error: Color
    
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
    
    public static let `default` = Theme()
    
    public static let dark = Theme(
        primary: .blue,
        secondary: .green,
        accent: .orange,
        background: Color(.systemBackground),
        surface: Color(.secondarySystemBackground),
        text: .white,
        error: .red
    )
    
    public static let light = Theme(
        primary: .blue,
        secondary: .green,
        accent: .orange,
        background: Color(.systemBackground),
        surface: Color(.secondarySystemBackground),
        text: .black,
        error: .red
    )
}

/// Environment key for theme
public struct ThemeKey: EnvironmentKey {
    public static let defaultValue: Theme = .default
}

/// Extension to add theme to environment values
extension EnvironmentValues {
    public var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Observable Wrappers for Actors

/// Observable wrapper for UnifiedLogger
@MainActor
public class ObservableLogger: ObservableObject {
    private let logger: UnifiedLogger
    @Published public private(set) var logs: [LogEntry] = []
    
    public static let shared = ObservableLogger()
    
    private init() {
        self.logger = ServiceContainer.shared.logManager
        Task {
            await loadLogs()
        }
    }
    
    private func loadLogs() async {
        // In a real implementation, this would load logs from the logger
        // For now, we'll just create some sample logs
        self.logs = [
            LogEntry(level: .info, category: .system, message: "Application started"),
            LogEntry(level: .debug, category: .network, message: "Scanning for devices"),
            LogEntry(level: .warning, category: .device, message: "Device connection timeout"),
            LogEntry(level: .error, category: .scene, message: "Failed to apply scene"),
            LogEntry(level: .critical, category: .system, message: "Unexpected error occurred")
        ]
    }
    
    public func log(level: LogEntry.Level, category: LogEntry.Category, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            file: file,
            function: function,
            line: line
        )
        logs.append(entry)
        
        // In a real implementation, this would also log to the actual logger
        Task {
            await logger.log(message: message, level: level.rawValue, category: category.rawValue, file: file, function: function, line: line)
        }
    }
    
    public func clearLogs() {
        logs.removeAll()
    }
}

/// Observable wrapper for UnifiedYeelightManager
@MainActor
public class ObservableYeelightManager: ObservableObject {
    private let manager: UnifiedYeelightManager
    @Published public private(set) var devices: [YeelightDevice] = []
    
    public init(manager: UnifiedYeelightManager) {
        self.manager = manager
        Task {
            await updateDevices()
        }
    }
    
    private func updateDevices() async {
        self.devices = manager.devices
    }
    
    public func connect(to device: YeelightDevice) async throws {
        try await manager.connect(to: device)
        await updateDevices()
    }
    
    public func disconnect(from device: YeelightDevice) async {
        await manager.disconnect(from: device)
        await updateDevices()
    }
    
    public func send(_ command: YeelightCommand, to device: YeelightDevice) async throws {
        try await manager.send(command, to: device)
        await updateDevices()
    }
    
    public func discover() async throws -> [YeelightDevice] {
        let devices = try await manager.discover()
        await updateDevices()
        return devices
    }
    
    public func getConnectedDevices() -> [YeelightDevice] {
        return manager.getConnectedDevices()
    }
    
    public func getDevice(withId id: String) -> YeelightDevice? {
        return manager.getDevice(withId: id)
    }
    
    public func updateDevice(_ device: YeelightDevice) async throws {
        try await manager.updateDevice(device)
        await updateDevices()
    }
    
    public func applyScene(_ scene: any YeelightScene, to device: YeelightDevice) {
        manager.applyScene(scene as! Scene, to: device)
    }
    
    public func stopEffect(on device: YeelightDevice) {
        manager.stopEffect(on: device)
    }
}

// MARK: - Type Aliases

/// Type aliases to help with migration
public typealias YeelightManager = ObservableYeelightManager
public typealias YeelightDevice = Core.YeelightDevice
public typealias DeviceManager = ObservableDeviceManager
public typealias SceneManager = ObservableSceneManager
public typealias RoomManager = ObservableRoomManager
public typealias NetworkMonitor = ObservableNetworkManager
public typealias Logger = ObservableLogger
public typealias DeviceID = String
public typealias DeviceConnectionState = Bool // Simplified to a boolean for now
public typealias UnifiedAutomationManager = ObservableAutomationManager
public typealias EffectManager = ObservableEffectManager
public typealias StorageManager = ObservableStorageManager
public typealias LocationManager = ObservableLocationManager
public typealias PermissionManager = ObservablePermissionManager
public typealias AnalyticsManager = ObservableAnalyticsManager
public typealias ConfigurationManager = ObservableConfigurationManager
public typealias StateManager = ObservableStateManager
public typealias SecurityManager = ObservableSecurityManager
public typealias ErrorManager = ObservableErrorManager
public typealias ThemeManager = ObservableThemeManager
public typealias ConnectionManager = ObservableConnectionManager

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

// MARK: - Scene Protocol

/// Protocol for Yeelight scenes to avoid ambiguity with SwiftUI.Scene
public protocol YeelightScene: Identifiable, Equatable {
    var id: String { get }
    var name: String { get }
    var deviceIds: [String] { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

// MARK: - Device Settings Type

/// Device settings for scene creation
public struct DeviceSettings: Identifiable, Equatable, Codable {
    public var id: String
    public var isOn: Bool
    public var brightness: Double
    public var colorTemperature: Double?
    public var color: Color?
    public var mode: DeviceMode
    
    public init(
        id: String = UUID().uuidString,
        isOn: Bool = true,
        brightness: Double = 100,
        colorTemperature: Double? = nil,
        color: Color? = nil,
        mode: DeviceMode = .color
    ) {
        self.id = id
        self.isOn = isOn
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.color = color
        self.mode = mode
    }
    
    public enum DeviceMode: String, Codable {
        case color
        case temperature
    }
}

extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        // Convert Color to hex string
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let hex = String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(r) * 255),
            lroundf(Float(g) * 255),
            lroundf(Float(b) * 255)
        )
        
        try container.encode(hex)
    }
}

// MARK: - Scene Preset Type

/// Scene preset for scene creation
public struct ScenePreset: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let icon: String
    public let defaultSettings: DeviceSettings
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        icon: String,
        defaultSettings: DeviceSettings
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.defaultSettings = defaultSettings
    }
    
    public static let presets: [ScenePreset] = [
        ScenePreset(
            name: "Reading",
            description: "Bright white light for reading",
            icon: "book",
            defaultSettings: DeviceSettings(
                brightness: 100,
                colorTemperature: 4500,
                mode: .temperature
            )
        ),
        ScenePreset(
            name: "Relaxing",
            description: "Warm light for relaxing",
            icon: "moon.stars",
            defaultSettings: DeviceSettings(
                brightness: 50,
                colorTemperature: 2700,
                mode: .temperature
            )
        ),
        ScenePreset(
            name: "Movie",
            description: "Dim light for watching movies",
            icon: "film",
            defaultSettings: DeviceSettings(
                brightness: 20,
                color: Color.blue.opacity(0.7),
                mode: .color
            )
        ),
        ScenePreset(
            name: "Party",
            description: "Colorful light for parties",
            icon: "party.popper",
            defaultSettings: DeviceSettings(
                brightness: 100,
                color: Color.purple,
                mode: .color
            )
        )
    ]
}

// MARK: - Automation Types

/// Automation type for UI components
public struct Automation: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let trigger: AutomationTrigger
    public let action: AutomationAction
    public let isEnabled: Bool
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        trigger: AutomationTrigger,
        action: AutomationAction,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.trigger = trigger
        self.action = action
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public enum Location: String, CaseIterable, Identifiable {
        case home, work, custom
        public var id: String { self.rawValue }
    }
}

/// Automation trigger type
public enum AutomationTrigger: Equatable {
    case time(hour: Int, minute: Int)
    case location(enter: Bool, location: Automation.Location)
    case device(deviceId: String, state: DeviceState)
    case manual
    
    public var name: String {
        switch self {
        case .time: return "Time"
        case .location: return "Location"
        case .device: return "Device"
        case .manual: return "Manual"
        }
    }
}

/// Automation action type
public enum AutomationAction: Equatable {
    case applyScene(sceneId: String)
    case setDeviceState(deviceId: String, state: DeviceState)
    case runEffect(deviceId: String, effectId: String)
    
    public var name: String {
        switch self {
        case .applyScene: return "Apply Scene"
        case .setDeviceState: return "Set Device State"
        case .runEffect: return "Run Effect"
        }
    }
}

/// Observable wrapper for automation manager
@MainActor
public class ObservableAutomationManager: ObservableObject {
    @Published public private(set) var automations: [Automation] = []
    
    public static let shared = ObservableAutomationManager()
    
    private init() {
        // In a real implementation, this would load automations from a storage manager
        // For now, we'll just create some sample automations
        self.automations = [
            Automation(
                name: "Morning Routine",
                trigger: .time(hour: 7, minute: 0),
                action: .applyScene(sceneId: "morning_scene")
            ),
            Automation(
                name: "Evening Lights",
                trigger: .time(hour: 19, minute: 0),
                action: .applyScene(sceneId: "evening_scene")
            ),
            Automation(
                name: "Arrive Home",
                trigger: .location(enter: true, location: .home),
                action: .setDeviceState(deviceId: "light_1", state: DeviceState())
            )
        ]
    }
    
    public func addAutomation(_ automation: Automation) {
        automations.append(automation)
    }
    
    public func removeAutomation(withId id: String) {
        automations.removeAll { $0.id == id }
    }
    
    public func updateAutomation(_ automation: Automation) {
        if let index = automations.firstIndex(where: { $0.id == automation.id }) {
            automations[index] = automation
        }
    }
    
    public func getAutomation(withId id: String) -> Automation? {
        return automations.first { $0.id == id }
    }
}

// MARK: - Log Entry Type

/// Log entry type for UI components
public struct LogEntry: Identifiable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let level: Level
    public let category: Category
    public let message: String
    public let file: String
    public let function: String
    public let line: Int
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: Level,
        category: Category,
        message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.file = file
        self.function = function
        self.line = line
    }
    
    public enum Level: String, CaseIterable, Identifiable {
        case debug, info, warning, error, critical
        public var id: String { self.rawValue }
        
        public var color: Color {
            switch self {
            case .debug: return .gray
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .critical: return .purple
            }
        }
    }
    
    public enum Category: String, CaseIterable, Identifiable {
        case network, device, scene, effect, system, other
        public var id: String { self.rawValue }
        
        public var icon: String {
            switch self {
            case .network: return "network"
            case .device: return "lightbulb"
            case .scene: return "theatermasks"
            case .effect: return "wand.and.stars"
            case .system: return "gear"
            case .other: return "questionmark.circle"
            }
        }
    }
} 