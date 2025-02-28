import Foundation

// MARK: - Network Errors
public enum NetworkError: LocalizedError {
    case deviceNotFound
    case connectionFailed
    case invalidResponse
    case timeout
    case networkUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Device not found"
        case .connectionFailed:
            return "Failed to connect to device"
        case .invalidResponse:
            return "Invalid response from device"
        case .timeout:
            return "Connection timed out"
        case .networkUnavailable:
            return "Network is unavailable"
        }
    }
}

// MARK: - Scene Errors
public enum SceneError: LocalizedError {
    case invalidScene
    case sceneNotFound
    case activationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidScene:
            return "Invalid scene configuration"
        case .sceneNotFound:
            return "Scene not found"
        case .activationFailed:
            return "Failed to activate scene"
        }
    }
}

// MARK: - Effect Errors
public enum EffectError: LocalizedError {
    case invalidEffect
    case effectNotFound
    case activationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidEffect:
            return "Invalid effect configuration"
        case .effectNotFound:
            return "Effect not found"
        case .activationFailed:
            return "Failed to activate effect"
        }
    }
}

// MARK: - Location Errors
public enum LocationError: LocalizedError {
    case permissionDenied
    case locationDisabled
    case invalidLocation
    case geofencingNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied"
        case .locationDisabled:
            return "Location services are disabled"
        case .invalidLocation:
            return "Invalid location data"
        case .geofencingNotAvailable:
            return "Geofencing is not available"
        }
    }
}

// MARK: - Background Errors
public enum BackgroundError: LocalizedError {
    case taskRegistrationFailed
    case backgroundRefreshDisabled
    case executionLimitExceeded
    
    public var errorDescription: String? {
        switch self {
        case .taskRegistrationFailed:
            return "Failed to register background task"
        case .backgroundRefreshDisabled:
            return "Background refresh is disabled"
        case .executionLimitExceeded:
            return "Background execution time limit exceeded"
        }
    }
}

// MARK: - Configuration Errors
public enum ConfigurationError: LocalizedError {
    case invalidConfiguration
    case missingRequiredValue
    case invalidFormat
    
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid configuration"
        case .missingRequiredValue:
            return "Missing required configuration value"
        case .invalidFormat:
            return "Invalid configuration format"
        }
    }
}

// MARK: - Storage Errors
public enum StorageError: LocalizedError {
    case saveFailed
    case loadFailed
    case notFound
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .notFound:
            return "Data not found"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

// MARK: - Device Errors
public enum DeviceError: LocalizedError {
    case connectionFailed
    case commandFailed
    case invalidState
    case unsupportedOperation
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to device"
        case .commandFailed:
            return "Failed to execute command"
        case .invalidState:
            return "Invalid device state"
        case .unsupportedOperation:
            return "Operation not supported by device"
        }
    }
}

// MARK: - Automation Errors
public enum AutomationError: LocalizedError {
    case invalidTrigger
    case invalidAction
    case executionFailed
    case schedulingFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidTrigger:
            return "Invalid automation trigger"
        case .invalidAction:
            return "Invalid automation action"
        case .executionFailed:
            return "Failed to execute automation"
        case .schedulingFailed:
            return "Failed to schedule automation"
        }
    }
}

// MARK: - State Errors
public enum StateError: LocalizedError {
    case invalidTransition
    case inconsistentState
    case updateFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidTransition:
            return "Invalid state transition"
        case .inconsistentState:
            return "Inconsistent state detected"
        case .updateFailed:
            return "Failed to update state"
        }
    }
} 