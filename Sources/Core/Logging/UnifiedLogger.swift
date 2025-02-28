import Foundation
import Combine
import SwiftUI

// MARK: - Logger Protocol
@preconcurrency public protocol Logging: Actor {
    func log(_ level: LogLevel, _ message: String, category: LogCategory, file: String, function: String, line: Int) async
    func debug(_ message: String, category: LogCategory, file: String, function: String, line: Int) async
    func info(_ message: String, category: LogCategory, file: String, function: String, line: Int) async
    func warning(_ message: String, category: LogCategory, file: String, function: String, line: Int) async
    func error(_ message: String, category: LogCategory, file: String, function: String, line: Int) async
    func critical(_ message: String, category: LogCategory, file: String, function: String, line: Int) async
    func clearLogs() async
}

// MARK: - Logger Implementation
@MainActor
public final class UnifiedLogger: ObservableObject, Logging {
    // MARK: - Published Properties
    @Published public private(set) var logs: [LogEntry] = []
    
    // MARK: - Private Properties
    private let storage: StorageManaging
    private let maxLogCount = 1000
    private let queue = DispatchQueue(label: "com.yeelightcontrol.logger", qos: .utility)
    
    // MARK: - Constants
    private enum Constants {
        static let logsKey = "app_logs"
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedLogger()
    
    // MARK: - Initialization
    public init(services: ServiceContainer = .shared) {
        self.storage = services.storage
        loadLogs()
    }
    
    // MARK: - Public Methods
    public func log(_ level: LogLevel, _ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) async {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            category: category,
            file: file,
            function: function,
            line: line
        )
        
        await addLogEntry(entry)
    }
    
    public func debug(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) async {
        await log(.debug, message, category: category, file: file, function: function, line: line)
    }
    
    public func info(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) async {
        await log(.info, message, category: category, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) async {
        await log(.warning, message, category: category, file: file, function: function, line: line)
    }
    
    public func error(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) async {
        await log(.error, message, category: category, file: file, function: function, line: line)
    }
    
    public func critical(_ message: String, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) async {
        await log(.critical, message, category: category, file: file, function: function, line: line)
    }
    
    public func clearLogs() async {
        logs.removeAll()
        await saveLogs()
    }
    
    // MARK: - Private Methods
    private func addLogEntry(_ entry: LogEntry) async {
        logs.append(entry)
        if logs.count > maxLogCount {
            logs.removeFirst()
        }
        await saveLogs()
    }
    
    private func loadLogs() {
        Task {
            do {
                if let data = try await storage.readData(fromFile: Constants.logsKey) {
                    let decoder = JSONDecoder()
                    let loadedLogs = try decoder.decode([LogEntry].self, from: data)
                    await MainActor.run {
                        logs = loadedLogs
                    }
                }
            } catch {
                print("Failed to load logs: \(error)")
            }
        }
    }
    
    private func saveLogs() async {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(logs)
            try await storage.writeData(data, toFile: Constants.logsKey)
        } catch {
            print("Failed to save logs: \(error)")
        }
    }
} 