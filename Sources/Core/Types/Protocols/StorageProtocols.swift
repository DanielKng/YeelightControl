import Foundation

// This protocol should be defined only once in the codebase
@preconcurrency public protocol Core_StorageManaging: Core_BaseService {
    nonisolated func save<T: Codable>(_ value: T, forKey key: String) async throws
    nonisolated func load<T: Codable>(forKey key: String) async throws -> T?
    nonisolated func load<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T?
    nonisolated func getAll<T: Codable>(_ type: T.Type, withPrefix prefix: String) async throws -> [T]
    nonisolated func remove(forKey key: String) async throws
    nonisolated func clear() async throws
} 