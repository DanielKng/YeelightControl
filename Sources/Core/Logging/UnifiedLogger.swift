import Foundation
import Combine
import OSLog

// Define type aliases for Core module types
public typealias CoreLogLevel = LogLevel
public typealias CoreLogEntry = LogEntry
public typealias CoreLogCategory = LogCategory

// MARK: - Log Level
public enum LogLevel: String, Codable, CaseIterable {
    case debug
    case info
    case warning
    case error
    case critical
}

// MARK: - Log Entry
public struct LogEntry: Codable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let level: LogLevel
    public let message: String
    public let category: String
    public let file: String
    public let line: Int
    public let function: String
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        level: LogLevel,
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
public struct LogFilter {
    public var levels: [LogLevel]?
    public var categories: [String]?
    public var startDate: Date?
    public var endDate: Date?
    public var searchText: String?
    
    public init(
        levels: [LogLevel]? = nil,
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
@preconcurrency public protocol Logging: Actor {
    func log(_ message: String, level: LogLevel, category: String, file: String, function: String, line: Int) async
    func getLogs(filter: LogFilter?) async -> [LogEntry]
    func clearLogs() async
}

// MARK: - Logger Implementation
public actor UnifiedLogger: Logging {
    // MARK: - Properties
    private var logs: [LogEntry] = []
    private let storageManager: any StorageManaging
    private let logSubject = PassthroughSubject<LogEntry, Never>()
    private let maxLogCount = 1000
    private let osLog = OSLog(subsystem: "com.yeelightcontrol", category: "app")
    
    // MARK: - Initialization
    public init(storageManager: any StorageManaging) {
        self.storageManager = storageManager
        
        Task {
            await loadLogs()
        }
    }
    
    // MARK: - Logging
    
    public func log(_ message: String, level: LogLevel, category: String, file: String = #file, function: String = #function, line: Int = #line) async {
        let entry = LogEntry(
            level: level,
            message: message,
            category: category,
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
        
        os_log("%{public}s: %{public}s", log: osLog, type: osLogType, category, message)
        
        // Publish log entry
        logSubject.send(entry)
    }
    
    public func getLogs(filter: LogFilter? = nil) async -> [LogEntry] {
        guard let filter = filter else {
            return logs
        }
        
        return logs.filter { entry in
            var shouldInclude = true
            
            if let levels = filter.levels, !levels.isEmpty {
                shouldInclude = shouldInclude && levels.contains(entry.level)
            }
            
            if let categories = filter.categories, !categories.isEmpty {
                shouldInclude = shouldInclude && categories.contains(entry.category)
            }
            
            if let startDate = filter.startDate {
                shouldInclude = shouldInclude && entry.timestamp >= startDate
            }
            
            if let endDate = filter.endDate {
                shouldInclude = shouldInclude && entry.timestamp <= endDate
            }
            
            if let searchText = filter.searchText, !searchText.isEmpty {
                shouldInclude = shouldInclude && (
                    entry.message.localizedCaseInsensitiveContains(searchText) ||
                    entry.category.localizedCaseInsensitiveContains(searchText) ||
                    entry.file.localizedCaseInsensitiveContains(searchText)
                )
            }
            
            return shouldInclude
        }
    }
    
    public func clearLogs() async {
        logs.removeAll()
        await saveLogs()
    }
    
    // MARK: - Private Methods
    
    private func loadLogs() async {
        do {
            logs = try await storageManager.getAll(fromCollection: "logs")
        } catch {
            await log("Failed to load logs: \(error.localizedDescription)", level: .error, category: "storage")
        }
    }
    
    private func saveLogs() async {
        do {
            try await storageManager.deleteCollection("logs")
            for log in logs {
                try await storageManager.save(log, withId: log.id, inCollection: "logs")
            }
        } catch {
            os_log("Failed to save logs: %{public}s", log: osLog, type: .error, error.localizedDescription)
        }
    }
} 
