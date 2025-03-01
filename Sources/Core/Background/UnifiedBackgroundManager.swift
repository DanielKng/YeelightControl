import Foundation
import BackgroundTasks
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

@MainActor
public final class UnifiedBackgroundManager: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var isBackgroundRefreshEnabled = false
    @Published public private(set) var lastRefreshDate: Date?
    @Published public private(set) var nextScheduledRefresh: Date?
    
    // MARK: - Private Properties
    private let services: BaseServiceContainer
    private var cancellables = Set<AnyCancellable>()
    private var backgroundConfig = BackgroundConfiguration()
    
    // MARK: - Constants
    private enum Constants {
        static let appRefreshTaskIdentifier = "com.yeelight.control.refresh"
        static let minimumRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
        static let maximumRefreshInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedBackgroundManager()
    
    private init() {
        self.services = .shared
        setupObservers()
        registerBackgroundTasks()
    }
    
    // MARK: - Public Methods
    public func enableBackgroundRefresh() {
        backgroundConfig.appSettings.backgroundRefreshEnabled = true
        scheduleBackgroundRefresh()
    }
    
    public func disableBackgroundRefresh() {
        backgroundConfig.appSettings.backgroundRefreshEnabled = false
        cancelBackgroundRefresh()
    }
    
    public func setBackgroundRefreshInterval(_ interval: TimeInterval) {
        backgroundConfig.appSettings.backgroundRefreshInterval = interval
        if backgroundConfig.appSettings.backgroundRefreshEnabled {
            scheduleBackgroundRefresh()
        }
    }
    
    public func performBackgroundRefresh() async throws {
        lastRefreshDate = Date()
        
        // Update device states
        for device in services.deviceManager.devices {
            do {
                try await services.deviceManager.updateDeviceState(device)
            } catch {
                services.errorHandler.handle(error)
            }
        }
        
        // Schedule next refresh
        scheduleBackgroundRefresh()
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Add any necessary observers here
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Constants.appRefreshTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleAppRefresh(task as! BGAppRefreshTask)
        }
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.appRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow:
            backgroundConfig.appSettings.backgroundRefreshInterval ?? Constants.minimumRefreshInterval
        )
        
        do {
            try BGTaskScheduler.shared.submit(request)
            nextScheduledRefresh = request.earliestBeginDate
        } catch {
            services.errorHandler.handle(error)
        }
    }
    
    private func cancelBackgroundRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Constants.appRefreshTaskIdentifier)
        nextScheduledRefresh = nil
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
    
    private func refreshDevices() async {
        // Implement device refresh logic here
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    var backgroundRefreshInterval: TimeInterval? {
        get {
            let interval = TimeInterval(exactly: integer(forKey: "backgroundRefreshInterval"))
            return interval.map { max(UnifiedBackgroundManager.Constants.minimumRefreshInterval, 
                                     min($0, UnifiedBackgroundManager.Constants.maximumRefreshInterval)) }
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