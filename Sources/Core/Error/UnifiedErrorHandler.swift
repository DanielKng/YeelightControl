import Foundation
import Combine
import SwiftUI

// MARK: - Error Handling Protocol
// Core_ErrorHandling protocol is defined in ServiceProtocols.swift

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
// Core_AppError already conforms to Identifiable in ErrorTypes.swift
// No need to redefine it here

// MARK: - Error Handler Implementation
public actor UnifiedErrorHandler: Core_ErrorHandling, Core_BaseService {
    private let services: Core_ServiceContainer
    private let errorSubject = PassthroughSubject<Core_AppError, Never>()
    private var _lastError: Core_AppError?
    private var _isEnabled: Bool = true
    
    // MARK: - Core_BaseService
    public nonisolated var isEnabled: Bool {
        get {
            let task = Task { await _isEnabled }
            return (try? task.result.get()) ?? false
        }
    }
    
    public var serviceIdentifier: String {
        return "core.error"
    }
    
    // MARK: - Core_ErrorHandling
    
    nonisolated public var lastError: Core_AppError? {
        get {
            let task = Task { await _lastError }
            return (try? task.result.get())
        }
    }
    
    nonisolated public var errorUpdates: AnyPublisher<Core_AppError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    public func handle(_ appError: Core_AppError) async {
        _lastError = appError
        errorSubject.send(appError)
        
        // Log the error
        let logger = services.logManager
        await logger.log(
            message: appError.localizedDescription,
            level: Core_LogLevel.error.rawValue,
            category: Core_LogCategory.error.rawValue,
            file: appError.sourceLocation.file,
            function: appError.sourceLocation.function,
            line: appError.sourceLocation.line
        )
    }
    
    public init(services: Core_ServiceContainer) {
        self.services = services
    }
    
    public func handle(_ error: Error) async {
        if let appError = error as? Core_AppError {
            await handle(appError)
        } else {
            // Convert to AppError.unknown
            let sourceLocation = SourceLocation()
            let appError = Core_AppError.unknown(error, sourceLocation)
            _lastError = appError
            let logger = services.logManager
            await logger.log(
                message: error.localizedDescription,
                level: Core_LogLevel.error.rawValue,
                category: Core_LogCategory.error.rawValue,
                file: sourceLocation.file,
                function: sourceLocation.function,
                line: sourceLocation.line
            )
            errorSubject.send(appError)
        }
    }
    
    public func clearError() async {
        _lastError = nil
    }
}

// MARK: - View Extension
public extension View {
    func handleError(_ error: Binding<Core_AppError?>) -> some View {
        alert(item: error) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.errorDescription ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
} 