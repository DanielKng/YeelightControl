import Foundation
import BackgroundTasks
import Combine
import os.log

/// Manages background refresh tasks for the application
/// Handles scheduling and execution of background tasks to keep device data fresh
final class BackgroundRefreshManager: ObservableObject {
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = BackgroundRefreshManager()
    
    /// Logger for debugging background tasks
    private let logger = Logger(subsystem: "com.yeelight.control", category: "BackgroundRefresh")
    
    /// Background task identifiers
    private enum TaskIdentifier {
        static let appRefresh = "com.yeelight.refresh"
        static let deviceSync = "com.yeelight.deviceSync"
    }
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {
        registerBackgroundTasks()
    }
    
    // MARK: - Public Methods
    
    /// Schedules a background app refresh task
    /// - Returns: True if the task was successfully scheduled
    @discardableResult
    func scheduleAppRefresh() -> Bool {
        let request = BGAppRefreshTaskRequest(identifier: TaskIdentifier.appRefresh)
        
        // Set earliest begin date to 15 minutes from now
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Successfully scheduled app refresh task")
            return true
        } catch {
            logger.error("Failed to schedule app refresh: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Schedules a device synchronization task
    /// - Returns: True if the task was successfully scheduled
    @discardableResult
    func scheduleDeviceSync() -> Bool {
        let request = BGProcessingTaskRequest(identifier: TaskIdentifier.deviceSync)
        
        // Require network connectivity for this task
        request.requiresNetworkConnectivity = true
        
        // Allow task to run for up to 5 minutes
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Successfully scheduled device sync task")
            return true
        } catch {
            logger.error("Failed to schedule device sync: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// Registers all background tasks with the system
    private func registerBackgroundTasks() {
        // Register app refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.appRefresh,
            using: nil
        ) { [weak self] task in
            self?.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Register device sync task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.deviceSync,
            using: nil
        ) { [weak self] task in
            self?.handleDeviceSync(task: task as! BGProcessingTask)
        }
        
        logger.info("Registered background tasks")
    }
    
    /// Handles execution of an app refresh background task
    /// - Parameter task: The app refresh task to handle
    private func handleAppRefresh(task: BGAppRefreshTask) {
        logger.info("Handling app refresh task")
        
        // Schedule the next refresh before this one ends
        scheduleAppRefresh()
        
        // Set up task expiration handler
        task.expirationHandler = {
            self.logger.warning("App refresh task expired before completion")
        }
        
        // Perform a quick refresh of device states
        Task {
            do {
                try await YeelightManager.shared.quickRefreshDevices()
                task.setTaskCompleted(success: true)
                self.logger.info("App refresh task completed successfully")
            } catch {
                task.setTaskCompleted(success: false)
                self.logger.error("App refresh task failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Handles execution of a device sync background task
    /// - Parameter task: The device sync task to handle
    private func handleDeviceSync(task: BGProcessingTask) {
        logger.info("Handling device sync task")
        
        // Schedule the next sync before this one ends
        scheduleDeviceSync()
        
        // Set up task expiration handler
        task.expirationHandler = {
            self.logger.warning("Device sync task expired before completion")
        }
        
        // Perform a full sync of all devices
        Task {
            do {
                try await YeelightManager.shared.fullSyncDevices()
                task.setTaskCompleted(success: true)
                self.logger.info("Device sync task completed successfully")
            } catch {
                task.setTaskCompleted(success: false)
                self.logger.error("Device sync task failed: \(error.localizedDescription)")
            }
        }
    }
} 