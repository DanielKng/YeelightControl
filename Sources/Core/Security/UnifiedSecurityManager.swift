import Foundation
import Security
import CryptoKit
import LocalAuthentication
import Combine
import SwiftUI

// MARK: - Security Managing Protocol
protocol SecurityManaging {
    func encrypt(_ data: Data, key: String) throws -> Data
    func decrypt(_ data: Data, key: String) throws -> Data
    func hash(_ string: String) -> String
    func generateKey() -> String
    
    func saveToKeychain(_ data: Data, forKey key: String) throws
    func loadFromKeychain(forKey key: String) throws -> Data
    func removeFromKeychain(forKey key: String) throws
    
    func authenticate(reason: String) async throws -> Bool
    func checkBiometryType() -> BiometryType
}

// MARK: - Biometry Type
enum BiometryType {
    case none
    case touchID
    case faceID
    
    var name: String {
        switch self {
        case .none: return "None"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        }
    }
}

// MARK: - Security Error
enum SecurityError: Error {
    case invalidKey
    case invalidData
    case keychainSaveFailed(OSStatus)
    case keychainLoadFailed(OSStatus)
    case keychainDeleteFailed(OSStatus)
    case accessControlCreationFailed(String)
    case biometricsNotAvailable
    case authenticationFailed
}

@MainActor
public final class UnifiedSecurityManager: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var biometricType: LABiometryType = .none
    @Published public private(set) var isBiometricsAvailable = false
    
    // MARK: - Private Properties
    private let services: BaseServiceContainer
    private let context = LAContext()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private struct Configuration {
        var keychainAccessGroup: String?
        var useAccessControl = true
        var useBiometricProtection = true
        var minimumKeyLength = 32
    }
    
    private let config = Configuration()
    
    // MARK: - Constants
    private enum Constants {
        static let keychainService = "com.yeelight.control"
        static let biometricReason = "Authenticate to access Yeelight Control"
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedSecurityManager()
    
    // MARK: - Initialization
    public init(services: BaseServiceContainer = .shared) {
        self.services = services
        checkBiometricAvailability()
    }
    
    // MARK: - Encryption Methods
    func encrypt(_ data: Data, key: String) throws -> Data {
        guard let keyData = key.data(using: .utf8) else {
            throw SecurityError.invalidKey
        }
        
        let symmetricKey = SymmetricKey(data: keyData)
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
        return sealedBox.combined ?? Data()
    }
    
    func decrypt(_ data: Data, key: String) throws -> Data {
        guard let keyData = key.data(using: .utf8) else {
            throw SecurityError.invalidKey
        }
        
        let symmetricKey = SymmetricKey(data: keyData)
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
    
    func hash(_ string: String) -> String {
        let inputData = Data(string.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func generateKey() -> String {
        var bytes = [UInt8](repeating: 0, count: config.minimumKeyLength)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }
    
    // MARK: - Keychain Methods
    func saveToKeychain(_ data: Data, forKey key: String) throws {
        var query = createKeychainQuery(forKey: key)
        query[kSecValueData as String] = data
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw SecurityError.keychainSaveFailed(status)
        }
        
        print("Saved data to keychain for key: \(key)")
    }
    
    func loadFromKeychain(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw SecurityError.keychainLoadFailed(status)
        }
        
        guard let data = result as? Data else {
            throw SecurityError.invalidData
        }
        
        return data
    }
    
    func removeFromKeychain(forKey key: String) throws {
        let query = createKeychainQuery(forKey: key)
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SecurityError.keychainDeleteFailed(status)
        }
        
        print("Removed data from keychain for key: \(key)")
    }
    
    // MARK: - Authentication Methods
    public func authenticate() async throws {
        guard isBiometricsAvailable else {
            throw SecurityError.biometricsNotAvailable
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: Constants.biometricReason) { success, error in
                Task { @MainActor in
                    if success {
                        self.isAuthenticated = true
                        continuation.resume()
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: SecurityError.authenticationFailed)
                    }
                }
            }
        }
    }
    
    func checkBiometryType() -> BiometryType {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        let biometryType = context.biometryType
        switch biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        default:
            // Handle any future biometry types
            return .none
        }
    }
    
    // MARK: - Private Methods
    private func checkBiometricAvailability() {
        var error: NSError?
        isBiometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometricType = context.biometryType
    }
    
    private func createKeychainQuery(forKey key: String) -> [String: Any] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        return query
    }
}

// MARK: - Constants
extension UnifiedSecurityManager {
    static let logCategory = Core_LogCategory.security
} 