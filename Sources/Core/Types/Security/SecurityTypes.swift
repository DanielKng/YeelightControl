import Foundation
import Combine

// MARK: - Security Protocols
@preconcurrency public protocol Core_SecurityManaging: Core_BaseService {
    /// Encrypt data
    func encrypt(_ data: Data, withKey key: String) async throws -> Data
    
    /// Decrypt data
    func decrypt(_ data: Data, withKey key: String) async throws -> Data
    
    /// Generate a secure key
    func generateSecureKey() async throws -> String
    
    /// Store a secure value
    func storeSecureValue(_ value: String, forKey key: String) async throws
    
    /// Retrieve a secure value
    func retrieveSecureValue(forKey key: String) async throws -> String?
    
    /// Delete a secure value
    func deleteSecureValue(forKey key: String) async throws
    
    /// Check if biometric authentication is available
    func isBiometricAuthenticationAvailable() async -> Bool
    
    /// Authenticate with biometrics
    func authenticateWithBiometrics(reason: String) async throws -> Bool
}

// MARK: - Security Error

public enum Core_SecurityError: Error {
    case keychainError(status: OSStatus)
    case dataConversionError
    case authenticationFailed
    case userCancelled
    case userFallback
    case biometryNotAvailable
    case biometryNotEnrolled
    case unknown
}

extension Core_SecurityError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .dataConversionError:
            return "Failed to convert data"
        case .authenticationFailed:
            return "Authentication failed"
        case .userCancelled:
            return "Authentication cancelled by user"
        case .userFallback:
            return "User selected fallback authentication"
        case .biometryNotAvailable:
            return "Biometric authentication not available"
        case .biometryNotEnrolled:
            return "Biometric authentication not enrolled"
        case .unknown:
            return "Unknown security error"
        }
    }
}

// MARK: - Security Managing Protocol

public protocol Core_SecurityManaging {
    /// Saves a secure value to the keychain
    func saveSecureValue(_ value: String, for key: String) throws
    
    /// Gets a secure value from the keychain
    func getSecureValue(for key: String) throws -> String
    
    /// Deletes a secure value from the keychain
    func deleteSecureValue(for key: String) throws
    
    /// Clears all secure values from the keychain
    func clearAllSecureValues() throws
    
    /// Checks if the device supports biometric authentication
    func canAuthenticate() -> Bool
    
    /// Authenticates the user using biometrics
    func authenticateUser() async throws
    
    /// Generates a random token of the specified length
    func generateRandomToken(length: Int) -> String
} 