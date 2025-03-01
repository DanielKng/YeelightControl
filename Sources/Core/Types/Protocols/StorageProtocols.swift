import Foundation

@preconcurrency public protocol Core_StorageManaging: Core_BaseService {
    func save<T: Codable>(_ value: T, forKey key: String) async throws
    func load<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T?
    func remove(forKey key: String) async throws
    func clear() async throws
} 