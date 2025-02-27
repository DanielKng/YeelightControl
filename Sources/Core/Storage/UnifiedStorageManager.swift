import Foundation
import Combine

// MARK: - Storage Managing Protocol
protocol StorageManaging {
    func save<T: Encodable>(_ value: T, forKey key: StorageKey) async throws
    func load<T: Decodable>(forKey key: StorageKey) async throws -> T
    func remove(forKey key: StorageKey) async throws
    func exists(forKey key: StorageKey) -> Bool
    func clear() async throws
}

// MARK: - Storage Keys
enum StorageKey: String, CaseIterable {
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

// MARK: - Storage Manager Implementation
final class UnifiedStorageManager: StorageManaging {
    // MARK: - Private Properties
    private let queue = DispatchQueue(label: "de.knng.app.yeelightcontrol.storage", qos: .userInitiated)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileManager = FileManager.default
    
    // MARK: - Configuration
    private struct Configuration {
        var maxCacheSize: Int = 50 * 1024 * 1024  // 50MB
        var maxBackupCount = 5
        var useEncryption = true
        var compressionEnabled = true
    }
    
    private let config = Configuration()
    
    // MARK: - Initialization
    init() {
        setupDirectories()
        setupCoding()
    }
    
    // MARK: - Public Methods
    func save<T: Encodable>(_ value: T, forKey key: StorageKey) async throws {
        try await queue.run {
            let url = getURL(for: key)
            let data = try encoder.encode(value)
            
            // Create directory if needed
            try createDirectoryIfNeeded(for: key.directory)
            
            // Write data
            try data.write(to: url, options: .atomic)
            
            // Clean up if needed
            if key.directory == .cache {
                try cleanupCacheIfNeeded()
            } else if key.directory == .backups {
                try cleanupBackupsIfNeeded()
            }
        }
    }
    
    func load<T: Decodable>(forKey key: StorageKey) async throws -> T {
        try await queue.run {
            let url = getURL(for: key)
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        }
    }
    
    func remove(forKey key: StorageKey) async throws {
        try await queue.run {
            let url = getURL(for: key)
            try fileManager.removeItem(at: url)
        }
    }
    
    func exists(forKey key: StorageKey) -> Bool {
        queue.sync {
            let url = getURL(for: key)
            return fileManager.fileExists(atPath: url.path)
        }
    }
    
    func clear() async throws {
        try await queue.run {
            for directory in StorageDirectory.allCases {
                let url = directory.url
                let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                for fileURL in contents {
                    try fileManager.removeItem(at: fileURL)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupDirectories() {
        for directory in StorageDirectory.allCases {
            try? createDirectoryIfNeeded(for: directory)
        }
    }
    
    private func setupCoding() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        if config.compressionEnabled {
            encoder.dataEncodingStrategy = .base64
            decoder.dataDecodingStrategy = .base64
        }
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

// MARK: - Storage Errors
enum StorageError: LocalizedError {
    case saveFailed(String)
    case loadFailed(String)
    case notFound
    case invalidData
    case directoryCreationFailed
    case encryptionFailed
    case diskSpaceLow
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let reason):
            return "Failed to save data: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load data: \(reason)"
        case .notFound:
            return "Data not found"
        case .invalidData:
            return "Invalid data format"
        case .directoryCreationFailed:
            return "Failed to create directory"
        case .encryptionFailed:
            return "Failed to encrypt/decrypt data"
        case .diskSpaceLow:
            return "Insufficient disk space"
        }
    }
}

// MARK: - Storage Directory Extension
extension StorageDirectory: CaseIterable {
    static var allCases: [StorageDirectory] {
        [.documents, .cache, .logs, .backups]
    }
} 