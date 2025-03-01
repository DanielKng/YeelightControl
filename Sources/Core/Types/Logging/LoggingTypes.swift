import Foundation

// MARK: - Log Category
public enum Core_LogCategory: String, Codable, CaseIterable {
    case general
    case network
    case storage
    case device
    case scene
    case effect
    case security
    case notification
    case location
    case analytics
    case configuration
    case system
    case error
}

// MARK: - Log Level
public enum Core_LogLevel: String, Codable, Comparable {
    case debug
    case info
    case warning
    case error
    case critical
    
    public static func < (lhs: Core_LogLevel, rhs: Core_LogLevel) -> Bool {
        let order: [Core_LogLevel] = [.debug, .info, .warning, .error, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Log Entry
public struct Core_LogEntry: Codable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let level: Core_LogLevel
    public let message: String
    public let category: Core_LogCategory
    public let file: String
    public let line: Int
    public let function: String
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        level: Core_LogLevel,
        message: String,
        category: Core_LogCategory,
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

// MARK: - Log Managing Protocol
public protocol Core_LogManaging {
    /// Logs a message with the specified level
    func log(_ message: String, level: Core_LogLevel, file: String, function: String, line: Int)
    
    /// Logs a debug message
    func debug(_ message: String, file: String, function: String, line: Int)
    
    /// Logs an info message
    func info(_ message: String, file: String, function: String, line: Int)
    
    /// Logs a warning message
    func warning(_ message: String, file: String, function: String, line: Int)
    
    /// Logs an error message
    func error(_ message: String, file: String, function: String, line: Int)
    
    /// Logs a critical message
    func critical(_ message: String, file: String, function: String, line: Int)
    
    /// Gets log entries, optionally filtered by level and limited to a certain number
    func getLogEntries(level: Core_LogLevel?, limit: Int?) -> [Core_LogEntry]
    
    /// Clears all log entries
    func clearLogs()
} 