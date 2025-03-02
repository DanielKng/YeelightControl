import Foundation
#if os(iOS)
import BackgroundTasks
#endif
import Combine
import SwiftUI

// MARK: - Configuration
public struct BackgroundConfiguration: Codable {
    public struct AppSettings: Codable {
        public var backgroundRefreshEnabled: Bool
        public var backgroundRefreshInterval: TimeInterval?
        
        public init(backgroundRefreshEnabled: Bool = false, backgroundRefreshInterval: TimeInterval? = nil) {
            self.backgroundRefreshEnabled = backgroundRefreshEnabled
            self.backgroundRefreshInterval = backgroundRefreshInterval
        }
    }
    
    public var appSettings: AppSettings
    
    public init(appSettings: AppSettings = AppSettings()) {
        self.appSettings = appSettings
    }
}

// MARK: - Constants
public enum BackgroundConstants {
    public static let appRefreshTaskIdentifier = "com.yeelight.control.refresh"
    public static let minimumRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
    public static let maximumRefreshInterval: TimeInterval = 24 * 60 * 60 // 24 hours
}

@MainActor
public final class UnifiedBackgroundManager: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var isBackgroundRefreshEnabled = false
    @Published public private(set) var lastRefreshDate: Date?
    @Published public private(set) var nextScheduledRefresh: Date?
    
    // MARK: - Private Properties
    private let services: ServiceContainer
    private var cancellables = Set<AnyCancellable>()
    private var backgroundConfig = BackgroundConfiguration()
    
    // MARK: - Singleton
    public static let shared = UnifiedBackgroundManager()
    
    private init() {
        self.services = .shared
        setupObservers()
        #if os(iOS)
        registerBackgroundTasks()
        #endif
    }
    
    // MARK: - Public Methods
    public func enableBackgroundRefresh() {
        backgroundConfig.appSettings.backgroundRefreshEnabled = true
        #if os(iOS)
        scheduleBackgroundRefresh()
        #endif
    }
    
    public func disableBackgroundRefresh() {
        backgroundConfig.appSettings.backgroundRefreshEnabled = false
        #if os(iOS)
        cancelBackgroundRefresh()
        #endif
    }
    
    public func setBackgroundRefreshInterval(_ interval: TimeInterval) {
        backgroundConfig.appSettings.backgroundRefreshInterval = interval
        #if os(iOS)
        if backgroundConfig.appSettings.backgroundRefreshEnabled {
            scheduleBackgroundRefresh()
        }
        #endif
    }
    
    public func performBackgroundRefresh() async throws {
        lastRefreshDate = Date()
        
        // Update device states
        for device in services.deviceManager.devices {
            do {
                try await services.deviceManager.updateDevice(device)
            } catch {
                await services.errorHandler.handle(Core_AppError(error: error, context: "Background refresh"))
            }
        }
        
        // Schedule next refresh
        #if os(iOS)
        scheduleBackgroundRefresh()
        #endif
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Add any necessary observers here
    }
    
    #if os(iOS)
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundConstants.appRefreshTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundTask(task)
        }
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundConstants.appRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow:
            backgroundConfig.appSettings.backgroundRefreshInterval ?? BackgroundConstants.minimumRefreshInterval
        )
        
        do {
            try BGTaskScheduler.shared.submit(request)
            nextScheduledRefresh = request.earliestBeginDate
        } catch {
            Task {
                await services.errorHandler.handle(Core_AppError(error: error, context: "Background task scheduling"))
            }
        }
    }
    
    private func cancelBackgroundRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundConstants.appRefreshTaskIdentifier)
        nextScheduledRefresh = nil
    }
    
    private func handleBackgroundTask(_ task: Any) {
        if let refreshTask = task as? BGAppRefreshTask {
            handleAppRefresh(refreshTask)
        } else if let processingTask = task as? BGProcessingTask {
            handleProcessingTask(processingTask)
        }
    }
    
    private func handleAppRefresh(_ task: BGAppRefreshTask) {
        if backgroundConfig.appSettings.backgroundRefreshEnabled {
            Task {
                await refreshDevices()
                scheduleBackgroundRefresh()
                task.setTaskCompleted(success: true)
            }
        } else {
            task.setTaskCompleted(success: false)
        }
    }
    
    private func handleProcessingTask(_ task: BGProcessingTask) {
        // Implementation for processing task
        task.setTaskCompleted(success: true)
    }
    #endif
    
    private func refreshDevices() async {
        // Implement device refresh logic here
        for device in services.deviceManager.devices {
            do {
                try await services.deviceManager.updateDevice(device)
            } catch {
                await services.errorHandler.handle(Core_AppError(error: error, context: "Device refresh"))
            }
        }
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    var backgroundRefreshInterval: TimeInterval? {
        get {
            let interval = TimeInterval(exactly: integer(forKey: "backgroundRefreshInterval"))
            return interval.map { max(BackgroundConstants.minimumRefreshInterval, 
                                     min($0, BackgroundConstants.maximumRefreshInterval)) }
        }
        set {
            if let interval = newValue {
                set(Int(interval), forKey: "backgroundRefreshInterval")
            } else {
                removeObject(forKey: "backgroundRefreshInterval")
            }
        }
    }
}

// MARK: - Core_AppError Extension
extension Core_AppError {
    init(error: Error, context: String) {
        // Create a general error with the provided context
        self = .general("\(context): \(error.localizedDescription)")
    }
} 