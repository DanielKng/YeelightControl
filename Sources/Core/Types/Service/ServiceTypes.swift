import Foundation

// MARK: - Service Status

/// Represents the status of a service
public enum Core_ServiceStatus: String, Codable {
    case active
    case inactive
    case error
    case initializing
}

// MARK: - Service Type

/// Represents the type of a service
public enum Core_ServiceType: String, Codable {
    case analytics
    case configuration
    case device
    case effect
    case error
    case location
    case logging
    case network
    case notification
    case permission
    case scene
    case security
    case state
    case storage
    case theme
    case yeelight
} 