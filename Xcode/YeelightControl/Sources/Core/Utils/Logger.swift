import Foundation
import SwiftUI

class Logger: ObservableObject {
    static let shared = Logger()
    
    // MARK: - Configuration
    private let maxFileSize = 10 * 1024 * 1024 // 10MB
    private let maxLogFiles = 5
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    // MARK: - Properties
    @Published private(set) var logs: [LogEntry] = []
    @AppStorage("debugMode") private var debugMode = false
    @AppStorage("logToFile") private var logToFile = false
    @AppStorage("logLevel") private var minimumLogLevel = LogEntry.Level.info.rawValue
    
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.yeelight.logger")
    private let maxMemoryLogs = 1000
    
    // MARK: - File Management
    private var logDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Logs", isDirectory: true)
    }
    
    private var currentLogFileURL: URL? {
        logDirectory?.appendingPathComponent("yeelight.log")
    }
    
    init() {
        setupLogDirectory()
    }
    
    private func setupLogDirectory() {
        guard let logDirectory = logDirectory else { return }
        
        if !fileManager.fileExists(atPath: logDirectory.path) {
            try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        }
    }
    
    func log(_ message: String, level: LogEntry.Level = .info, category: LogEntry.Category = .general, file: String = #file, line: Int = #line, function: String = #function) {
        let entry = LogEntry(
            timestamp: Date(),
            message: message,
            level: level,
            category: category,
            sourceFile: file,
            sourceLine: line,
            sourceFunction: function
        )
        
        guard level.rawValue >= minimumLogLevel else { return }
        if level == .debug && !debugMode { return }
        
        DispatchQueue.main.async {
            self.logs.append(entry)
            self.trimLogsIfNeeded()
        }
        
        if logToFile {
            queue.async { self.writeToFile(entry) }
        }
    }
    
    private func writeToFile(_ entry: LogEntry) {
        guard let url = currentLogFileURL else { return }
        
        let formattedLog = """
        [\(dateFormatter.string(from: entry.timestamp))] [\(entry.level.rawValue.uppercased())] \
        [\(entry.category.rawValue)] \(entry.message) \
        [\(entry.sourceFile):\(entry.sourceLine) \(entry.sourceFunction)]\n
        """
        
        if !fileManager.fileExists(atPath: url.path) {
            try? formattedLog.write(to: url, atomically: true, encoding: .utf8)
        } else {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(formattedLog.data(using: .utf8) ?? Data())
                try? handle.close()
            }
        }
        
        rotateLogFilesIfNeeded()
    }
    
    private func rotateLogFilesIfNeeded() {
        guard let url = currentLogFileURL,
              let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? UInt64,
              size > maxFileSize
        else { return }
        
        guard let logDirectory = logDirectory else { return }
        
        // Rotate existing log files
        for index in (1...maxLogFiles-1).reversed() {
            let oldLog = logDirectory.appendingPathComponent("yeelight.\(index).log")
            let newLog = logDirectory.appendingPathComponent("yeelight.\(index + 1).log")
            try? fileManager.moveItem(at: oldLog, to: newLog)
        }
        
        // Move current log to .1
        let firstRotatedLog = logDirectory.appendingPathComponent("yeelight.1.log")
        try? fileManager.moveItem(at: url, to: firstRotatedLog)
        
        // Remove oldest log if it exists
        let oldestLog = logDirectory.appendingPathComponent("yeelight.\(maxLogFiles).log")
        try? fileManager.removeItem(at: oldestLog)
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
        
        queue.async {
            guard let logDirectory = self.logDirectory else { return }
            try? self.fileManager.removeItem(at: logDirectory)
            self.setupLogDirectory()
        }
    }
    
    private func trimLogsIfNeeded() {
        if logs.count > maxMemoryLogs {
            logs.removeFirst(logs.count - maxMemoryLogs)
        }
    }
}

// MARK: - Models
extension Logger {
    struct LogEntry: Codable, Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: Level
        let category: Category
        let sourceFile: String
        let sourceLine: Int
        let sourceFunction: String
        
        enum Level: String, Codable, CaseIterable {
            case debug, info, warning, error
            
            var color: Color {
                switch self {
                case .debug: return .gray
                case .info: return .blue
                case .warning: return .orange
                case .error: return .red
                }
            }
        }
        
        enum Category: String, Codable, CaseIterable {
            case network, device, scene, automation, general
            
            var icon: String {
                switch self {
                case .network: return "network"
                case .device: return "lightbulb"
                case .scene: return "theatermasks"
                case .automation: return "clock"
                case .general: return "gear"
                }
            }
        }
    }
} 