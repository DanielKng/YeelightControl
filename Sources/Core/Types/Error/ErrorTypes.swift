import Foundation

public enum NetworkError: LocalizedError, Hashable {
    case invalidURL
    case invalidResponse
    case invalidData
    case connectionFailed
    case timeout
    case unauthorized
    case serverError
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .invalidData: return "Invalid data received"
        case .connectionFailed: return "Connection failed"
        case .timeout: return "Request timed out"
        case .unauthorized: return "Unauthorized access"
        case .serverError: return "Server error"
        case .unknown: return "Unknown network error"
        }
    }
}

public enum LocationError: LocalizedError, Hashable {
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

public enum ConfigurationError: LocalizedError, Hashable {
    case invalidKey
    case invalidValue
    case serializationFailed
    case persistenceFailed
    case notFound
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidKey: return "Invalid configuration key"
        case .invalidValue: return "Invalid configuration value"
        case .serializationFailed: return "Configuration serialization failed"
        case .persistenceFailed: return "Configuration persistence failed"
        case .notFound: return "Configuration not found"
        case .unknown: return "Unknown configuration error"
        }
    }
}

public enum DeviceError: LocalizedError, Hashable {
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

public enum SecurityError: LocalizedError, Hashable {
    case unauthorized
    case invalidCredentials
    case encryptionFailed
    case decryptionFailed
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .unauthorized: return "Unauthorized access"
        case .invalidCredentials: return "Invalid credentials"
        case .encryptionFailed: return "Encryption failed"
        case .decryptionFailed: return "Decryption failed"
        case .unknown: return "Unknown security error"
        }
    }
}

public enum StorageError: LocalizedError, Hashable {
    case readFailed
    case writeFailed
    case deleteFailed
    case notFound
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .readFailed: return "Storage read failed"
        case .writeFailed: return "Storage write failed"
        case .deleteFailed: return "Storage delete failed"
        case .notFound: return "Storage item not found"
        case .unknown: return "Unknown storage error"
        }
    }
}

public enum PermissionError: LocalizedError, Hashable {
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

public enum EffectError: LocalizedError, Hashable {
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

public enum SceneError: LocalizedError, Hashable {
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

public enum AppError: LocalizedError, Hashable {
    case network(NetworkError)
    case location(LocationError)
    case configuration(ConfigurationError)
    case device(DeviceError)
    case security(SecurityError)
    case storage(StorageError)
    case permission(PermissionError)
    case effect(EffectError)
    case scene(SceneError)
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .network(let error): return error.errorDescription
        case .location(let error): return error.errorDescription
        case .configuration(let error): return error.errorDescription
        case .device(let error): return error.errorDescription
        case .security(let error): return error.errorDescription
        case .storage(let error): return error.errorDescription
        case .permission(let error): return error.errorDescription
        case .effect(let error): return error.errorDescription
        case .scene(let error): return error.errorDescription
        case .unknown: return "Unknown application error"
        }
    }
} 