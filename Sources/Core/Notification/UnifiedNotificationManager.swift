import Foundation
import UserNotifications
import Combine
import SwiftUI
import CoreLocation

// MARK: - Notification Managing Protocol
// Using Core_NotificationManaging protocol instead of duplicate definition
// protocol NotificationManaging {
//     var notificationSettings: NotificationSettings { get }
//     var notificationUpdates: AnyPublisher<NotificationUpdate, Never> { get }
//     
//     func requestAuthorization() async throws
//     func scheduleNotification(_ notification: AppNotification) async throws
//     func cancelNotification(withId id: String) async
//     func cancelAllNotifications() async
//     func handleNotificationResponse(_ response: UNNotificationResponse)
//     func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any]) async
// }

// MARK: - Notification Settings
// Using Core_NotificationSettings instead
struct NotificationSettings {
    let authorizationStatus: UNAuthorizationStatus
    let alertSetting: Bool
    let soundSetting: Bool
    let badgeSetting: Bool
    let criticalAlertSetting: Bool
    let providesAppNotificationSettings: Bool
}

// MARK: - App Notification
// Using Core_NotificationRequest instead of duplicate AppNotification
// struct AppNotification {
//     let id: String
//     let title: String
//     let body: String
//     let category: InternalNotificationCategory
//     let trigger: InternalNotificationTrigger
//     let userInfo: [String: Any]
//     
//     init(
//         id: String = UUID().uuidString,
//         title: String,
//         body: String,
//         category: InternalNotificationCategory,
//         trigger: InternalNotificationTrigger,
//         userInfo: [String: Any] = [:]
//     ) {
//         self.id = id
//         self.title = title
//         self.body = body
//         self.category = category
//         self.trigger = trigger
//         self.userInfo = userInfo
//     }
// }

// MARK: - Notification Category
// Using Core_AppNotificationCategory instead of duplicate NotificationCategory
enum NotificationCategory: String {
    case device = "device_notification"
    case automation = "automation_notification"
    case scene = "scene_notification"
    case effect = "effect_notification"
    case system = "system_notification"
    
    var actions: [UNNotificationAction] {
        switch self {
        case .device:
            return [
                UNNotificationAction(
                    identifier: "view_device",
                    title: "View Device",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "dismiss_device",
                    title: "Dismiss",
                    options: .destructive
                )
            ]
        case .automation:
            return [
                UNNotificationAction(
                    identifier: "view_automation",
                    title: "View Automation",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "disable_automation",
                    title: "Disable",
                    options: .destructive
                )
            ]
        case .scene, .effect:
            return [
                UNNotificationAction(
                    identifier: "apply",
                    title: "Apply",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "dismiss",
                    title: "Dismiss",
                    options: .destructive
                )
            ]
        case .system:
            return [
                UNNotificationAction(
                    identifier: "acknowledge",
                    title: "OK",
                    options: .foreground
                )
            ]
        }
    }
}

// MARK: - Notification Trigger
// Using Core_AppNotificationTrigger instead of duplicate NotificationTrigger
enum NotificationTrigger {
    case immediate
    case timeInterval(TimeInterval)
    case dateComponents(DateComponents)
    case location(CLRegion)
    
    var unNotificationTrigger: UNNotificationTrigger? {
        switch self {
        case .immediate:
            return nil
        case .timeInterval(let interval):
            return UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        case .dateComponents(let components):
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .location(let region):
            return UNLocationNotificationTrigger(region: region, repeats: false)
        }
    }
}

// MARK: - Notification Update
enum NotificationUpdate {
    case settingsChanged(NotificationSettings)
    case notificationReceived(Core_NotificationRequest) // Updated to use Core_NotificationRequest
    case notificationResponded(String, String) // id, actionIdentifier
    case authorizationChanged(Bool)
}

@MainActor
public final class UnifiedNotificationManager: NSObject, ObservableObject, Core_NotificationManaging, Core_BaseService {
    // MARK: - Published Properties
    @Published public private(set) var isNotificationsEnabled = false
    @Published public private(set) var pendingNotifications: [UNNotificationRequest] = []
    @Published public private(set) var deliveredNotifications: [UNNotification] = []
    
    // MARK: - Core_BaseService Conformance
    private var _isEnabled: Bool = true
    nonisolated public var isEnabled: Bool {
        _isEnabled
    }
    
    // MARK: - Core_NotificationManaging Protocol Properties
    public nonisolated var notificationEvents: AnyPublisher<Core_NotificationEvent, Never> {
        notificationEventsSubject.eraseToAnyPublisher()
    }
    private let notificationEventsSubject = PassthroughSubject<Core_NotificationEvent, Never>()
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let analytics: UnifiedAnalyticsManager
    private let services: BaseServiceContainer
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum Constants {
        static let deviceStateCategory = "device_state"
        static let automationCategory = "automation"
        static let errorCategory = "error"
        
        static let defaultSound = UNNotificationSound.default
        static let criticalSound = UNNotificationSound.defaultCritical
        static let logCategory = Core_LogCategory.notification
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedNotificationManager()
    
    // MARK: - Initialization
    public override init() {
        self.analytics = .shared
        self.services = .shared
        super.init()
        
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Initialize properties
        self.pendingNotifications = []
        self.deliveredNotifications = []
        
        // Request authorization if needed
        Task {
            do {
                _ = try await requestAuthorization()
            } catch {
                print("Failed to request notification authorization: \(error)")
            }
        }
    }
    
    // MARK: - Core_NotificationManaging Protocol Methods
    public func requestAuthorization() async throws -> Core_PermissionStatus {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        isNotificationsEnabled = try await notificationCenter.requestAuthorization(options: options)
        
        analytics.trackEvent(Core_AnalyticsEvent(
            type: .custom,
            parameters: ["authorized": String(isNotificationsEnabled)]
        ))
        
        return isNotificationsEnabled ? .authorized : .denied
    }
    
    public func getAuthorizationStatus() async -> Core_PermissionStatus {
        let settings = await notificationCenter.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
    
    public func scheduleNotification(_ notification: Core_NotificationRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = Constants.defaultSound
        
        // Convert dictionary to [String: Any]
        var userInfo: [String: Any] = [:]
        for (key, value) in notification.userInfo {
            userInfo[key] = value
        }
        content.userInfo = userInfo
        
        // Set category based on notification category
        switch notification.category {
        case .device:
            content.categoryIdentifier = Constants.deviceStateCategory
        case .automation:
            content.categoryIdentifier = Constants.automationCategory
        case .system:
            content.categoryIdentifier = Constants.errorCategory
        default:
            content.categoryIdentifier = notification.category.rawValue
        }
        
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: notification.trigger.unNotificationTrigger
        )
        
        try await notificationCenter.add(request)
        await refreshNotificationLists()
    }
    
    public func cancelNotification(withId id: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        await refreshNotificationLists()
    }
    
    public func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        await refreshNotificationLists()
    }
    
    public func getPendingNotifications() async -> [Core_NotificationRequest] {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        return pendingRequests.compactMap { request in
            guard let content = request.content as? UNMutableNotificationContent else { return nil }
            
            // Convert userInfo to string dictionary
            var stringUserInfo: [String: String] = [:]
            for (key, value) in content.userInfo {
                if let keyString = key as? String {
                    stringUserInfo[keyString] = String(describing: value)
                }
            }
            
            // Determine category
            let category: Core_AppNotificationCategory
            switch content.categoryIdentifier {
            case Constants.deviceStateCategory:
                category = .device
            case Constants.automationCategory:
                category = .automation
            case Constants.errorCategory:
                category = .system
            default:
                category = .system
            }
            
            // Determine trigger
            let trigger: Core_AppNotificationTrigger
            if let unTrigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                trigger = .timeInterval(unTrigger.timeInterval)
            } else if let unTrigger = request.trigger as? UNCalendarNotificationTrigger {
                trigger = .dateComponents(unTrigger.dateComponents)
            } else if let unTrigger = request.trigger as? UNLocationNotificationTrigger {
                let region = unTrigger.region
                if let circularRegion = region as? CLCircularRegion {
                    trigger = .location(
                        latitude: circularRegion.center.latitude,
                        longitude: circularRegion.center.longitude,
                        radius: circularRegion.radius
                    )
                } else {
                    trigger = .immediate
                }
            } else {
                trigger = .immediate
            }
            
            return Core_NotificationRequest(
                id: request.identifier,
                title: content.title,
                body: content.body,
                category: category,
                trigger: trigger,
                userInfo: stringUserInfo
            )
        }
    }
    
    public func getDeliveredNotifications() async -> [Core_NotificationRequest] {
        let deliveredNotifications = await notificationCenter.deliveredNotifications()
        return deliveredNotifications.compactMap { notification in
            let content = notification.request.content
            
            // Convert userInfo to string dictionary
            var stringUserInfo: [String: String] = [:]
            for (key, value) in content.userInfo {
                if let keyString = key as? String {
                    stringUserInfo[keyString] = String(describing: value)
                }
            }
            
            // Determine category
            let category: Core_AppNotificationCategory
            switch content.categoryIdentifier {
            case Constants.deviceStateCategory:
                category = .device
            case Constants.automationCategory:
                category = .automation
            case Constants.errorCategory:
                category = .system
            default:
                category = .system
            }
            
            return Core_NotificationRequest(
                id: notification.request.identifier,
                title: content.title,
                body: content.body,
                category: category,
                trigger: .immediate, // Delivered notifications don't have triggers
                userInfo: stringUserInfo
            )
        }
    }
    
    // MARK: - Legacy Public Methods
    public func scheduleDeviceStateNotification(
        title: String,
        body: String,
        deviceId: String
    ) async throws {
        // Use the Core_NotificationRequest version
        let notification = Core_NotificationRequest(
            id: "device_state_\(deviceId)_\(Date().timeIntervalSince1970)",
            title: title,
            body: body,
            category: .device,
            trigger: .immediate,
            userInfo: ["device_id": deviceId]
        )
        try await scheduleNotification(notification)
    }
    
    public func scheduleAutomationNotification(
        title: String,
        body: String,
        automationId: String
    ) async throws {
        // Use the Core_NotificationRequest version
        let notification = Core_NotificationRequest(
            id: "automation_\(automationId)_\(Date().timeIntervalSince1970)",
            title: title,
            body: body,
            category: .automation,
            trigger: .immediate,
            userInfo: ["automation_id": automationId]
        )
        try await scheduleNotification(notification)
    }
    
    public func scheduleErrorNotification(
        title: String,
        error: Error
    ) async throws {
        // Use the Core_NotificationRequest version
        let notification = Core_NotificationRequest(
            id: "error_\(Date().timeIntervalSince1970)",
            title: title,
            body: error.localizedDescription,
            category: .system,
            trigger: .immediate,
            userInfo: ["error": error.localizedDescription]
        )
        try await scheduleNotification(notification)
    }
    
    // MARK: - Private Methods
    private func refreshNotificationLists() async {
        pendingNotifications = await notificationCenter.pendingNotificationRequests()
        deliveredNotifications = await notificationCenter.deliveredNotifications()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension UnifiedNotificationManager: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Convert to Core_NotificationRequest
        let content = notification.request.content
        var stringUserInfo: [String: String] = [:]
        for (key, value) in content.userInfo {
            if let keyString = key as? String {
                stringUserInfo[keyString] = String(describing: value)
            }
        }
        
        // Determine category
        let category: Core_AppNotificationCategory
        switch content.categoryIdentifier {
        case Constants.deviceStateCategory:
            category = .device
        case Constants.automationCategory:
            category = .automation
        case Constants.errorCategory:
            category = .system
        default:
            category = .system
        }
        
        let coreNotification = Core_NotificationRequest(
            id: notification.request.identifier,
            title: content.title,
            body: content.body,
            category: category,
            trigger: .immediate,
            userInfo: stringUserInfo
        )
        
        // Emit notification received event
        notificationEventsSubject.send(.received(notification.request.identifier))
        
        // Show the notification
        completionHandler([.banner, .sound, .badge])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Emit notification responded event
        notificationEventsSubject.send(.responded(response.notification.request.identifier, response.actionIdentifier))
        
        completionHandler()
    }
}

// MARK: - Constants
extension UnifiedNotificationManager {
    static let logCategory = Core_LogCategory.notification
} 