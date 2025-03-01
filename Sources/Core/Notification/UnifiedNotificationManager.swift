import Foundation
import UserNotifications
import Combine
import SwiftUI
import CoreLocation

// MARK: - Notification Managing Protocol
protocol NotificationManaging {
    var notificationSettings: NotificationSettings { get }
    var notificationUpdates: AnyPublisher<NotificationUpdate, Never> { get }
    
    func requestAuthorization() async throws
    func scheduleNotification(_ notification: AppNotification) async throws
    func cancelNotification(withId id: String) async
    func cancelAllNotifications() async
    func handleNotificationResponse(_ response: UNNotificationResponse)
    func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any]) async
}

// MARK: - Notification Settings
struct NotificationSettings {
    let authorizationStatus: UNAuthorizationStatus
    let alertSetting: Bool
    let soundSetting: Bool
    let badgeSetting: Bool
    let criticalAlertSetting: Bool
    let providesAppNotificationSettings: Bool
}

// MARK: - App Notification
struct AppNotification {
    let id: String
    let title: String
    let body: String
    let category: InternalNotificationCategory
    let trigger: InternalNotificationTrigger
    let userInfo: [String: Any]
    
    init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        category: InternalNotificationCategory,
        trigger: InternalNotificationTrigger,
        userInfo: [String: Any] = [:]
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.category = category
        self.trigger = trigger
        self.userInfo = userInfo
    }
}

// MARK: - Notification Category
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
enum NotificationTrigger {
    case immediate
    case timeInterval(TimeInterval)
    case dateComponents(DateComponents)
    case location(CLRegion)
    
    var unTrigger: UNNotificationTrigger? {
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
    case notificationReceived(AppNotification)
    case notificationResponded(String, String) // id, actionIdentifier
    case authorizationChanged(Bool)
}

@MainActor
public final class UnifiedNotificationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var isNotificationsEnabled = false
    @Published public private(set) var pendingNotifications: [UNNotificationRequest] = []
    @Published public private(set) var deliveredNotifications: [UNNotification] = []
    
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
            await requestAuthorization()
        }
    }
    
    // MARK: - Public Methods
    public func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        isNotificationsEnabled = try await notificationCenter.requestAuthorization(options: options)
        
        analytics.trackEvent(AnalyticsEvent(
            name: "notification_authorization_requested",
            parameters: ["authorized": String(isNotificationsEnabled)]
        ))
    }
    
    public func scheduleDeviceStateNotification(
        title: String,
        body: String,
        deviceId: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = Constants.defaultSound
        content.categoryIdentifier = Constants.deviceStateCategory
        content.userInfo = ["device_id": deviceId]
        
        let request = UNNotificationRequest(
            identifier: "device_state_\(deviceId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try await notificationCenter.add(request)
        await refreshNotificationLists()
    }
    
    public func scheduleAutomationNotification(
        title: String,
        body: String,
        automationId: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = Constants.defaultSound
        content.categoryIdentifier = Constants.automationCategory
        content.userInfo = ["automation_id": automationId]
        
        let request = UNNotificationRequest(
            identifier: "automation_\(automationId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try await notificationCenter.add(request)
        await refreshNotificationLists()
    }
    
    public func scheduleErrorNotification(
        title: String,
        error: Error
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = error.localizedDescription
        content.sound = Constants.criticalSound
        content.categoryIdentifier = Constants.errorCategory
        
        let request = UNNotificationRequest(
            identifier: "error_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        try await notificationCenter.add(request)
        await refreshNotificationLists()
    }
    
    public func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        pendingNotifications.removeAll()
    }
    
    public func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        deliveredNotifications.removeAll()
    }
    
    // MARK: - Private Methods
    private func checkNotificationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            isNotificationsEnabled = settings.authorizationStatus == .authorized
        }
    }
    
    private func refreshNotificationLists() async {
        async let pending = notificationCenter.pendingNotificationRequests()
        async let delivered = notificationCenter.deliveredNotifications()
        
        let (pendingList, deliveredList) = await (pending, delivered)
        pendingNotifications = pendingList
        deliveredNotifications = deliveredList
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension UnifiedNotificationManager: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        analytics.trackEvent(AnalyticsEvent(
            name: "notification_presented",
            parameters: [
                "category": notification.request.content.categoryIdentifier,
                "id": notification.request.identifier
            ]
        ))
        
        await refreshNotificationLists()
        return [.banner, .sound, .badge]
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        analytics.trackEvent(AnalyticsEvent(
            name: "notification_response",
            parameters: [
                "category": response.notification.request.content.categoryIdentifier,
                "id": response.notification.request.identifier,
                "action": response.actionIdentifier
            ]
        ))
        
        await refreshNotificationLists()
    }
}

// MARK: - Logger Category Extension
extension Core_LogCategory {
    static let notification = LogCategory.notification
}

// MARK: - Constants
extension UnifiedNotificationManager {
    static let logCategory = Core_LogCategory.notification
} 