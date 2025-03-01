import Foundation
import Combine
import SwiftUI

// MARK: - Storage Key
// Core_StorageKey is defined in StorageTypes.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Storage Directory
// Core_StorageDirectory is defined in StorageTypes.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Storage Managing Protocol
// Core_StorageManaging protocol is defined in StorageProtocols.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Storage Error
public enum Core_StorageError: Error {
    case itemNotFound
    case encodingError
    case decodingError
    case fileSystemError
}

// MARK: - Storage Manager Implementation
public actor UnifiedStorageManager: Core_StorageManaging, Core_BaseService {
    private var _isEnabled: Bool = true
    
    nonisolated public var isEnabled: Bool {
        get async {
            await _isEnabled
        }
    }
    
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
    
    public nonisolated func save<T: Codable>(_ value: T, forKey key: String) async throws {
        try await saveInternal(value, forKey: key)
    }
    
    private func saveInternal<T: Encodable>(_ value: T, forKey key: String) throws {
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
        
        do {
            let data = try encoder.encode(value)
            let fileURL = storageURL(for: key)
            
            try data.write(to: fileURL)
        } catch {
            throw Core_StorageError.encodingError
        }
    }
    
    public nonisolated func load<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T? {
        do {
            return try await loadInternal(forKey: key)
        } catch Core_StorageError.itemNotFound {
            return nil
        } catch {
            throw error
        }
    }
    
    private func loadInternal<T: Decodable>(forKey key: String) throws -> T {
        // Handle simple types directly from UserDefaults
        if T.self == String.self {
            guard let value = userDefaults.string(forKey: key) as? T else {
                throw Core_StorageError.itemNotFound
            }
            return value
        }
        
        if T.self == Int.self {
            return userDefaults.integer(forKey: key) as! T
        }
        
        if T.self == Double.self {
            return userDefaults.double(forKey: key) as! T
        }
        
        if T.self == Bool.self {
            return userDefaults.bool(forKey: key) as! T
        }
        
        if T.self == Date.self {
            guard let value = userDefaults.object(forKey: key) as? T else {
                throw Core_StorageError.itemNotFound
            }
            return value
        }
        
        // For complex objects, load from file
        let fileURL = storageURL(for: key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw Core_StorageError.itemNotFound
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(T.self, from: data)
        } catch {
            throw Core_StorageError.decodingError
        }
    }
    
    public nonisolated func remove(forKey key: String) async throws {
        try await removeInternal(forKey: key)
    }
    
    private func removeInternal(forKey key: String) throws {
        // Remove from UserDefaults
        userDefaults.removeObject(forKey: key)
        
        // Remove file if it exists
        let fileURL = storageURL(for: key)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    public nonisolated func clear() async throws {
        try await clearInternal()
    }
    
    private func clearInternal() throws {
        // Clear UserDefaults (domain-specific)
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleIdentifier)
        }
        
        // Clear all files in storage directory
        let storageDirectory = documentsDirectory.appendingPathComponent("Storage", isDirectory: true)
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
            
            for url in contents {
                try fileManager.removeItem(at: url)
            }
        } catch {
            throw Core_StorageError.fileSystemError
        }
    }
    
    // MARK: - Helper Methods
    
    private func storageURL(for key: String) -> URL {
        let sanitizedKey = key.replacingOccurrences(of: "/", with: "_")
        return documentsDirectory.appendingPathComponent("Storage/\(sanitizedKey).json")
    }
} 
