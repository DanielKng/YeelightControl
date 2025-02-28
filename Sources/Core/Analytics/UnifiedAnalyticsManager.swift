import Foundation
import Combine
import SwiftUI

// MARK: - Analytics Managing Protocol
protocol AnalyticsManaging {
    func trackEvent(_ event: AnalyticsEvent)
    func startSession()
    func endSession()
    func logError(_ error: Error, context: [String: Any]?)
    func setUserProperty(_ value: Any?, forKey key: String)
    func incrementMetric(_ metric: AnalyticsMetric)
}

// MARK: - Analytics Event
public struct AnalyticsEvent: Codable {
    public let name: String
    public let category: AnalyticsCategory
    public let parameters: [String: String]
    public let timestamp: Date
    
    public init(
        name: String,
        category: AnalyticsCategory,
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
enum AnalyticsCategory: String, Codable {
    case device
    case room
    case scene
    case effect
    case automation
    case network
    case error
    case performance
    case user
}

// MARK: - Analytics Metric
enum AnalyticsMetric: String {
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
public final class UnifiedAnalyticsManager: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var isEnabled = false
    @Published public private(set) var events: [AnalyticsEvent] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let queue = DispatchQueue(label: "com.yeelight.analytics", qos: .utility)
    private let storage: UnifiedStorageManager
    private var sessionStartTime: Date?
    private var eventBuffer: [AnalyticsEvent] = []
    private let maxBufferSize = 100
    
    // MARK: - Constants
    private enum Constants {
        static let maxEventCount = 1000
        static let storageKey = "analytics_events"
        static let batchSize = 50
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedAnalyticsManager()
    
    private init() {
        self.storage = .shared
        loadEvents()
        setupPeriodicUpload()
        loadSettings()
    }
    
    // MARK: - Public Methods
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            clearEvents()
        }
        saveSettings()
    }
    
    public func trackEvent(_ event: AnalyticsEvent) {
        guard isEnabled, sessionStartTime != nil else { return }
        
        eventBuffer.append(event)
        
        if eventBuffer.count >= maxBufferSize {
            flushEvents()
        }
    }
    
    public func clearEvents() {
        events.removeAll()
        try? storage.remove(forKey: Constants.storageKey)
    }
    
    // MARK: - Private Methods
    private func loadEvents() {
        do {
            let data = try storage.load(forKey: Constants.storageKey)
            let decoder = JSONDecoder()
            events = try decoder.decode([AnalyticsEvent].self, from: data)
        } catch {
            print("Failed to load analytics events: \(error)")
        }
    }
    
    private func saveEvents() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(events)
            try storage.save(data, forKey: Constants.storageKey)
        } catch {
            print("Failed to save analytics events: \(error)")
        }
    }
    
    private func setupPeriodicUpload() {
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.uploadEvents()
            }
            .store(in: &cancellables)
    }
    
    private func uploadEvents() {
        guard !events.isEmpty else { return }
        
        let eventsToUpload = Array(events.prefix(Constants.batchSize))
        
        queue.async { [weak self] in
            // Here you would implement the actual upload logic
            // For example, sending to a analytics service
            
            DispatchQueue.main.async {
                self?.events.removeFirst(min(eventsToUpload.count, self?.events.count ?? 0))
                self?.saveEvents()
            }
        }
    }
    
    private func flushEvents() {
        guard !eventBuffer.isEmpty else { return }
        
        do {
            try storage.save(eventBuffer, forKey: "analytics_events")
            eventBuffer.removeAll()
        } catch {
            print("Failed to flush analytics events: \(error)")
        }
    }
    
    private func loadSettings() {
        do {
            isEnabled = try storage.load(Bool.self, forKey: "analytics_enabled")
        } catch {
            print("Failed to load analytics settings: \(error)")
            isEnabled = true // Default to enabled
        }
    }
    
    private func saveSettings() {
        do {
            try storage.save(isEnabled, forKey: "analytics_enabled")
        } catch {
            print("Failed to save analytics settings: \(error)")
        }
    }
}

// MARK: - Analytics Event Names
public enum AnalyticsEventName {
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

// MARK: - Logger Category Extension
extension LogCategory {
    static let analytics: LogCategory = "analytics"
} 