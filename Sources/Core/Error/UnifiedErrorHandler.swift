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

// MARK: - App Error Type
public enum AppError: LocalizedError, Identifiable, Codable {
    case network(NetworkError)
    case location(LocationError)
    case background(BackgroundError)
    case configuration(ConfigurationError)
    case storage(StorageError)
    case device(DeviceError)
    case automation(AutomationError)
    case state(StateError)
    case scene(SceneError)
    case effect(EffectError)
    case system(String)
    case unknown(String)
    
    public var id: String {
        switch self {
        case .network(let error): return "network-\(error.localizedDescription)"
        case .location(let error): return "location-\(error.localizedDescription)"
        case .background(let error): return "background-\(error.localizedDescription)"
        case .configuration(let error): return "config-\(error.localizedDescription)"
        case .storage(let error): return "storage-\(error.localizedDescription)"
        case .device(let error): return "device-\(error.localizedDescription)"
        case .automation(let error): return "automation-\(error.localizedDescription)"
        case .state(let error): return "state-\(error.localizedDescription)"
        case .scene(let error): return "scene-\(error.localizedDescription)"
        case .effect(let error): return "effect-\(error.localizedDescription)"
        case .system(let message): return "system-\(message)"
        case .unknown(let message): return "unknown-\(message)"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .network(let error): return error.localizedDescription
        case .location(let error): return error.localizedDescription
        case .background(let error): return error.localizedDescription
        case .configuration(let error): return error.localizedDescription
        case .storage(let error): return error.localizedDescription
        case .device(let error): return error.localizedDescription
        case .automation(let error): return error.localizedDescription
        case .state(let error): return error.localizedDescription
        case .scene(let error): return error.localizedDescription
        case .effect(let error): return error.localizedDescription
        case .system(let message): return message
        case .unknown(let message): return message
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .network:
            return "Check your internet connection and try again."
        case .location:
            return "Check location permissions in Settings and try again."
        case .background:
            return "Try restarting the app."
        case .configuration:
            return "Try resetting app settings to defaults."
        case .storage:
            return "Check available storage space and try again."
        case .device:
            return "Make sure the device is powered on and connected to the network."
        case .automation:
            return "Check automation settings and try again."
        case .state:
            return "Try refreshing the device state."
        case .scene:
            return "Check scene configuration and try again."
        case .effect:
            return "Check effect settings and try again."
        case .system, .unknown:
            return "Try restarting the app. If the problem persists, contact support."
        }
    }
    
    public var severity: ErrorSeverity {
        switch self {
        case .network: return .warning
        case .location: return .warning
        case .background: return .warning
        case .configuration: return .warning
        case .storage: return .error
        case .device: return .warning
        case .automation: return .warning
        case .state: return .warning
        case .scene: return .warning
        case .effect: return .warning
        case .system: return .error
        case .unknown: return .error
        }
    }
}

// MARK: - Error Severity
public enum ErrorSeverity: String, Codable {
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
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .yellow
        case .error: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - Error Handler Implementation
@MainActor
public final class UnifiedErrorHandler: ErrorHandling, ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var lastError: AppError?
    @Published public private(set) var errorHistory: [ErrorRecord] = []
    
    // MARK: - Publishers
    private let errorSubject = PassthroughSubject<AppError, Never>()
    public var errorUpdates: AnyPublisher<AppError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let storage: StorageManaging
    private let analytics: UnifiedAnalyticsManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum Constants {
        static let maxHistoryCount = 100
        static let errorHistoryKey = "error_history"
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedErrorHandler()
    
    // MARK: - Types
    private struct ErrorRecord: Codable {
        let error: AppError
        let timestamp: Date
        let context: [String: String]?
    }
    
    // MARK: - Initialization
    private init() {
        self.storage = UnifiedStorageManager.shared
        self.analytics = UnifiedAnalyticsManager.shared
        loadErrorHistory()
    }
    
    // MARK: - Public Methods
    public func handle(_ error: Error) {
        let appError = convertToAppError(error)
        handle(appError)
    }
    
    public func handle(_ error: AppError) {
        lastError = error
        errorSubject.send(error)
        
        let record = ErrorRecord(
            error: error,
            timestamp: Date(),
            context: ["stack": Thread.callStackSymbols.first ?? ""]
        )
        
        errorHistory.insert(record, at: 0)
        if errorHistory.count > Constants.maxHistoryCount {
            errorHistory.removeLast(errorHistory.count - Constants.maxHistoryCount)
        }
        
        saveErrorHistory()
        trackError(error)
    }
    
    public func clearError() {
        lastError = nil
    }
    
    public func clearErrorHistory() {
        errorHistory.removeAll()
        try? storage.remove(forKey: Constants.errorHistoryKey)
    }
    
    // MARK: - Private Methods
    private func convertToAppError(_ error: Error) -> AppError {
        switch error {
        case let networkError as NetworkError:
            return .network(networkError)
        case let locationError as LocationError:
            return .location(locationError)
        case let backgroundError as BackgroundError:
            return .background(backgroundError)
        case let configError as ConfigurationError:
            return .configuration(configError)
        case let storageError as StorageError:
            return .storage(storageError)
        case let deviceError as DeviceError:
            return .device(deviceError)
        case let automationError as AutomationError:
            return .automation(automationError)
        case let stateError as StateError:
            return .state(stateError)
        case let sceneError as SceneError:
            return .scene(sceneError)
        case let effectError as EffectError:
            return .effect(effectError)
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
    private func loadErrorHistory() {
        do {
            let data = try storage.load(Constants.errorHistoryKey)
            errorHistory = try JSONDecoder().decode([ErrorRecord].self, from: data)
        } catch {
            print("Failed to load error history: \(error)")
        }
    }
    
    private func saveErrorHistory() {
        do {
            let data = try JSONEncoder().encode(errorHistory)
            try storage.save(data, forKey: Constants.errorHistoryKey)
        } catch {
            print("Failed to save error history: \(error)")
        }
    }
    
    private func trackError(_ error: AppError) {
        analytics.trackEvent(AnalyticsEvent(
            name: "error_occurred",
            parameters: [
                "error_type": String(describing: type(of: error)),
                "error_description": error.errorDescription ?? "",
                "error_severity": error.severity.rawValue
            ]
        ))
    }
}

// MARK: - SwiftUI View Modifiers
public extension View {
    func handleError(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorHandlingViewModifier(error: error))
    }
}

public struct ErrorHandlingViewModifier: ViewModifier {
    @Binding var error: AppError?
    @Environment(\.dismiss) private var dismiss
    
    public func body(content: Content) -> some View {
        content
            .alert(
                error?.errorDescription ?? "",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let suggestion = error?.recoverySuggestion {
                    Text(suggestion)
                }
            }
    }
} 