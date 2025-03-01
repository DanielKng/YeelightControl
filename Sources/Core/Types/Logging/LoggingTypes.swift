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

// MARK: - Log Managing Protocol
public protocol Core_LogManaging {
    /// Logs a message with the specified level
    func log(_ message: String, level: Core_LogLevel, category: Core_LogCategory, file: String, function: String, line: Int)
    
    /// Logs a debug message
    func debug(_ message: String, category: Core_LogCategory, file: String, function: String, line: Int)
    
    /// Logs an info message
    func info(_ message: String, category: Core_LogCategory, file: String, function: String, line: Int)
    
    /// Logs a warning message
    func warning(_ message: String, category: Core_LogCategory, file: String, function: String, line: Int)
    
    /// Logs an error message
    func error(_ message: String, category: Core_LogCategory, file: String, function: String, line: Int)
    
    /// Logs a critical message
    func critical(_ message: String, category: Core_LogCategory, file: String, function: String, line: Int)
    
    /// Gets log entries, optionally filtered by level and limited to a certain number
    func getLogEntries(level: Core_LogLevel?, category: Core_LogCategory?, limit: Int?) -> [Core_LogEntry]
    
    /// Clears all log entries
    func clearLogs()
} 