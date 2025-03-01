import Foundation

// Create typealiases to disambiguate types
public typealias CoreNetworkError = Core_NetworkError
public typealias CoreLocationError = Core_LocationError
public typealias CoreConfigurationError = Core_ConfigurationError
public typealias CoreDeviceError = Core_DeviceError
public typealias CoreSecurityError = Core_SecurityError
public typealias CoreStorageError = Core_StorageError
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
    case connectionFailed
    case commandFailed
    case invalidState
    case unsupportedFeature
    case timeout
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .notFound: return "Device not found"
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

public enum Core_AppError: LocalizedError, Hashable, Identifiable {
    case configuration(CoreConfigurationError)
    case storage(CoreStorageError)
    case network(CoreNetworkError)
    case security(CoreSecurityError)
    case yeelight(CoreYeelightError)
    case general(String)
    
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
        }
    }
} 