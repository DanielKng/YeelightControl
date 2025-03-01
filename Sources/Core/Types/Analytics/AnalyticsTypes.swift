import Foundation
import Combine

// MARK: - Analytics Types
public enum Core_AnalyticsEventType: String, Codable, CaseIterable {
    case appOpen
    case appClose
    case deviceConnected
    case deviceDisconnected
    case deviceControlled
    case sceneActivated
    case sceneDeactivated
    case effectStarted
    case effectStopped
    case settingsChanged
    case error
    case custom
}

public struct Core_AnalyticsEvent: Codable, Hashable {
    public let type: Core_AnalyticsEventType
    public let timestamp: Date
    public let parameters: [String: String]
    
    public init(
        type: Core_AnalyticsEventType,
        timestamp: Date = Date(),
        parameters: [String: String] = [:]
    ) {
        self.type = type
        self.timestamp = timestamp
        self.parameters = parameters
    }
}

public enum Core_AnalyticsCategory: String, Codable, CaseIterable {
    case app
    case device
    case scene
    case effect
    case user
    case error
    case network
    case performance
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

// MARK: - Analytics Protocols
@preconcurrency public protocol Core_AnalyticsManaging: Core_BaseService {
    /// Publisher for analytics events
    nonisolated var analyticsEvents: AnyPublisher<Core_AnalyticsEvent, Never> { get }
    
    /// Track an analytics event
    func trackEvent(_ event: Core_AnalyticsEvent)
    
    /// Set a user property
    func setUserProperty(_ property: String, value: String)
} 