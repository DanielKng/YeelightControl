import Foundation
import BackgroundTasks
import Combine
import UIKit

// MARK: - Background Managing Protocol
protocol BackgroundManaging {
    var isRefreshing: Bool { get }
    var lastRefreshDate: Date? { get }
    var refreshError: Error? { get }
    
    func startBackgroundRefresh()
    func stopBackgroundRefresh()
    func performRefresh() async throws
}

// MARK: - Background Manager Implementation
final class UnifiedBackgroundManager: BackgroundManaging, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastRefreshDate: Date?
    @Published private(set) var refreshError: Error?
    
    // MARK: - Private Properties
    private let services: ServiceContainer
    private let queue = DispatchQueue(label: "de.knng.app.yeelightcontrol.background", qos: .utility)
    private let refreshTaskIdentifier = "de.knng.app.yeelightcontrol.refresh"
    private var refreshTask: Task<Void, Never>?
    private var refreshTimer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(services: ServiceContainer = .shared) {
        self.services = services
        setupBackgroundTasks()
        setupNotificationObservers()
        setupConfigurationObserver()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    func startBackgroundRefresh() {
        stopBackgroundRefresh()
        
        let interval = services.config.getValue(for: .minRefreshInterval) ?? 15 * 60
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refreshTask = Task {
                do {
                    try await self?.performRefresh()
                } catch {
                    self?.services.logger.error("Periodic refresh failed: \(error.localizedDescription)", category: .background)
                }
            }
        }
        refreshTimer?.tolerance = 60 // 1 minute tolerance
        
        services.logger.info("Started background refresh with interval: \(interval) seconds", category: .background)
    }
    
    func stopBackgroundRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        refreshTask?.cancel()
        refreshTask = nil
        
        services.logger.info("Stopped background refresh", category: .background)
    }
    
    func performRefresh() async throws {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            services.logger.info("Starting background refresh", category: .background)
            
            // Discover new devices
            await services.deviceManager.discoverDevices()
            
            // Update device states
            let devices = try await services.storage.load(forKey: .devices) as [StoredDevice]
            for device in devices {
                if let yeelightDevice = services.deviceManager.getDevice(byId: device.id) {
                    try await services.stateManager.syncState(for: yeelightDevice.id)
                }
            }
            
            // Clean up stale automations
            try await cleanupStaleAutomations()
            
            // Update last refresh date
            lastRefreshDate = Date()
            refreshError = nil
            
            services.logger.info("Background refresh completed successfully", category: .background)
            
        } catch {
            refreshError = error
            services.logger.error("Background refresh failed: \(error.localizedDescription)", category: .background)
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func cleanup() {
        stopBackgroundRefresh()
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func setupBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { [weak self] task in
            self?.handleBackgroundRefresh(task as! BGAppRefreshTask)
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func setupConfigurationObserver() {
        services.config.configurationUpdates
            .sink { [weak self] _ in
                self?.handleConfigurationUpdate()
            }
            .store(in: &cancellables)
    }
    
    private func handleConfigurationUpdate() {
        // Restart background refresh with new configuration
        if refreshTimer != nil {
            stopBackgroundRefresh()
            startBackgroundRefresh()
        }
    }
    
    private func handleBackgroundRefresh(_ task: BGAppRefreshTask) {
        // Schedule next refresh before starting work
        scheduleNextRefresh()
        
        let timeout = services.config.getValue(for: .backgroundTaskTimeout) ?? 30.0
        
        // Set expiration handler
        task.expirationHandler = { [weak self] in
            self?.cleanup()
        }
        
        // Start refresh
        refreshTask = Task {
            do {
                try await withTimeout(timeout) {
                    try await self.performRefresh()
                }
                task.setTaskCompleted(success: true)
            } catch {
                services.logger.error("Background refresh task failed: \(error.localizedDescription)", category: .background)
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        let interval = services.config.getValue(for: .minRefreshInterval) ?? 15 * 60
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            services.logger.info("Scheduled next background refresh", category: .background)
        } catch {
            services.logger.error("Failed to schedule background refresh: \(error.localizedDescription)", category: .background)
        }
    }
    
    private func cleanupStaleAutomations() async throws {
        let automations = try await services.storage.load(forKey: .automations) as [Automation]
        var updatedAutomations = automations
        
        // Remove automations with invalid device references
        updatedAutomations.removeAll { automation in
            for action in automation.actions {
                switch action {
                case .setPower(let deviceId, _),
                     .setBrightness(let deviceId, _),
                     .setScene(let deviceId, _),
                     .setEffect(let deviceId, _),
                     .setColor(let deviceId, _),
                     .setColorTemperature(let deviceId, _):
                    if services.deviceManager.getDevice(byId: deviceId) == nil {
                        return true
                    }
                }
            }
            return false
        }
        
        if updatedAutomations.count != automations.count {
            try await services.storage.save(updatedAutomations, forKey: .automations)
            services.logger.info("Removed \(automations.count - updatedAutomations.count) stale automations", category: .background)
        }
    }
    
    private func withTimeout<T>(_ seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw BackgroundError.timeout
            }
            
            let result = try await group.next()
            group.cancelAll()
            return result ?? { throw BackgroundError.taskCancelled }()
        }
    }
    
    @objc private func applicationDidEnterBackground() {
        scheduleNextRefresh()
    }
    
    @objc private func applicationWillEnterForeground() {
        // Perform a refresh when app comes to foreground if enough time has passed
        if let lastRefresh = lastRefreshDate {
            let interval = services.config.getValue(for: .minRefreshInterval) ?? 15 * 60
            if Date().timeIntervalSince(lastRefresh) >= interval {
                Task {
                    try? await performRefresh()
                }
            }
        }
    }
}

// MARK: - Background Errors
enum BackgroundError: LocalizedError {
    case refreshInProgress
    case taskCancelled
    case timeout
    case systemError(String)
    
    var errorDescription: String? {
        switch self {
        case .refreshInProgress:
            return "A refresh operation is already in progress"
        case .taskCancelled:
            return "Background task was cancelled"
        case .timeout:
            return "Background task timed out"
        case .systemError(let message):
            return "System error: \(message)"
        }
    }
} 