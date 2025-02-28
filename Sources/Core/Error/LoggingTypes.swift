import Foundation

public enum LogCategory: String, Codable {
    case system
    case network
    case device
    case scene
    case effect
    case automation
    case security
    case analytics
    case background
    case error
}

public enum LogLevel: String, Codable {
    case debug
    case info
    case warning
    case error
    case critical
}

public struct LogEntry: Codable {
    public let timestamp: Date
    public let category: LogCategory
    public let level: LogLevel
    public let message: String
    
    public init(timestamp: Date = Date(), category: LogCategory, level: LogLevel, message: String) {
        self.timestamp = timestamp
        self.category = category
        self.level = level
        self.message = message
    }
} 