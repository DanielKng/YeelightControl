import Foundation
import Combine

/// Base protocol for all core services
@preconcurrency public protocol Core_BaseService {
    /// Whether the service is enabled
    nonisolated var isEnabled: Bool { get }
}

/// Protocol for error handling services
@preconcurrency public protocol Core_ErrorHandling: Core_BaseService {
    /// The last error that occurred
    var lastError: Core_AppError? { get }
    
    /// Publisher for error updates
    nonisolated var errorUpdates: AnyPublisher<Core_AppError, Never> { get }
    
    /// Handle an error
    func handle(_ appError: Core_AppError) async
}

/// Protocol for logging services
@preconcurrency public protocol Core_LoggingService: Core_BaseService {
    /// Log a message
    func log(_ message: String, level: Core_LogLevel, category: Core_LogCategory, file: String, function: String, line: Int)
    
    /// Get all logs
    func getAllLogs() async -> [Core_LogEntry]
    
    /// Clear all logs
    func clearLogs() async
}

/// Protocol for network services
@preconcurrency public protocol Core_NetworkManaging: Core_BaseService {
    /// Make a network request
    func request<T: Decodable>(_ endpoint: String, method: String, headers: [String: String]?, body: Data?) async throws -> T
    
    /// Download data from a URL
    func download(_ url: URL) async throws -> Data
}

/// Protocol for device management services
@preconcurrency public protocol Core_DeviceManaging: Core_BaseService {
    /// The list of devices
    nonisolated var devices: [Core_Device] { get }
    
    /// Publisher for device updates
    nonisolated var deviceUpdates: AnyPublisher<[Core_Device], Never> { get }
    
    /// Discover devices
    func discoverDevices() async throws
    
    /// Connect to a device
    func connectToDevice(_ device: Core_Device) async throws
    
    /// Disconnect from a device
    func disconnectFromDevice(_ device: Core_Device) async throws
    
    /// Update a device
    func updateDevice(_ device: Core_Device) async throws
}

/// Protocol for effect management services
@preconcurrency public protocol Core_EffectManaging: Core_BaseService {
    /// Apply an effect to a device
    func applyEffect(_ effect: Core_Effect, to device: Core_Device) async throws
    
    /// Get available effects
    func getAvailableEffects() async -> [Core_Effect]
} 