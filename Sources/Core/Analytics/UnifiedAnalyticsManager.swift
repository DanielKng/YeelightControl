import Foundation
import Combine
import SwiftUI

// MARK: - Analytics Managing Protocol
public protocol Core_AnalyticsManaging: Core_BaseService {
    var isEnabled: Bool { get set }
    func trackEvent(_ event: Core_AnalyticsEvent)
    func startSession() async
    func endSession() async
    func logError(_ error: Error, context: [String: Any]?) async
    func setUserProperty(_ value: Any?, forKey key: String) async
    func incrementMetric(_ metric: Core_AnalyticsMetric) async
}

// MARK: - Analytics Event
public struct Core_AnalyticsEvent: Codable, Identifiable {
    public var id: String { UUID().uuidString }
    public let name: String
    public let category: Core_AnalyticsCategory
    public let parameters: [String: String]
    public let timestamp: Date
    
    public init(
        name: String,
        category: Core_AnalyticsCategory,
        parameters: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.name = name
        self.category = category
        self.parameters = parameters
        self.timestamp = timestamp
    }
}

// MARK: - Analytics Category
public enum Core_AnalyticsCategory: String, Codable {
    case device
    case room
    case scene
    case effect
    case automation
    case network
    case error
    case performance
    case user
    case analytics
}

// MARK: - Analytics Metric
public enum Core_AnalyticsMetric: String {
    case deviceCount
    case roomCount
    case sceneCount
    case effectCount
    case automationCount
    case networkRequests
    case errorCount
    case sessionDuration
    case appLaunchTime
    case backgroundTaskCount
}

@MainActor
public final class UnifiedAnalyticsManager: ObservableObject, Core_AnalyticsManaging {
    // MARK: - Published Properties
    @Published public var isEnabled = false
    @Published public private(set) var events: [Core_AnalyticsEvent] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let queue = DispatchQueue(label: "com.yeelight.analytics", qos: .utility)
    private let storage: any Core_StorageManaging
    private var sessionStartTime: Date?
    private var eventBuffer: [Core_AnalyticsEvent] = []
    private let maxBufferSize = 100
    
    // MARK: - Constants
    private enum Constants {
        static let maxEventCount = 1000
        static let storageKey = "analytics"
        static let settingsKey = "analytics.settings"
        static let batchSize = 50
    }
    
    // MARK: - Initialization
    public init(storageManager: any Core_StorageManaging) {
        self.storage = storageManager
        
        Task {
            await loadSettings()
            await loadEvents()
            setupPeriodicUpload()
        }
    }
    
    // MARK: - Public Methods
    public func setEnabled(_ enabled: Bool) async {
        isEnabled = enabled
        if !enabled {
            await clearEvents()
        }
        await saveSettings()
    }
    
    public func trackEvent(_ event: Core_AnalyticsEvent) {
        // TODO: Implement analytics tracking
        print("Analytics event tracked: \(event.name) with parameters: \(event.parameters)")
    }
    
    public func startSession() async {
        sessionStartTime = Date()
    }
    
    public func endSession() async {
        guard let startTime = sessionStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        print("Session ended with duration: \(duration) seconds")
        sessionStartTime = nil
    }
    
    public func logError(_ error: Error, context: [String: Any]?) async {
        print("Analytics error logged: \(error.localizedDescription) with context: \(context ?? [:])")
    }
    
    public func setUserProperty(_ value: Any?, forKey key: String) async {
        print("Setting user property \(key) to \(String(describing: value))")
    }
    
    public func incrementMetric(_ metric: Core_AnalyticsMetric) async {
        print("Incrementing metric: \(metric.rawValue)")
    }
    
    public func clearEvents() async {
        events.removeAll()
        do {
            try await storage.delete(forKey: Constants.storageKey)
        } catch {
            print("Failed to clear analytics events: \(error)")
        }
    }
    
    // MARK: - Private Methods
    private func loadEvents() async {
        do {
            let loadedEvents: [Core_AnalyticsEvent] = try await storage.load(forKey: Constants.storageKey)
            await MainActor.run {
                events = loadedEvents
            }
        } catch {
            print("Failed to load analytics events: \(error)")
        }
    }
    
    private func saveEvents() async {
        do {
            try await storage.save(events, forKey: Constants.storageKey)
        } catch {
            print("Failed to save analytics events: \(error)")
        }
    }
    
    private func setupPeriodicUpload() {
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.uploadEvents()
                }
            }
            .store(in: &cancellables)
    }
    
    private func uploadEvents() async {
        guard !events.isEmpty else { return }
        
        let eventsToUpload = Array(events.prefix(Constants.batchSize))
        
        // Here you would implement the actual upload logic
        // For example, sending to a analytics service
        
        events.removeFirst(min(eventsToUpload.count, events.count))
        await saveEvents()
    }
    
    private func flushEvents() async {
        guard !eventBuffer.isEmpty else { return }
        
        do {
            try await storage.save(eventBuffer, forKey: Constants.storageKey)
            eventBuffer.removeAll()
        } catch {
            print("Failed to flush analytics events: \(error)")
        }
    }
    
    private func loadSettings() async {
        do {
            let enabled: Bool = try await storage.load(forKey: Constants.settingsKey)
            await MainActor.run {
                isEnabled = enabled
            }
        } catch {
            print("Failed to load analytics settings: \(error)")
            await MainActor.run {
                isEnabled = true // Default to enabled
            }
        }
    }
    
    private func saveSettings() async {
        do {
            try await storage.save(isEnabled, forKey: Constants.settingsKey)
        } catch {
            print("Failed to save analytics settings: \(error)")
        }
    }
}

// MARK: - Analytics Event Names
public enum Core_AnalyticsEventName {
    public static let appLaunch = "app_launch"
    public static let deviceDiscovered = "device_discovered"
    public static let deviceConnected = "device_connected"
    public static let deviceDisconnected = "device_disconnected"
    public static let sceneActivated = "scene_activated"
    public static let effectActivated = "effect_activated"
    public static let settingsChanged = "settings_changed"
    public static let errorOccurred = "error_occurred"
}

// MARK: - Notification Extension
extension Notification.Name {
    static let networkRequestCompleted = Notification.Name("NetworkRequestCompleted")
}

// MARK: - Constants
extension UnifiedAnalyticsManager {
    public static let logCategory = Core_AnalyticsCategory.analytics
} 