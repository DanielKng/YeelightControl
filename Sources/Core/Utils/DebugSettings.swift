import SwiftUI

/// Centralized management of debug settings
class DebugSettings: ObservableObject {
    static let shared = DebugSettings()
    
    @AppStorage("debugMode") var debugMode = false
    @AppStorage("logToFile") var logToFile = false
    @AppStorage("logLevel") var logLevel = LogEntry.Level.info.rawValue
    @AppStorage("networkMonitoring") var networkMonitoring = false
    @AppStorage("connectionLogging") var connectionLogging = false
    @AppStorage("deviceCacheDebugging") var deviceCacheDebugging = false
    
    private init() {}
    
    var isAnyDebugEnabled: Bool {
        debugMode || networkMonitoring || connectionLogging || deviceCacheDebugging
    }
} 