import Foundation
import Combine
import SwiftUI

// MARK: - Error Handling Protocol
@preconcurrency protocol ErrorHandling: Actor {
    var lastError: AppError? { get }
    nonisolated var errorUpdates: AnyPublisher<AppError, Never> { get }
    
    func handle(_ error: Error) async
    func handle(_ appError: AppError) async
    func clearError() async
}

// MARK: - Error Record
public struct ErrorRecord: Codable, Hashable {
    public let error: Error
    public let timestamp: Date
    
    public init(error: Error, timestamp: Date = Date()) {
        self.error = error
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case error
        case timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let errorString = try container.decode(String.self, forKey: .error)
        error = NSError(domain: "YeelightControl", code: 0, userInfo: [NSLocalizedDescriptionKey: errorString])
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(error.localizedDescription, forKey: .error)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    public static func == (lhs: ErrorRecord, rhs: ErrorRecord) -> Bool {
        return lhs.error.localizedDescription == rhs.error.localizedDescription &&
               lhs.timestamp == rhs.timestamp
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(error.localizedDescription)
        hasher.combine(timestamp)
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
public actor UnifiedErrorHandler: ErrorHandling {
    private let services: BaseServiceContainer
    private let errorSubject = PassthroughSubject<AppError, Never>()
    private(set) var lastError: AppError?
    
    public init(services: BaseServiceContainer = .shared) {
        self.services = services
    }
    
    public nonisolated var errorUpdates: AnyPublisher<AppError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    public func handle(_ error: Error) async {
        if let appError = error as? AppError {
            await handle(appError)
        } else {
            // Convert to AppError.unknown
            let appError = AppError.unknown
            lastError = appError
            services.logger.error(error.localizedDescription, category: .error)
            errorSubject.send(appError)
        }
    }
    
    public func handle(_ appError: AppError) async {
        lastError = appError
        services.logger.error(appError.errorDescription ?? "Unknown error", category: .error)
        errorSubject.send(appError)
    }
    
    public func clearError() async {
        lastError = nil
    }
}

// MARK: - View Extension
public extension View {
    func handleError(_ error: Binding<AppError?>) -> some View {
        alert(item: error) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.errorDescription ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
} 