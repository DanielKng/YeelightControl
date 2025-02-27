import Foundation
import Combine

// MARK: - Error Handling Protocol
protocol ErrorHandling {
    var lastError: AppError? { get }
    var errorUpdates: AnyPublisher<AppError, Never> { get }
    
    func handle(_ error: Error)
    func handle(_ error: AppError)
    func clearError()
}

// MARK: - App Error Type
enum AppError: LocalizedError, Identifiable {
    case network(NetworkError)
    case location(LocationError)
    case background(BackgroundError)
    case configuration(ConfigurationError)
    case storage(StorageError)
    case device(DeviceError)
    case automation(AutomationError)
    case state(StateError)
    case system(String)
    case unknown(Error)
    
    var id: String {
        switch self {
        case .network(let error): return "network-\(error.localizedDescription)"
        case .location(let error): return "location-\(error.localizedDescription)"
        case .background(let error): return "background-\(error.localizedDescription)"
        case .configuration(let error): return "config-\(error.localizedDescription)"
        case .storage(let error): return "storage-\(error.localizedDescription)"
        case .device(let error): return "device-\(error.localizedDescription)"
        case .automation(let error): return "automation-\(error.localizedDescription)"
        case .state(let error): return "state-\(error.localizedDescription)"
        case .system(let message): return "system-\(message)"
        case .unknown(let error): return "unknown-\(error.localizedDescription)"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .network(let error): return error.localizedDescription
        case .location(let error): return error.localizedDescription
        case .background(let error): return error.localizedDescription
        case .configuration(let error): return error.localizedDescription
        case .storage(let error): return error.localizedDescription
        case .device(let error): return error.localizedDescription
        case .automation(let error): return error.localizedDescription
        case .state(let error): return error.localizedDescription
        case .system(let message): return message
        case .unknown(let error): return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
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
        case .system, .unknown:
            return "Try restarting the app. If the problem persists, contact support."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .network(let error):
            return error is NetworkError ? .warning : .error
        case .location(let error):
            return error is LocationError ? .warning : .error
        case .background:
            return .warning
        case .configuration:
            return .warning
        case .storage:
            return .error
        case .device:
            return .warning
        case .automation:
            return .warning
        case .state:
            return .warning
        case .system:
            return .error
        case .unknown:
            return .error
        }
    }
}

// MARK: - Error Severity
enum ErrorSeverity {
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
final class UnifiedErrorHandler: ErrorHandling, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var lastError: AppError?
    
    // MARK: - Publishers
    private let errorSubject = PassthroughSubject<AppError, Never>()
    var errorUpdates: AnyPublisher<AppError, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let storage: StorageManaging
    private let queue = DispatchQueue(label: "de.knng.app.yeelightcontrol.error", qos: .userInitiated)
    private var errorHistory: [ErrorRecord] = []
    private let maxHistorySize = 100
    
    // MARK: - Types
    private struct ErrorRecord: Codable {
        let error: AppError
        let timestamp: Date
        let context: String?
    }
    
    // MARK: - Initialization
    init(storage: StorageManaging) {
        self.storage = storage
        loadErrorHistory()
    }
    
    // MARK: - Public Methods
    func handle(_ error: Error) {
        queue.async { [weak self] in
            let appError = self?.convertToAppError(error)
            self?.handleAppError(appError)
        }
    }
    
    func handle(_ error: AppError) {
        queue.async { [weak self] in
            self?.handleAppError(error)
        }
    }
    
    func clearError() {
        queue.async { [weak self] in
            self?.lastError = nil
        }
    }
    
    // MARK: - Private Methods
    private func handleAppError(_ error: AppError?) {
        guard let error = error else { return }
        
        // Update last error
        lastError = error
        
        // Send error update
        errorSubject.send(error)
        
        // Log error
        services.logger.error(error.localizedDescription, category: .system)
        
        // Record error
        let record = ErrorRecord(
            error: error,
            timestamp: Date(),
            context: Thread.callStackSymbols.first
        )
        errorHistory.append(record)
        
        // Trim history if needed
        if errorHistory.count > maxHistorySize {
            errorHistory.removeFirst(errorHistory.count - maxHistorySize)
        }
        
        // Save error history
        try? saveErrorHistory()
    }
    
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
        default:
            return .unknown(error)
        }
    }
    
    private func loadErrorHistory() {
        do {
            errorHistory = try storage.load(forKey: .errorHistory)
        } catch {
            services.logger.error("Failed to load error history: \(error.localizedDescription)", category: .system)
        }
    }
    
    private func saveErrorHistory() throws {
        try storage.save(errorHistory, forKey: .errorHistory)
    }
}

// MARK: - Error View Modifiers
extension View {
    func handleError(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorHandlingViewModifier(error: error))
    }
}

struct ErrorHandlingViewModifier: ViewModifier {
    @Binding var error: AppError?
    @Environment(\.services) var services
    
    func body(content: Content) -> some View {
        content
            .alert(item: $error) { error in
                Alert(
                    title: Text(error.localizedDescription),
                    message: Text(error.recoverySuggestion ?? ""),
                    dismissButton: .default(Text("OK")) {
                        services.errorHandler.clearError()
                    }
                )
            }
    }
} 