import Foundation
import Combine
import SwiftUI

// MARK: - Error Handling Protocol
public protocol ErrorHandling {
    var lastError: AppError? { get }
    var errorUpdates: AnyPublisher<AppError, Never> { get }
    
    func handle(_ error: Error)
    func handle(_ error: AppError)
    func clearError()
}

// MARK: - Error Record
private struct ErrorRecord: Codable {
    let timestamp: Date
    let severity: ErrorSeverity
    let message: String
    let category: LogCategory
    let file: String
    let function: String
    let line: Int
    
    init(timestamp: Date = Date(),
         severity: ErrorSeverity,
         message: String,
         category: LogCategory,
         file: String = #file,
         function: String = #function,
         line: Int = #line) {
        self.timestamp = timestamp
        self.severity = severity
        self.message = message
        self.category = category
        self.file = file
        self.function = function
        self.line = line
    }
}

// MARK: - Error Severity
public enum ErrorSeverity: String, Codable {
    case debug
    case info
    case warning
    case error
    case critical
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        case .debug: return "ladybug"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .yellow
        case .error: return .red
        case .critical: return .purple
        case .debug: return .gray
        }
    }
}

// MARK: - AppError Extensions
extension AppError: Identifiable {
    public var id: String {
        switch self {
        case .network(let error): return "network-\(error)"
        case .location(let error): return "location-\(error)"
        case .configuration(let error): return "config-\(error)"
        case .device(let error): return "device-\(error)"
        case .security(let error): return "security-\(error)"
        case .storage(let error): return "storage-\(error)"
        case .permission(let error): return "permission-\(error)"
        case .effect(let error): return "effect-\(error)"
        case .scene(let error): return "scene-\(error)"
        case .unknown: return "unknown"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .network(let error): return "Network error: \(error)"
        case .location(let error): return "Location error: \(error)"
        case .configuration(let error): return "Configuration error: \(error)"
        case .device(let error): return "Device error: \(error)"
        case .security(let error): return "Security error: \(error)"
        case .storage(let error): return "Storage error: \(error)"
        case .permission(let error): return "Permission error: \(error)"
        case .effect(let error): return "Effect error: \(error)"
        case .scene(let error): return "Scene error: \(error)"
        case .unknown: return "Unknown error occurred"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .network: return "Check your internet connection and try again."
        case .location: return "Check location permissions in Settings and try again."
        case .configuration: return "Try resetting app settings to defaults."
        case .device: return "Make sure the device is powered on and connected to the network."
        case .security: return "Try authenticating again."
        case .storage: return "Check available storage space and try again."
        case .permission: return "Check app permissions in Settings."
        case .effect: return "Check effect settings and try again."
        case .scene: return "Check scene configuration and try again."
        case .unknown: return "Try restarting the app. If the problem persists, contact support."
        }
    }
    
    public var severity: ErrorSeverity {
        switch self {
        case .network: return .warning
        case .location: return .warning
        case .configuration: return .warning
        case .device: return .warning
        case .security: return .error
        case .storage: return .error
        case .permission: return .warning
        case .effect: return .warning
        case .scene: return .warning
        case .unknown: return .error
        }
    }
}

// MARK: - Error Handler Implementation
@MainActor
public final class UnifiedErrorHandler: ErrorHandling, ObservableObject {
    // MARK: - Properties
    @Published public private(set) var lastError: AppError?
    private let errorSubject = PassthroughSubject<AppError, Never>()
    
    public var errorUpdates: AnyPublisher<AppError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    private let storageManager: StorageManaging
    private var errorRecords: [ErrorRecord] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum Constants {
        static let maxRecords = 1000
        static let errorLogFile = "error_log.json"
    }
    
    // MARK: - Initialization
    public init(services: ServiceContainer) {
        self.storageManager = services.storageManager
        loadErrorLog()
    }
    
    // MARK: - Public Methods
    public func handle(_ error: Error) {
        let appError: AppError
        
        switch error {
        case let networkError as NetworkError:
            appError = .network(networkError)
        case let locationError as LocationError:
            appError = .location(locationError)
        case let configError as ConfigurationError:
            appError = .configuration(configError)
        case let deviceError as DeviceError:
            appError = .device(deviceError)
        case let securityError as SecurityError:
            appError = .security(securityError)
        case let storageError as StorageError:
            appError = .storage(storageError)
        case let permissionError as PermissionError:
            appError = .permission(permissionError)
        case let effectError as EffectError:
            appError = .effect(effectError)
        case let sceneError as SceneError:
            appError = .scene(sceneError)
        default:
            appError = .unknown
        }
        
        handle(appError)
    }
    
    public func handle(_ error: AppError) {
        let category: LogCategory
        switch error {
        case .network: category = .network
        case .location: category = .location
        case .configuration: category = .configuration
        case .device: category = .device
        case .security: category = .security
        case .storage: category = .storage
        case .permission: category = .permission
        case .effect: category = .effect
        case .scene: category = .scene
        case .unknown: category = .general
        }
        
        let record = ErrorRecord(
            severity: error.severity,
            message: error.localizedDescription ?? "Unknown error",
            category: category
        )
        
        errorRecords.append(record)
        if errorRecords.count > Constants.maxRecords {
            errorRecords.removeFirst()
        }
        
        lastError = error
        errorSubject.send(error)
        
        saveErrorLog()
    }
    
    public func clearError() {
        lastError = nil
    }
    
    // MARK: - Private Methods
    private func loadErrorLog() {
        do {
            if let data = try storageManager.readData(fromFile: Constants.errorLogFile) {
                let decoder = JSONDecoder()
                errorRecords = try decoder.decode([ErrorRecord].self, from: data)
            }
        } catch {
            print("Failed to load error log: \(error)")
        }
    }
    
    private func saveErrorLog() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(errorRecords)
            try storageManager.writeData(data, toFile: Constants.errorLogFile)
        } catch {
            print("Failed to save error log: \(error)")
        }
    }
}

// MARK: - View Extension
public extension View {
    func handleError(_ error: Binding<AppError?>) -> some View {
        alert(item: error) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.localizedDescription ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
} 