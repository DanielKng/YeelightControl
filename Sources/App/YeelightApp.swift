import SwiftUI
import Combine
import BackgroundTasks

/// Main application entry point for YeelightControl
/// Manages core services and environment objects for the app
@main
struct YeelightApp: App {
    // MARK: - Properties
    
    /// Debug settings manager
    @StateObject private var debugSettings = DebugSettings.shared
    
    /// Main manager for Yeelight devices
    @StateObject private var yeelightManager = YeelightManager.shared
    
    /// Monitors network connectivity status
    @StateObject private var networkMonitor = NetworkMonitor()
    
    /// Handles persistent storage of device data
    @StateObject private var deviceStorage = DeviceStorage.shared
    
    /// Manages scene creation and application
    @StateObject private var sceneManager = SceneManager.shared
    
    /// Manages background refresh tasks
    @StateObject private var backgroundRefreshManager = BackgroundRefreshManager.shared
    
    // MARK: - Initialization
    
    init() {
        // Register background tasks for device state refresh
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "de.knng.yeelightcontrol.refresh",
            using: nil
        ) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Configure global UI appearance settings
        configureAppearance()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(yeelightManager)
                .environmentObject(networkMonitor)
                .environmentObject(deviceStorage)
                .environmentObject(sceneManager)
                .environmentObject(backgroundRefreshManager)
                .environmentObject(debugSettings)
                .onAppear {
                    // Start network monitoring only if enabled in debug settings
                    if debugSettings.networkMonitoring {
                        networkMonitor.startMonitoring()
                    }
                    
                    // Load saved devices from persistent storage
                    deviceStorage.loadDevices()
                    
                    // Schedule background refresh tasks
                    backgroundRefreshManager.scheduleAppRefresh()
                }
                .onDisappear {
                    // Stop network monitoring when app disappears
                    networkMonitor.stopMonitoring()
                }
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles background app refresh tasks
    /// - Parameter task: The background app refresh task to handle
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Create a task that refreshes device states
        let refreshTask = Task {
            await yeelightManager.refreshAllDevices()
        }
        
        // Schedule a new refresh task before this one ends
        backgroundRefreshManager.scheduleAppRefresh()
        
        // Set expiration handler to cancel the task if time runs out
        task.expirationHandler = {
            refreshTask.cancel()
        }
        
        // Mark task complete when refresh is done
        Task {
            await refreshTask.value
            task.setTaskCompleted(success: true)
        }
    }
    
    /// Configures global UI appearance settings
    private func configureAppearance() {
        // Set navigation bar title appearance
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.primary)
        ]
        
        // Set table view background to clear
        UITableView.appearance().backgroundColor = .clear
    }
} 