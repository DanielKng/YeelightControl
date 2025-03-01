import Foundation

// MARK: - Storage Types
public enum Core_StorageKey: String, Codable, CaseIterable {
    case configuration
    case devices
    case scenes
    case effects
    case logs
    case analytics
    case user
    case settings
}

public enum Core_StorageDirectory: String, Codable, CaseIterable {
    case documents
    case caches
    case temporary
    case applicationSupport
    case library
}

// MARK: - Storage Protocols
@preconcurrency public protocol Core_StorageManaging: Core_BaseService {
    /// Save an object
    func save<T: Encodable>(_ object: T, withId id: String, inCollection collection: String) async throws
    
    /// Get an object
    func get<T: Decodable>(withId id: String, fromCollection collection: String) async throws -> T
    
    /// Get all objects
    func getAll<T: Decodable>(fromCollection collection: String) async throws -> [T]
    
    /// Delete an object
    func delete(withId id: String, fromCollection collection: String) async throws
    
    /// Delete a collection
    func deleteCollection(_ collection: String) async throws
    
    /// Check if an object exists
    func exists(withId id: String, inCollection collection: String) async -> Bool
} 