import Foundation
import Combine
import SwiftUI

// MARK: - Analytics Managing Protocol
// Protocol is already defined in AnalyticsTypes.swift
// Removing duplicate definition

// MARK: - Analytics Event
// Core_AnalyticsEvent is already defined in AnalyticsTypes.swift
// Removing duplicate definition

// MARK: - Analytics Category
// Core_AnalyticsCategory is already defined in AnalyticsTypes.swift
// Removing duplicate definition

// MARK: - Analytics Metric
// Core_AnalyticsMetric is already defined in AnalyticsTypes.swift
// Removing duplicate definition

public actor UnifiedAnalyticsManager: Core_AnalyticsManaging, Core_BaseService {
    // MARK: - Published Properties
    public private(set) var _isEnabled = false
    public private(set) var events: [Core_AnalyticsEvent] = []
    
    // MARK: - Core_BaseService Conformance
    nonisolated public var isEnabled: Bool {
        // Using a default value since we can't access actor state in a nonisolated context
        // The actual state will be used in isolated contexts
        return false
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let queue = DispatchQueue(label: "com.yeelight.analytics", qos: .utility)
    private let storage: any Core_StorageManaging
    private var sessionStartTime: Date?
    private var eventBuffer: [Core_AnalyticsEvent] = []
    private let maxBufferSize = 100
    private let analyticsEventsSubject = PassthroughSubject<Core_AnalyticsEvent, Never>()
    
    // MARK: - Constants
    private enum Constants {
        static let maxEventCount = 1000
        static let storageKey = "analytics"
        static let settingsKey = "analytics.settings"
        static let batchSize = 50
    }
    
    // MARK: - Core_BaseService
    public var serviceIdentifier: String {
        return "core.analytics"
    }
    
    // MARK: - Core_AnalyticsManaging Protocol Conformance
    public nonisolated var analyticsEvents: AnyPublisher<Core_AnalyticsEvent, Never> {
        let publisher = PassthroughSubject<Core_AnalyticsEvent, Never>()
        
        Task {
            for await event in await analyticsEventsSubject.values {
                publisher.send(event)
            }
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    public init(storageManager: any Core_StorageManaging) {
        self.storage = storageManager
        
        Task {
            await loadSettings()
            await loadEvents()
            await setupPeriodicUpload()
        }
    }
    
    // MARK: - Public Methods
    
    public func setEnabled(_ enabled: Bool) async {
        _isEnabled = enabled
        if !enabled {
            await clearEvents()
        }
        await saveSettings()
    }
    
    public nonisolated func trackEvent(_ event: Core_AnalyticsEvent) {
        Task {
            await trackEventInternal(event)
        }
    }
    
    private func trackEventInternal(_ event: Core_AnalyticsEvent) {
        // TODO: Implement analytics tracking
        print("Analytics event tracked: \(event.type) with parameters: \(event.parameters)")
        analyticsEventsSubject.send(event)
    }
    
    public nonisolated func startSession() {
        Task {
            await startSessionInternal()
        }
    }
    
    private func startSessionInternal() {
        sessionStartTime = Date()
    }
    
    public nonisolated func endSession() {
        Task {
            await endSessionInternal()
        }
    }
    
    private func endSessionInternal() {
        guard let startTime = sessionStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        print("Session ended with duration: \(duration) seconds")
        sessionStartTime = nil
    }
    
    public nonisolated func logError(_ error: Error, context: [String: Any]?) {
        Task {
            await logErrorInternal(error, context: context)
        }
    }
    
    private func logErrorInternal(_ error: Error, context: [String: Any]?) {
        print("Analytics error logged: \(error.localizedDescription) with context: \(context ?? [:])")
    }
    
    public nonisolated func setUserProperty(_ property: String, value: String) {
        Task {
            await setUserPropertyInternal(property, value: value)
        }
    }
    
    private func setUserPropertyInternal(_ property: String, value: String) {
        print("Setting user property \(property) to \(value)")
    }
    
    public nonisolated func incrementMetric(_ metric: Core_AnalyticsMetric) {
        Task {
            await incrementMetricInternal(metric)
        }
    }
    
    private func incrementMetricInternal(_ metric: Core_AnalyticsMetric) {
        print("Incrementing metric: \(metric.rawValue)")
    }
    
    public func clearEvents() async {
        events.removeAll()
        do {
            try await storage.remove(forKey: Constants.storageKey)
        } catch {
            print("Failed to clear analytics events: \(error)")
        }
    }
    
    // MARK: - Private Methods
    private func loadEvents() async {
        do {
            if let loadedEvents = try await storage.load([Core_AnalyticsEvent].self, forKey: Constants.storageKey) {
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
    
    private func setupPeriodicUpload() async {
        let timer = Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
        
        Task {
            for await _ in timer.values {
                await uploadEvents()
            }
        }
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
            if let enabled = try await storage.load(Bool.self, forKey: Constants.settingsKey) {
                _isEnabled = enabled
            } else {
                _isEnabled = true // Default to enabled
            }
        } catch {
            print("Failed to load analytics settings: \(error)")
            _isEnabled = true // Default to enabled
        }
    }
    
    private func saveSettings() async {
        do {
            try await storage.save(_isEnabled, forKey: Constants.settingsKey)
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