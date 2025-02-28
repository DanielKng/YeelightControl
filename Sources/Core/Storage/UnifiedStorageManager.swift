import Foundation
import Combine
import SwiftUI

// MARK: - Storage Managing Protocol
@preconcurrency public protocol StorageManaging: Actor {
    func save<T: Encodable>(_ value: T, forKey key: StorageKey) async throws
    func load<T: Decodable>(forKey key: StorageKey) async throws -> T
    func remove(forKey key: StorageKey) async throws
    nonisolated func exists(forKey key: StorageKey) -> Bool
    func clear() async throws
}

// MARK: - Storage Keys
public enum StorageKey: String, CaseIterable {
    case devices
    case rooms
    case automations
    case effects
    case configuration
    case errorHistory
    case deviceState
    case customScene
    case backup
    case theme
    case scenes
    case analytics
    
    var fileName: String {
        switch self {
        case .devices:
            return "devices.json"
        case .rooms:
            return "rooms.json"
        case .automations:
            return "automations.json"
        case .effects:
            return "effects.json"
        case .configuration:
            return "config.json"
        case .errorHistory:
            return "errors.json"
        case .deviceState(let deviceId):
            return "device_state_\(deviceId).json"
        case .customScene(let name):
            return "scene_\(name).json"
        case .backup(let date):
            return "backup_\(date).json"
        case .theme:
            return "theme.json"
        case .scenes:
            return "scenes.json"
        case .analytics:
            return "analytics.json"
        }
    }
    
    var directory: StorageDirectory {
        switch self {
        case .devices, .rooms, .automations, .effects, .configuration, .theme:
            return .documents
        case .errorHistory:
            return .logs
        case .deviceState:
            return .cache
        case .customScene:
            return .documents
        case .backup:
            return .backups
        case .scenes, .effects:
            return .documents
        case .analytics:
            return .cache
        }
    }
}

// MARK: - Storage Directory
enum StorageDirectory: String {
    case documents = "Documents"
    case cache = "Cache"
    case logs = "Logs"
    case backups = "Backups"
    
    var url: URL {
        let baseURL: URL
        switch self {
        case .documents:
            baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        case .cache:
            baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        case .logs, .backups:
            baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(rawValue)
        }
        return baseURL
    }
}

@MainActor
public final class UnifiedStorageManager: ObservableObject, StorageManaging {
    // MARK: - Published Properties
    @Published public private(set) var lastSaveDate: Date?
    @Published public private(set) var lastLoadDate: Date?
    @Published public private(set) var isLoading = false
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "com.yeelightcontrol.storage", qos: .utility)
    
    // MARK: - Constants
    private struct Constants {
        static let storageDirectory = "YeelightControl"
        static let backupDirectory = "Backups"
        static let fileExtension = "json"
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedStorageManager()
    
    private init() {
        setupStorage()
        setupEncoder()
    }
    
    // MARK: - Public Methods
    public func save<T: Encodable>(_ value: T, forKey key: StorageKey) async throws {
        try await Task.detached {
            let url = self.getURL(for: key)
            let data = try self.encoder.encode(value)
            
            // Create directory if needed
            try self.createDirectoryIfNeeded(for: key.directory)
            
            // Write data
            try data.write(to: url, options: .atomic)
            
            // Clean up if needed
            if key.directory == .cache {
                try self.cleanupCacheIfNeeded()
            } else if key.directory == .backups {
                try self.cleanupBackupsIfNeeded()
            }
            
            await MainActor.run {
                self.lastSaveDate = Date()
            }
        }.value
    }
    
    public func load<T: Decodable>(forKey key: StorageKey) async throws -> T {
        try await Task.detached {
            let url = self.getURL(for: key)
            let data = try Data(contentsOf: url)
            let value = try self.decoder.decode(T.self, from: data)
            
            await MainActor.run {
                self.lastLoadDate = Date()
            }
            
            return value
        }.value
    }
    
    public func remove(forKey key: StorageKey) async throws {
        try await Task.detached {
            let url = self.getURL(for: key)
            try self.fileManager.removeItem(at: url)
        }.value
    }
    
    public nonisolated func exists(forKey key: StorageKey) -> Bool {
        let url = getURL(for: key)
        return fileManager.fileExists(atPath: url.path)
    }
    
    public func clear() async throws {
        try await Task.detached {
            for directory in StorageDirectory.allCases {
                let url = directory.url
                let contents = try self.fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                for fileURL in contents {
                    try self.fileManager.removeItem(at: fileURL)
                }
            }
        }.value
    }
    
    public func createBackup() async throws -> URL {
        let backupURL = try getBackupURL()
        let storageURL = try getStorageURL()
        
        // Create backup directory if needed
        try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)
        
        // Create backup folder with timestamp
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupFolderURL = backupURL.appendingPathComponent(timestamp)
        try fileManager.createDirectory(at: backupFolderURL, withIntermediateDirectories: true)
        
        // Copy all files to backup
        let contents = try fileManager.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: nil)
        try contents.forEach { sourceURL in
            let destinationURL = backupFolderURL.appendingPathComponent(sourceURL.lastPathComponent)
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
        
        return backupFolderURL
    }
    
    public func restoreFromBackup(_ backupURL: URL) async throws {
        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw StorageError.backupNotFound
        }
        
        let storageURL = try getStorageURL()
        
        // Clear current storage
        try clear()
        
        // Copy backup files to storage
        let contents = try fileManager.contentsOfDirectory(at: backupURL, includingPropertiesForKeys: nil)
        try contents.forEach { sourceURL in
            let destinationURL = storageURL.appendingPathComponent(sourceURL.lastPathComponent)
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }
    }
    
    // MARK: - Private Methods
    private func setupStorage() {
        do {
            let url = try getStorageURL()
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            print("Failed to setup storage: \(error)")
        }
    }
    
    private func setupEncoder() {
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        decoder.dateDecodingStrategy = .iso8601
    }
    
    private func getStorageURL() throws -> URL {
        try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(Constants.storageDirectory)
    }
    
    private func getBackupURL() throws -> URL {
        try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(Constants.storageDirectory)
            .appendingPathComponent(Constants.backupDirectory)
    }
    
    private func getURL(for key: StorageKey) -> URL {
        key.directory.url.appendingPathComponent(key.fileName)
    }
    
    private func createDirectoryIfNeeded(for directory: StorageDirectory) throws {
        let url = directory.url
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    private func cleanupCacheIfNeeded() throws {
        let cacheURL = StorageDirectory.cache.url
        let contents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey])
        
        var totalSize = 0
        for fileURL in contents {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            totalSize += attributes[.size] as? Int ?? 0
        }
        
        if totalSize > config.maxCacheSize {
            // Remove oldest files until under limit
            let sortedFiles = contents.sorted { file1, file2 in
                let date1 = try? fileManager.attributesOfItem(atPath: file1.path)[.creationDate] as? Date
                let date2 = try? fileManager.attributesOfItem(atPath: file2.path)[.creationDate] as? Date
                return date1 ?? Date() < date2 ?? Date()
            }
            
            for fileURL in sortedFiles {
                try fileManager.removeItem(at: fileURL)
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                totalSize -= attributes[.size] as? Int ?? 0
                
                if totalSize <= config.maxCacheSize {
                    break
                }
            }
        }
    }
    
    private func cleanupBackupsIfNeeded() throws {
        let backupsURL = StorageDirectory.backups.url
        let contents = try fileManager.contentsOfDirectory(at: backupsURL, includingPropertiesForKeys: [.creationDateKey])
        
        if contents.count > config.maxBackupCount {
            let sortedFiles = contents.sorted { file1, file2 in
                let date1 = try? fileManager.attributesOfItem(atPath: file1.path)[.creationDate] as? Date
                let date2 = try? fileManager.attributesOfItem(atPath: file2.path)[.creationDate] as? Date
                return date1 ?? Date() < date2 ?? Date()
            }
            
            for fileURL in sortedFiles.prefix(contents.count - config.maxBackupCount) {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }
}

// MARK: - Storage Directory Extension
extension StorageDirectory: CaseIterable {
    static var allCases: [StorageDirectory] {
        [.documents, .cache, .logs, .backups]
    }
} 