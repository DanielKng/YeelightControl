import Foundation
import SwiftUI
import CoreLocation
import Combine

// MARK: - Theme Types

// Core_Theme is already defined in UnifiedThemeManager.swift
// public enum Core_Theme: String, Codable, CaseIterable {
//     case light
//     case dark
//     case system
//     case custom
// }

public protocol ThemeColors {
    var primary: Color { get }
    var secondary: Color { get }
    var accent: Color { get }
    var background: Color { get }
    var text: Color { get }
    var error: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var info: Color { get }
}

public protocol ThemeFonts {
    var title: Font { get }
    var headline: Font { get }
    var body: Font { get }
    var caption: Font { get }
    var button: Font { get }
}

public protocol ThemeMetrics {
    var spacing: CGFloat { get }
    var padding: CGFloat { get }
    var cornerRadius: CGFloat { get }
    var iconSize: CGFloat { get }
    var buttonHeight: CGFloat { get }
}

// MARK: - Permission Types

// Core_AppPermissionType is already defined in UnifiedPermissionManager.swift
// public enum Core_AppPermissionType: String, CaseIterable {
//     case location
//     case notification
//     case camera
//     case microphone
//     case photoLibrary
//     case contacts
//     case calendar
//     case reminders
//     case bluetooth
//     case backgroundRefresh
//     case localNetwork
// }

// Core_PermissionStatus is already defined in UnifiedPermissionManager.swift
// public enum Core_PermissionStatus: String {
//     case notDetermined
//     case restricted
//     case denied
//     case authorized
//     case ephemeral
//     case provisional
// }

// MARK: - Notification Types

public typealias Core_InternalNotificationCategory = Core_AppNotificationCategory
public typealias Core_InternalNotificationTrigger = Core_AppNotificationTrigger

public struct Core_NotificationRequest {
    public let id: String
    public let title: String
    public let body: String
    public let category: Core_AppNotificationCategory
    public let trigger: Core_AppNotificationTrigger
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        category: Core_AppNotificationCategory,
        trigger: Core_AppNotificationTrigger
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.category = category
        self.trigger = trigger
    }
}

public enum Core_AppNotificationCategory: String, Codable, CaseIterable {
    case device
    case scene
    case effect
    case system
    case update
    case error
}

public enum Core_AppNotificationTrigger: Codable {
    case immediate
    case time(Date)
    case interval(TimeInterval)
    case calendar(DateComponents)
    case location(CLRegion)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "immediate":
            self = .immediate
        case "time":
            let date = try container.decode(Date.self, forKey: .value)
            self = .time(date)
        case "interval":
            let interval = try container.decode(TimeInterval.self, forKey: .value)
            self = .interval(interval)
        case "calendar":
            let components = try container.decode(DateComponents.self, forKey: .value)
            self = .calendar(components)
        case "location":
            let region = try container.decode(CLCircularRegion.self, forKey: .value)
            self = .location(region)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid trigger type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .immediate:
            try container.encode("immediate", forKey: .type)
        case .time(let date):
            try container.encode("time", forKey: .type)
            try container.encode(date, forKey: .value)
        case .interval(let interval):
            try container.encode("interval", forKey: .type)
            try container.encode(interval, forKey: .value)
        case .calendar(let components):
            try container.encode("calendar", forKey: .type)
            try container.encode(components, forKey: .value)
        case .location(let region):
            try container.encode("location", forKey: .type)
            if let region = region as? CLCircularRegion {
                try container.encode(region, forKey: .value)
            } else {
                throw EncodingError.invalidValue(region, EncodingError.Context(codingPath: [CodingKeys.value], debugDescription: "Only CLCircularRegion is supported"))
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }
}

// MARK: - Network Types

public enum Core_NetworkRequestMethod: String, Codable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
}

public struct Core_NetworkRequest {
    public let url: URL
    public let method: Core_NetworkRequestMethod
    public let headers: [String: String]
    public let body: Data?
    public let timeout: TimeInterval
    
    public init(
        url: URL,
        method: Core_NetworkRequestMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 30
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}

public struct Core_NetworkResponse {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?
    
    public init(
        statusCode: Int,
        headers: [String: String],
        body: Data?
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

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

// Note: The following types are defined in their respective files, so we're removing them here:
// - Effect, EffectType, EffectParameters (in Core/Types/Effect/)
// - Scene, SceneSchedule, Weekday (in Core/Types/Scene/)
// - LogEntry, LogLevel, LogCategory (in Core/Logging/) 