import CoreLocation
import Foundation
import UserNotifications
import Combine

// MARK: - Notification Types for App
// Removing duplicate typealias declarations and standardizing on Core_ prefixed versions
// public typealias InternalNotificationCategory = AppNotificationCategory
// public typealias InternalNotificationTrigger = AppNotificationTrigger

// Removing duplicate struct in favor of Core_NotificationRequest below
// public struct NotificationRequest: Identifiable, Codable {
//     public let id: String
//     public let title: String
//     public let body: String
//     public let category: AppNotificationCategory
//     public let trigger: AppNotificationTrigger
//     public let userInfo: [String: String]
//     
//     public init(
//         id: String = UUID().uuidString,
//         title: String,
//         body: String,
//         category: AppNotificationCategory,
//         trigger: AppNotificationTrigger,
//         userInfo: [String: String] = [:]
//     ) {
//         self.id = id
//         self.title = title
//         self.body = body
//         self.category = category
//         self.trigger = trigger
//         self.userInfo = userInfo
//     }
// }

// Removing duplicate enum in favor of Core_AppNotificationCategory below
// public enum AppNotificationCategory: String, Codable {
//     case device
//     case scene
//     case automation
//     case security
//     case system
// }

// Removing duplicate enum in favor of Core_AppNotificationTrigger below
// public enum AppNotificationTrigger: Codable {
//     case immediate
//     case timeInterval(TimeInterval)
//     case dateComponents(DateComponents)
//     case location(latitude: Double, longitude: Double, radius: Double)
//     
//     private enum CodingKeys: String, CodingKey {
//         case type
//         case timeInterval
//         case dateComponents
//         case latitude
//         case longitude
//         case radius
//     }
//     
//     public init(from decoder: Decoder) throws {
//         let container = try decoder.container(keyedBy: CodingKeys.self)
//         let type = try container.decode(String.self, forKey: .type)
//         
//         switch type {
//         case "immediate":
//             self = .immediate
//         case "timeInterval":
//             let interval = try container.decode(TimeInterval.self, forKey: .timeInterval)
//             self = .timeInterval(interval)
//         case "dateComponents":
//             let components = try container.decode(DateComponents.self, forKey: .dateComponents)
//             self = .dateComponents(components)
//         case "location":
//             let latitude = try container.decode(Double.self, forKey: .latitude)
//             let longitude = try container.decode(Double.self, forKey: .longitude)
//             let radius = try container.decode(Double.self, forKey: .radius)
//             self = .location(latitude: latitude, longitude: longitude, radius: radius)
//         default:
//             throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid notification trigger type")
//         }
//     }
//     
//     public func encode(to encoder: Encoder) throws {
//         var container = encoder.container(keyedBy: CodingKeys.self)
//         
//         switch self {
//         case .immediate:
//             try container.encode("immediate", forKey: .type)
//         case .timeInterval(let interval):
//             try container.encode("timeInterval", forKey: .type)
//             try container.encode(interval, forKey: .timeInterval)
//         case .dateComponents(let components):
//             try container.encode("dateComponents", forKey: .type)
//             try container.encode(components, forKey: .dateComponents)
//         case .location(let latitude, let longitude, let radius):
//             try container.encode("location", forKey: .type)
//             try container.encode(latitude, forKey: .latitude)
//             try container.encode(longitude, forKey: .longitude)
//             try container.encode(radius, forKey: .radius)
//         }
//     }
//     
//     public var unNotificationTrigger: UNNotificationTrigger? {
//         switch self {
//         case .immediate:
//             return nil
//         case .timeInterval(let interval):
//             return UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
//         case .dateComponents(let components):
//             return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
//         case .location(let latitude, let longitude, let radius):
//             let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//             let region = CLCircularRegion(center: center, radius: radius, identifier: UUID().uuidString)
//             region.notifyOnEntry = true
//             region.notifyOnExit = false
//             return UNLocationNotificationTrigger(region: region, repeats: false)
//         }
//     }
// }

// MARK: - Notification Protocols
@preconcurrency public protocol Core_NotificationManaging: Core_BaseService {
    /// Request notification authorization
    func requestAuthorization() async throws -> Core_PermissionStatus
    
    /// Get the current authorization status
    func getAuthorizationStatus() async -> Core_PermissionStatus
    
    /// Schedule a notification
    func scheduleNotification(_ notification: Core_NotificationRequest) async throws
    
    /// Cancel a notification
    func cancelNotification(withId id: String) async
    
    /// Cancel all notifications
    func cancelAllNotifications() async
    
    /// Get pending notifications
    func getPendingNotifications() async -> [Core_NotificationRequest]
    
    /// Get delivered notifications
    func getDeliveredNotifications() async -> [Core_NotificationRequest]
    
    /// Publisher for notification events
    nonisolated var notificationEvents: AnyPublisher<Core_NotificationEvent, Never> { get }
}

// MARK: - Notification Event
public enum Core_NotificationEvent: Equatable {
    case received(String)
    case responded(String, String?)
    case authorized
    case denied
}

// MARK: - Core Notification Category
public enum Core_AppNotificationCategory: String, Codable, Hashable {
    case device
    case scene
    case automation
    case security
    case system
}

// MARK: - Core Notification Trigger
public enum Core_AppNotificationTrigger: Codable, Hashable {
    case immediate
    case timeInterval(TimeInterval)
    case dateComponents(DateComponents)
    case location(latitude: Double, longitude: Double, radius: Double)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case timeInterval
        case dateComponents
        case latitude
        case longitude
        case radius
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "immediate":
            self = .immediate
        case "timeInterval":
            let interval = try container.decode(TimeInterval.self, forKey: .timeInterval)
            self = .timeInterval(interval)
        case "dateComponents":
            let components = try container.decode(DateComponents.self, forKey: .dateComponents)
            self = .dateComponents(components)
        case "location":
            let latitude = try container.decode(Double.self, forKey: .latitude)
            let longitude = try container.decode(Double.self, forKey: .longitude)
            let radius = try container.decode(Double.self, forKey: .radius)
            self = .location(latitude: latitude, longitude: longitude, radius: radius)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid notification trigger type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .immediate:
            try container.encode("immediate", forKey: .type)
        case .timeInterval(let interval):
            try container.encode("timeInterval", forKey: .type)
            try container.encode(interval, forKey: .timeInterval)
        case .dateComponents(let components):
            try container.encode("dateComponents", forKey: .type)
            try container.encode(components, forKey: .dateComponents)
        case .location(let latitude, let longitude, let radius):
            try container.encode("location", forKey: .type)
            try container.encode(latitude, forKey: .latitude)
            try container.encode(longitude, forKey: .longitude)
            try container.encode(radius, forKey: .radius)
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .immediate:
            hasher.combine(0)
        case .timeInterval(let interval):
            hasher.combine(1)
            hasher.combine(interval)
        case .dateComponents(let components):
            hasher.combine(2)
            hasher.combine(components.hashValue)
        case .location(let latitude, let longitude, let radius):
            hasher.combine(3)
            hasher.combine(latitude)
            hasher.combine(longitude)
            hasher.combine(radius)
        }
    }
    
    public static func == (lhs: Core_AppNotificationTrigger, rhs: Core_AppNotificationTrigger) -> Bool {
        switch (lhs, rhs) {
        case (.immediate, .immediate):
            return true
        case (.timeInterval(let lhsInterval), .timeInterval(let rhsInterval)):
            return lhsInterval == rhsInterval
        case (.dateComponents(let lhsComponents), .dateComponents(let rhsComponents)):
            return lhsComponents == rhsComponents
        case (.location(let lhsLat, let lhsLong, let lhsRadius), .location(let rhsLat, let rhsLong, let rhsRadius)):
            return lhsLat == rhsLat && lhsLong == rhsLong && lhsRadius == rhsRadius
        default:
            return false
        }
    }
    
    public var unNotificationTrigger: UNNotificationTrigger? {
        switch self {
        case .immediate:
            return nil
        case .timeInterval(let interval):
            return UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        case .dateComponents(let components):
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .location(let latitude, let longitude, let radius):
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = CLCircularRegion(center: center, radius: radius, identifier: UUID().uuidString)
            region.notifyOnEntry = true
            region.notifyOnExit = false
            return UNLocationNotificationTrigger(region: region, repeats: false)
        }
    }
}

// MARK: - Core Notification Request
public struct Core_NotificationRequest: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let body: String
    public let category: Core_AppNotificationCategory
    public let trigger: Core_AppNotificationTrigger
    public let userInfo: [String: String]
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        category: Core_AppNotificationCategory,
        trigger: Core_AppNotificationTrigger,
        userInfo: [String: String] = [:]
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.category = category
        self.trigger = trigger
        self.userInfo = userInfo
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Core_NotificationRequest, rhs: Core_NotificationRequest) -> Bool {
        return lhs.id == rhs.id
    }
}

// Add typealias declarations to help with transition
public typealias AppNotificationCategory = Core_AppNotificationCategory
public typealias AppNotificationTrigger = Core_AppNotificationTrigger
public typealias NotificationRequest = Core_NotificationRequest
public typealias InternalNotificationCategory = Core_AppNotificationCategory
public typealias InternalNotificationTrigger = Core_AppNotificationTrigger 
