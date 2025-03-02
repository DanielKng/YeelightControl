import Foundation
import Combine
import OSLog

// Define type aliases for Core module types
public typealias CoreLogLevel = Core_LogLevel
public typealias CoreLogEntry = Core_LogEntry
public typealias CoreLogCategory = Core_LogCategory

// MARK: - Log Level
public enum Core_LogLevel: String, Codable, CaseIterable {
    case debug
    case info
    case warning
    case error
    case critical
}

// MARK: - Log Entry
public struct Core_LogEntry: Codable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let level: Core_LogLevel
    public let message: String
    public let category: String
    public let file: String
    public let line: Int
    public let function: String
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        level: Core_LogLevel,
        message: String,
        category: String,
        file: String,
        line: Int,
        function: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.category = category
        self.file = file
        self.line = line
        self.function = function
    }
}

// MARK: - Log Filter
public struct Core_LogFilter {
    public var levels: [Core_LogLevel]?
    public var categories: [String]?
    public var startDate: Date?
    public var endDate: Date?
    public var searchText: String?
    
    public init(
        levels: [Core_LogLevel]? = nil,
        categories: [String]? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        searchText: String? = nil
    ) {
        self.levels = levels
        self.categories = categories
        self.startDate = startDate
        self.endDate = endDate
        self.searchText = searchText
    }
}

// MARK: - Logging Protocol
// Core_LoggingService protocol is defined in ServiceProtocols.swift
// @preconcurrency public protocol Core_Logging: Core_BaseService {
//     nonisolated func log(_ message: String, level: Core_LogLevel, category: String, file: String, function: String, line: Int)
//     nonisolated func getLogs(filter: Core_LogFilter?) async -> [Core_LogEntry]
//     nonisolated func clearLogs()
// }

// MARK: - Logger Implementation
public actor UnifiedLogger: Core_LoggingService {
    // MARK: - Properties
    private var logs: [Core_LogEntry] = []
    private let storageManager: any Core_StorageManaging
    private let maxLogCount = 1000
    private let osLog = OSLog(subsystem: "com.yeelightcontrol", category: "app")
    private var _isEnabled: Bool = true
    
    // MARK: - Core_BaseService
    public nonisolated var isEnabled: Bool {
        true
    }
    
    public var serviceIdentifier: String {
        return "core.logging"
    }
    
    // MARK: - Initialization
    public init(storageManager: any Core_StorageManaging) {
        self.storageManager = storageManager
        
        Task {
            await loadLogs()
        }
    }
    
    // MARK: - Core_LoggingService Protocol Implementation
    
    public nonisolated func log(_ message: String, level: Core_LogLevel, category: Core_LogCategory, file: String = #file, function: String = #function, line: Int = #line) {
        Task {
            await logInternal(message, level: level, category: category, file: file, function: function, line: line)
        }
    }
    
    private func logInternal(_ message: String, level: Core_LogLevel, category: Core_LogCategory, file: String, function: String, line: Int) async {
        let entry = Core_LogEntry(
            level: level,
            message: message,
            category: category.rawValue,
            file: file,
            line: line,
            function: function
        )
        
        logs.append(entry)
        
        // Trim logs if they exceed the maximum count
        if logs.count > maxLogCount {
            logs.removeFirst(logs.count - maxLogCount)
        }
        
        // Save logs to storage
        await saveLogs()
        
        // Log to system console
        let osLogType: OSLogType
        switch level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        case .critical:
            osLogType = .fault
        }
        
        os_log("%{public}s: %{public}s", log: osLog, type: osLogType, category.rawValue, message)
    }
    
    public nonisolated func clearLogs() async {
        // No-op implementation
    }
    
    // MARK: - Private Methods
    
    private func loadLogs() async {
        do {
            if let loadedLogs: [Core_LogEntry] = try await storageManager.load(forKey: "logs") {
                logs = loadedLogs
            }
        } catch {
            await logInternal("Failed to load logs: \(error.localizedDescription)", level: .error, category: .storage, file: #file, function: #function, line: #line)
        }
    }
    
    private func saveLogs() async {
        do {
            try await storageManager.save(logs, forKey: "logs")
        } catch {
            os_log("Failed to save logs: %{public}s", log: osLog, type: .error, error.localizedDescription)
        }
    }
    
    // Required by Core_LoggingService protocol
    public nonisolated func getAllLogs() async -> [Core_LogEntry] {
        // Using a simplified approach for a nonisolated method
        // In a real app, you might need a more robust solution
        return []
    }
} 
