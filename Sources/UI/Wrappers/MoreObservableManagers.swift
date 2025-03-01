import SwiftUI
import Core
import Combine

// MARK: - ObservablePermissionManager

/// Observable wrapper for UnifiedPermissionManager
@MainActor
public class ObservablePermissionManager: ObservableObject {
    private let manager: UnifiedPermissionManager
    @Published public private(set) var locationPermissionGranted: Bool = false
    @Published public private(set) var notificationPermissionGranted: Bool = false
    @Published public private(set) var bluetoothPermissionGranted: Bool = false
    
    public init(manager: UnifiedPermissionManager) {
        self.manager = manager
        Task {
            await updatePermissionStatus()
        }
    }
    
    private func updatePermissionStatus() async {
        self.locationPermissionGranted = await manager.isLocationPermissionGranted
        self.notificationPermissionGranted = await manager.isNotificationPermissionGranted
        self.bluetoothPermissionGranted = await manager.isBluetoothPermissionGranted
    }
    
    public func requestLocationPermission() async {
        await manager.requestLocationPermission()
        await updatePermissionStatus()
    }
    
    public func requestNotificationPermission() async {
        await manager.requestNotificationPermission()
        await updatePermissionStatus()
    }
    
    public func requestBluetoothPermission() async {
        await manager.requestBluetoothPermission()
        await updatePermissionStatus()
    }
    
    public func checkAndRequestPermissions() async {
        await manager.checkAndRequestPermissions()
        await updatePermissionStatus()
    }
    
    public func openSettings() {
        manager.openSettings()
    }
}

// MARK: - ObservableAnalyticsManager

/// Observable wrapper for UnifiedAnalyticsManager
@MainActor
public class ObservableAnalyticsManager: ObservableObject {
    private let manager: UnifiedAnalyticsManager
    @Published public private(set) var isEnabled: Bool = false
    
    public init(manager: UnifiedAnalyticsManager) {
        self.manager = manager
        Task {
            await updateStatus()
        }
    }
    
    private func updateStatus() async {
        self.isEnabled = await manager.isEnabled
    }
    
    public func setEnabled(_ enabled: Bool) async {
        await manager.setEnabled(enabled)
        await updateStatus()
    }
    
    public func logEvent(_ event: String, parameters: [String: Any]? = nil) {
        manager.logEvent(event, parameters: parameters)
    }
    
    public func startSession() async {
        await manager.startSession()
        await updateStatus()
    }
    
    public func endSession() async {
        await manager.endSession()
    }
}

// MARK: - ObservableConfigurationManager

/// Observable wrapper for UnifiedConfigurationManager
@MainActor
public class ObservableConfigurationManager: ObservableObject {
    private let manager: UnifiedConfigurationManager
    @Published public private(set) var appSettings: [String: Any] = [:]
    
    public init(manager: UnifiedConfigurationManager) {
        self.manager = manager
        Task {
            await loadSettings()
        }
    }
    
    private func loadSettings() async {
        do {
            self.appSettings = try await manager.getAppSettings()
        } catch {
            print("Failed to load app settings: \(error)")
        }
    }
    
    public func setSetting(_ value: Any, forKey key: String) async {
        do {
            try await manager.setSetting(value, forKey: key)
            await loadSettings()
        } catch {
            print("Failed to set setting: \(error)")
        }
    }
    
    public func getSetting(forKey key: String) -> Any? {
        return appSettings[key]
    }
    
    public func resetToDefaults() async {
        do {
            try await manager.resetToDefaults()
            await loadSettings()
        } catch {
            print("Failed to reset to defaults: \(error)")
        }
    }
}

// MARK: - ObservableStateManager

/// Observable wrapper for UnifiedStateManager
@MainActor
public class ObservableStateManager: ObservableObject {
    private let manager: UnifiedStateManager
    @Published public private(set) var appState: [String: Any] = [:]
    
    public init(manager: UnifiedStateManager) {
        self.manager = manager
        Task {
            await loadState()
        }
    }
    
    private func loadState() async {
        do {
            self.appState = try await manager.getState()
        } catch {
            print("Failed to load app state: \(error)")
        }
    }
    
    public func setState(_ value: Any, forKey key: String) async {
        do {
            try await manager.setState(value, forKey: key)
            await loadState()
        } catch {
            print("Failed to set state: \(error)")
        }
    }
    
    public func getState(forKey key: String) -> Any? {
        return appState[key]
    }
    
    public func clearState() async {
        do {
            try await manager.clearState()
            await loadState()
        } catch {
            print("Failed to clear state: \(error)")
        }
    }
    
    public func initialize() async {
        await manager.initialize()
        await loadState()
    }
}

// MARK: - ObservableSecurityManager

/// Observable wrapper for UnifiedSecurityManager
@MainActor
public class ObservableSecurityManager: ObservableObject {
    private let manager: UnifiedSecurityManager
    @Published public private(set) var securityAlert: String?
    @Published public private(set) var isSecurityEnabled: Bool = false
    
    public init(manager: UnifiedSecurityManager) {
        self.manager = manager
        Task {
            await updateSecurityStatus()
        }
    }
    
    private func updateSecurityStatus() async {
        self.isSecurityEnabled = await manager.isSecurityEnabled
    }
    
    public func setSecurityEnabled(_ enabled: Bool) async {
        await manager.setSecurityEnabled(enabled)
        await updateSecurityStatus()
    }
    
    public func initialize() async throws {
        try await manager.initialize()
        await updateSecurityStatus()
    }
    
    public func openSecuritySettings() {
        manager.openSecuritySettings()
    }
}

// MARK: - ObservableErrorManager

/// Observable wrapper for UnifiedErrorManager
@MainActor
public class ObservableErrorManager: ObservableObject {
    private let manager: UnifiedErrorManager
    @Published public private(set) var currentError: Error?
    @Published public private(set) var errorHistory: [Error] = []
    
    public init(manager: UnifiedErrorManager) {
        self.manager = manager
    }
    
    public func handle(_ error: Error) {
        manager.handle(error)
        self.currentError = error
        self.errorHistory.append(error)
    }
    
    public func clearError() {
        self.currentError = nil
    }
    
    public func clearErrorHistory() {
        self.errorHistory.removeAll()
    }
}

// MARK: - ObservableThemeManager

/// Observable wrapper for UnifiedThemeManager
@MainActor
public class ObservableThemeManager: ObservableObject {
    private let manager: UnifiedThemeManager
    @Published public private(set) var currentTheme: Theme = .default
    
    public init(manager: UnifiedThemeManager) {
        self.manager = manager
        Task {
            await updateTheme()
        }
    }
    
    private func updateTheme() async {
        // In a real implementation, this would get the current theme from the manager
        // For now, we'll just use the default theme
        self.currentTheme = .default
    }
    
    public func setTheme(_ theme: Theme) {
        // In a real implementation, this would set the theme in the manager
        self.currentTheme = theme
    }
    
    public func applyTheme() {
        manager.applyTheme()
    }
}

// MARK: - ObservableConnectionManager

/// Observable wrapper for UnifiedConnectionManager
@MainActor
public class ObservableConnectionManager: ObservableObject {
    private let manager: UnifiedConnectionManager
    @Published public private(set) var connectionStatus: [String: Bool] = [:]
    
    public init(manager: UnifiedConnectionManager) {
        self.manager = manager
        Task {
            await updateConnectionStatus()
        }
    }
    
    private func updateConnectionStatus() async {
        // In a real implementation, this would get the connection status from the manager
        // For now, we'll just use a sample status
        self.connectionStatus = [
            "wifi": true,
            "bluetooth": false,
            "internet": true
        ]
    }
    
    public func initialize() async throws {
        try await manager.initialize()
        await updateConnectionStatus()
    }
    
    public func testConnection() async -> Bool {
        let result = await manager.testConnection()
        await updateConnectionStatus()
        return result
    }
} 