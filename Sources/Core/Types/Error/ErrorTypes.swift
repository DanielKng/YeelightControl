import Foundation

// Create typealiases to disambiguate types
// Removing duplicate typealias declarations that are already defined elsewhere
// public typealias CoreNetworkError = Core_NetworkError
// public typealias CoreConfigurationError = Core_ConfigurationError
// public typealias CoreSecurityError = Core_SecurityError
// public typealias CoreStorageError = Core_StorageError

public typealias CoreLocationError = Core_LocationError
public typealias CoreDeviceError = Core_DeviceError
public typealias CorePermissionError = Core_PermissionError
public typealias CoreEffectError = Core_EffectError
public typealias CoreSceneError = Core_SceneError
public typealias CoreAppError = Core_AppError
public typealias CoreYeelightError = Core_YeelightError

// MARK: - Core Error Types

// These are defined in other files, so we don't redefine them here:
// Core_NetworkError
// Core_SecurityError
// Core_StorageError
// Core_ConfigurationError
// Core_YeelightError

public enum Core_LocationError: LocalizedError, Hashable {
    case unauthorized
    case servicesDisabled
    case invalidCoordinates
    case geocodingFailed
    case monitoringFailed
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .unauthorized: return "Location access unauthorized"
        case .servicesDisabled: return "Location services are disabled"
        case .invalidCoordinates: return "Invalid coordinates"
        case .geocodingFailed: return "Geocoding failed"
        case .monitoringFailed: return "Location monitoring failed"
        case .unknown: return "Unknown location error"
        }
    }
}

public enum Core_DeviceError: LocalizedError, Hashable {
    case notFound
    case deviceNotFound
    case connectionFailed
    case commandFailed
    case invalidState
    case unsupportedFeature
    case timeout
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .notFound: return "Device not found"
        case .deviceNotFound: return "Device not found"
        case .connectionFailed: return "Device connection failed"
        case .commandFailed: return "Device command failed"
        case .invalidState: return "Invalid device state"
        case .unsupportedFeature: return "Unsupported device feature"
        case .timeout: return "Device operation timed out"
        case .unknown: return "Unknown device error"
        }
    }
}

public enum Core_PermissionError: LocalizedError, Hashable {
    case denied
    case restricted
    case notDetermined
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .denied: return "Permission denied"
        case .restricted: return "Permission restricted"
        case .notDetermined: return "Permission not determined"
        case .unknown: return "Unknown permission error"
        }
    }
}

public enum Core_EffectError: LocalizedError, Hashable {
    case invalidParameters
    case executionFailed
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidParameters: return "Invalid effect parameters"
        case .executionFailed: return "Effect execution failed"
        case .unknown: return "Unknown effect error"
        }
    }
}

public enum Core_SceneError: LocalizedError, Hashable {
    case invalidDevices
    case activationFailed
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidDevices: return "Invalid scene devices"
        case .activationFailed: return "Scene activation failed"
        case .unknown: return "Unknown scene error"
        }
    }
}

// Add SourceLocation struct
public struct SourceLocation: Hashable, Codable {
    public let file: String
    public let function: String
    public let line: Int
    
    public init(file: String = #file, function: String = #function, line: Int = #line) {
        self.file = file
        self.function = function
        self.line = line
    }
}

public enum Core_AppError: LocalizedError, Hashable, Identifiable {
    case configuration(Core_ConfigurationError)
    case storage(Core_StorageError)
    case network(Core_NetworkError)
    case security(Core_SecurityError)
    case yeelight(Core_YeelightError)
    case general(String)
    case location(Core_LocationError)
    case device(Core_DeviceError)
    case permission(Core_PermissionError)
    case effect(Core_EffectError)
    case scene(Core_SceneError)
    case unknown(Error? = nil, SourceLocation? = nil)
    
    public var sourceLocation: SourceLocation {
        switch self {
        case .unknown(_, let location):
            return location ?? SourceLocation()
        default:
            return SourceLocation()
        }
    }
    
    public func with(sourceLocation: SourceLocation) -> Core_AppError {
        switch self {
        case .unknown(let error, _):
            return .unknown(error, sourceLocation)
        case .configuration(let error):
            return .configuration(error)
        case .storage(let error):
            return .storage(error)
        case .network(let error):
            return .network(error)
        case .security(let error):
            return .security(error)
        case .yeelight(let error):
            return .yeelight(error)
        case .general(let message):
            return .general(message)
        case .location(let error):
            return .location(error)
        case .device(let error):
            return .device(error)
        case .permission(let error):
            return .permission(error)
        case .effect(let error):
            return .effect(error)
        case .scene(let error):
            return .scene(error)
        }
    }
    
    public var id: String {
        switch self {
        case .configuration(let error):
            return "config-\(error.hashValue)"
        case .storage(let error):
            return "storage-\(error.hashValue)"
        case .network(let error):
            return "network-\(error.hashValue)"
        case .security(let error):
            return "security-\(error.hashValue)"
        case .yeelight(let error):
            return "yeelight-\(error.hashValue)"
        case .general(let message):
            return "general-\(message.hashValue)"
        case .location(let error):
            return "location-\(error.hashValue)"
        case .device(let error):
            return "device-\(error.hashValue)"
        case .permission(let error):
            return "permission-\(error.hashValue)"
        case .effect(let error):
            return "effect-\(error.hashValue)"
        case .scene(let error):
            return "scene-\(error.hashValue)"
        case .unknown(let error, _):
            return "unknown-\(error?.localizedDescription.hashValue ?? 0)"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .configuration(let error):
            return error.localizedDescription
        case .storage(let error):
            return error.localizedDescription
        case .network(let error):
            return error.localizedDescription
        case .security(let error):
            return error.localizedDescription
        case .yeelight(let error):
            return error.localizedDescription
        case .general(let message):
            return message
        case .location(let error):
            return "Location error: \(error)"
        case .device(let error):
            return "Device error: \(error)"
        case .permission(let error):
            return "Permission error: \(error)"
        case .effect(let error):
            return "Effect error: \(error)"
        case .scene(let error):
            return "Scene error: \(error)"
        case .unknown(let error, _):
            return error?.localizedDescription ?? "Unknown error occurred"
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Core_AppError, rhs: Core_AppError) -> Bool {
        return lhs.id == rhs.id
    }
} 