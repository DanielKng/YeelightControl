import Foundation
import Combine

// MARK: - Permission Type

public enum Core_PermissionType: String, Codable {
    case camera
    case microphone
    case photoLibrary
    case location
    case notification
    case bluetooth
}

// MARK: - Permission Status

public enum Core_PermissionStatus: String, Codable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case provisional
    case limited
}

// MARK: - Permission Event

public struct Core_PermissionEvent: Codable {
    public let type: Core_PermissionType
    public let status: Core_PermissionStatus
    public let timestamp: Date
    
    public init(type: Core_PermissionType, status: Core_PermissionStatus, timestamp: Date) {
        self.type = type
        self.status = status
        self.timestamp = timestamp
    }
}

// MARK: - Permission Managing Protocol

@preconcurrency public protocol Core_PermissionManaging: Core_BaseService {
    /// Get the status of a permission
    func getPermissionStatus(_ permission: Core_PermissionType) async -> Core_PermissionStatus
    
    /// Request a permission
    func requestPermission(_ permission: Core_PermissionType) async -> Core_PermissionStatus
    
    /// Check if a permission is granted
    func isPermissionGranted(_ permission: Core_PermissionType) async -> Bool
    
    /// Publisher for permission status updates
    nonisolated var permissionUpdates: AnyPublisher<(Core_PermissionType, Core_PermissionStatus), Never> { get }
} 