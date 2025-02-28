import Foundation
import BackgroundTasks
import Combine
import SwiftUI

@MainActor
public final class UnifiedBackgroundManager: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var isBackgroundRefreshEnabled = false
    @Published public private(set) var lastRefreshDate: Date?
    @Published public private(set) var nextScheduledRefresh: Date?
    
    // MARK: - Private Properties
    private let deviceManager: UnifiedDeviceManager
    private let configManager: UnifiedConfigurationManager
    private let errorManager: UnifiedErrorManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum Constants {
        static let appRefreshTaskIdentifier = "com.yeelight.control.refresh"
        static let minimumRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
        static let maximumRefreshInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedBackgroundManager()
    
    private init() {
        self.deviceManager = .shared
        self.configManager = .shared
        self.errorManager = .shared
        registerBackgroundTasks()
        setupObservers()
    }
    
    // MARK: - Public Methods
    public func enableBackgroundRefresh() {
        guard !isBackgroundRefreshEnabled else { return }
        isBackgroundRefreshEnabled = true
        scheduleBackgroundRefresh()
    }
    
    public func disableBackgroundRefresh() {
        isBackgroundRefreshEnabled = false
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Constants.appRefreshTaskIdentifier)
        nextScheduledRefresh = nil
    }
    
    public func performBackgroundRefresh() async throws {
        lastRefreshDate = Date()
        
        // Update device states
        for device in deviceManager.devices {
            do {
                try await deviceManager.updateDeviceState(device)
            } catch {
                errorManager.handle(error, context: ["device_id": device.id])
            }
        }
        
        // Schedule next refresh
        scheduleBackgroundRefresh()
    }
    
    // MARK: - Private Methods
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Constants.appRefreshTaskIdentifier,
            using: nil
        ) { [weak self] task in
            task.expirationHandler = {
                task.setTaskCompleted(success: false)
            }
            
            Task { @MainActor [weak self] in
                do {
                    try await self?.performBackgroundRefresh()
                    task.setTaskCompleted(success: true)
                } catch {
                    self?.errorManager.handle(error)
                    task.setTaskCompleted(success: false)
                }
            }
        }
    }
    
    private func scheduleBackgroundRefresh() {
        guard isBackgroundRefreshEnabled else { return }
        
        let request = BGAppRefreshTaskRequest(identifier: Constants.appRefreshTaskIdentifier)
        request.earliestBeginDate = calculateNextRefreshDate()
        
        do {
            try BGTaskScheduler.shared.submit(request)
            nextScheduledRefresh = request.earliestBeginDate
        } catch {
            errorManager.handle(error)
        }
    }
    
    private func calculateNextRefreshDate() -> Date {
        let now = Date()
        let interval = max(
            Constants.minimumRefreshInterval,
            min(
                configManager.configuration.appSettings.backgroundRefreshInterval ?? Constants.minimumRefreshInterval,
                Constants.maximumRefreshInterval
            )
        )
        return now.addingTimeInterval(interval)
    }
    
    private func setupObservers() {
        // Observe configuration changes
        configManager.$configuration
            .sink { [weak self] config in
                if config.appSettings.backgroundRefreshEnabled {
                    self?.enableBackgroundRefresh()
                } else {
                    self?.disableBackgroundRefresh()
                }
            }
            .store(in: &cancellables)
        
        // Initial state
        if configManager.configuration.appSettings.backgroundRefreshEnabled {
            enableBackgroundRefresh()
        }
    }
}

// MARK: - Configuration Extension
extension Configuration.AppSettings {
    public var backgroundRefreshInterval: TimeInterval? {
        get {
            UserDefaults.standard.value(forKey: "background_refresh_interval") as? TimeInterval
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "background_refresh_interval")
        }
    }
} 