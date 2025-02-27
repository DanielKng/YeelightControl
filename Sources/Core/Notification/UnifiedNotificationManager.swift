import Foundation
import UserNotifications
import Combine

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
    let category: NotificationCategory
    let trigger: NotificationTrigger
    let userInfo: [String: Any]
    
    init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        category: NotificationCategory,
        trigger: NotificationTrigger,
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

// MARK: - Notification Manager Implementation
final class UnifiedNotificationManager: NSObject, NotificationManaging {
    // MARK: - Published Properties
    @Published private(set) var notificationSettings: NotificationSettings = NotificationSettings(
        authorizationStatus: .notDetermined,
        alertSetting: false,
        soundSetting: false,
        badgeSetting: false,
        criticalAlertSetting: false,
        providesAppNotificationSettings: false
    )
    
    // MARK: - Publishers
    private let notificationSubject = PassthroughSubject<NotificationUpdate, Never>()
    var notificationUpdates: AnyPublisher<NotificationUpdate, Never> {
        notificationSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let services: ServiceContainer
    private let center = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private struct Configuration {
        var defaultSound = true
        var defaultBadge = true
        var criticalAlertsEnabled = false
        var provisionalEnabled = true
        var announcementsEnabled = false
    }
    
    private let config = Configuration()
    
    // MARK: - Initialization
    init(services: ServiceContainer = .shared) {
        self.services = services
        super.init()
        
        center.delegate = self
        setupCategories()
        refreshSettings()
    }
    
    // MARK: - Public Methods
    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [
            .alert,
            .sound,
            .badge,
            config.criticalAlertsEnabled ? .criticalAlert : [],
            config.provisionalEnabled ? .provisional : [],
            config.announcementsEnabled ? .announcement : []
        ]
        
        let granted = try await center.requestAuthorization(options: options)
        notificationSubject.send(.authorizationChanged(granted))
        await refreshSettings()
    }
    
    func scheduleNotification(_ notification: AppNotification) async throws {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.categoryIdentifier = notification.category.rawValue
        content.userInfo = notification.userInfo
        
        if config.defaultSound {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: notification.trigger.unTrigger
        )
        
        try await center.add(request)
        services.logger.info("Scheduled notification: \(notification.title)", category: .notification)
    }
    
    func cancelNotification(withId id: String) async {
        await center.removePendingNotificationRequests(withIdentifiers: [id])
        services.logger.info("Cancelled notification: \(id)", category: .notification)
    }
    
    func cancelAllNotifications() async {
        await center.removeAllPendingNotificationRequests()
        services.logger.info("Cancelled all notifications", category: .notification)
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let notification = response.notification
        let userInfo = notification.request.content.userInfo
        let id = notification.request.identifier
        
        notificationSubject.send(.notificationResponded(id, response.actionIdentifier))
        services.logger.info("Handled notification response: \(response.actionIdentifier)", category: .notification)
        
        // Track analytics
        services.analyticsManager.trackEvent(AnalyticsEvent(
            name: "notification_response",
            category: .user,
            parameters: [
                "notification_id": id,
                "action": response.actionIdentifier,
                "category": notification.request.content.categoryIdentifier
            ]
        ))
    }
    
    func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        guard let title = userInfo["title"] as? String,
              let body = userInfo["body"] as? String,
              let categoryString = userInfo["category"] as? String,
              let category = NotificationCategory(rawValue: categoryString) else {
            services.logger.error("Invalid remote notification format", category: .notification)
            return
        }
        
        let notification = AppNotification(
            title: title,
            body: body,
            category: category,
            trigger: .immediate,
            userInfo: userInfo as? [String: Any] ?? [:]
        )
        
        notificationSubject.send(.notificationReceived(notification))
        services.logger.info("Received remote notification: \(title)", category: .notification)
    }
    
    // MARK: - Private Methods
    private func setupCategories() {
        let categories = NotificationCategory.allCases.map { category in
            UNNotificationCategory(
                identifier: category.rawValue,
                actions: category.actions,
                intentIdentifiers: [],
                options: .customDismissAction
            )
        }
        
        center.setNotificationCategories(Set(categories))
    }
    
    private func refreshSettings() async {
        let settings = await center.notificationSettings()
        
        let newSettings = NotificationSettings(
            authorizationStatus: settings.authorizationStatus,
            alertSetting: settings.alertSetting == .enabled,
            soundSetting: settings.soundSetting == .enabled,
            badgeSetting: settings.badgeSetting == .enabled,
            criticalAlertSetting: settings.criticalAlertSetting == .enabled,
            providesAppNotificationSettings: settings.providesAppNotificationSettings
        )
        
        notificationSettings = newSettings
        notificationSubject.send(.settingsChanged(newSettings))
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension UnifiedNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let content = notification.request.content
        
        let notification = AppNotification(
            id: notification.request.identifier,
            title: content.title,
            body: content.body,
            category: NotificationCategory(rawValue: content.categoryIdentifier) ?? .system,
            trigger: .immediate,
            userInfo: content.userInfo
        )
        
        notificationSubject.send(.notificationReceived(notification))
        
        return [.banner, .sound, .badge]
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        handleNotificationResponse(response)
    }
}

// MARK: - Logger Category Extension
extension LogCategory {
    static let notification: LogCategory = "notification"
} 