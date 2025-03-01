import Foundation
import Combine
import SwiftUI

// MARK: - Storage Key
public enum StorageKey: String, CaseIterable {
    case settings
    case deviceState
    case devices
    case rooms
    case automations
    case effects
    case configuration
    case theme
    case errorHistory
    case sceneHistory
    case effectHistory
    case automationHistory
    case customScene
    case backup
}

// MARK: - Storage Directory
public enum StorageDirectory: String, CaseIterable {
    case documents
    case cache
    case temp
    case logs
    case backups
}

// MARK: - Storage Managing Protocol
@preconcurrency public protocol StorageManaging: Actor {
    func save<T: Encodable>(_ value: T, forKey key: StorageKey) async throws
    func load<T: Decodable>(forKey key: StorageKey) async throws -> T
    func remove(forKey key: StorageKey) async throws
    func clear() async throws
    
    func save<T: Encodable>(_ value: T, withId id: String, inCollection collection: String) async throws
    func get<T: Decodable>(withId id: String, fromCollection collection: String) async throws -> T
    func getAll<T: Decodable>(fromCollection collection: String) async throws -> [T]
    func delete(withId id: String, fromCollection collection: String) async throws
    func clearCollection(_ collection: String) async throws
}

// MARK: - Storage Manager Implementation
public actor UnifiedStorageManager: Core_StorageManaging {
    public var isEnabled: Bool = true
    
    public var serviceIdentifier: String {
        "core.storage"
    }
    
    private let userDefaults: UserDefaults
    private let fileManager: FileManager
    private let documentsDirectory: URL
    
    public init(userDefaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.userDefaults = userDefaults
        self.fileManager = fileManager
        
        // Get the documents directory
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Could not access documents directory")
        }
        self.documentsDirectory = documentsDirectory
        
        Task {
            await setupDirectories()
        }
    }
    
    private func setupDirectories() {
        let storageDirectory = documentsDirectory.appendingPathComponent("Storage", isDirectory: true)
        
        do {
            if !fileManager.fileExists(atPath: storageDirectory.path) {
                try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
            }
        } catch {
            print("Error creating storage directory: \(error)")
        }
    }
    
    // MARK: - Core_StorageManaging Protocol
    
    public func save<T: Codable>(_ value: T, forKey key: String) async throws {
        if let simple = value as? String {
            userDefaults.set(simple, forKey: key)
            return
        }
        
        if let simple = value as? Int {
            userDefaults.set(simple, forKey: key)
            return
        }
        
        if let simple = value as? Double {
            userDefaults.set(simple, forKey: key)
            return
        }
        
        if let simple = value as? Bool {
            userDefaults.set(simple, forKey: key)
            return
        }
        
        if let simple = value as? Date {
            userDefaults.set(simple, forKey: key)
            return
        }
        
        // For complex objects, encode to JSON and save to file
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(value)
        let fileURL = storageURL(for: key)
        
        try data.write(to: fileURL)
    }
    
    public func load<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T? {
        // Handle simple types directly from UserDefaults
        if type == String.self {
            return userDefaults.string(forKey: key) as? T
        }
        
        if type == Int.self {
            return userDefaults.integer(forKey: key) as? T
        }
        
        if type == Double.self {
            return userDefaults.double(forKey: key) as? T
        }
        
        if type == Bool.self {
            return userDefaults.bool(forKey: key) as? T
        }
        
        if type == Date.self {
            return userDefaults.object(forKey: key) as? T
        }
        
        // For complex objects, load from file
        let fileURL = storageURL(for: key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(type, from: data)
    }
    
    public func remove(forKey key: String) async throws {
        // Remove from UserDefaults
        userDefaults.removeObject(forKey: key)
        
        // Remove file if it exists
        let fileURL = storageURL(for: key)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    public func clear() async throws {
        // Clear UserDefaults (domain-specific)
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleIdentifier)
        }
        
        // Clear all files in storage directory
        let storageDirectory = documentsDirectory.appendingPathComponent("Storage", isDirectory: true)
        let contents = try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
        
        for url in contents {
            try fileManager.removeItem(at: url)
        }
    }
    
    // MARK: - Helper Methods
    
    private func storageURL(for key: String) -> URL {
        let sanitizedKey = key.replacingOccurrences(of: "/", with: "_")
        return documentsDirectory.appendingPathComponent("Storage/\(sanitizedKey).json")
    }
}

// MARK: - Storage Errors

public enum StorageError: Error {
    case itemNotFound
    case collectionNotFound
    case encodingError
    case decodingError
} 
