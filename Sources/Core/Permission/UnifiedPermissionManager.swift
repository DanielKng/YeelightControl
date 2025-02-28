import Foundation
import CoreLocation
import Photos
import Contacts
import AVFoundation
import UserNotifications
import Combine
import SwiftUI

// MARK: - Permission Managing Protocol
protocol PermissionManaging {
    var permissionUpdates: AnyPublisher<PermissionUpdate, Never> { get }
    
    func checkPermission(_ permission: Permission) async -> PermissionStatus
    func requestPermission(_ permission: Permission) async throws -> Bool
    func openSettings()
}

// MARK: - Permission Type
enum Permission: CaseIterable {
    case location
    case locationAlways
    case notification
    case camera
    case microphone
    case photoLibrary
    case contacts
    case calendar
    case bluetooth
    
    var name: String {
        switch self {
        case .location: return "Location"
        case .locationAlways: return "Location Always"
        case .notification: return "Notifications"
        case .camera: return "Camera"
        case .microphone: return "Microphone"
        case .photoLibrary: return "Photo Library"
        case .contacts: return "Contacts"
        case .calendar: return "Calendar"
        case .bluetooth: return "Bluetooth"
        }
    }
}

// MARK: - Permission Status
enum PermissionStatus {
    case notDetermined
    case denied
    case restricted
    case authorized
    case provisional
    case limited
    
    var isGranted: Bool {
        switch self {
        case .authorized, .provisional, .limited:
            return true
        default:
            return false
        }
    }
}

// MARK: - Permission Update
enum PermissionUpdate {
    case statusChanged(Permission, PermissionStatus)
    case error(Permission, Error)
}

@MainActor
public final class UnifiedPermissionManager: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published public private(set) var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published public private(set) var backgroundRefreshStatus: Bool = false
    
    // MARK: - Private Properties
    private let locationManager: UnifiedLocationManager
    private let notificationManager: UnifiedNotificationManager
    private let backgroundManager: UnifiedBackgroundManager
    private let analytics: UnifiedAnalyticsManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    public static let shared = UnifiedPermissionManager()
    
    private init() {
        self.locationManager = .shared
        self.notificationManager = .shared
        self.backgroundManager = .shared
        self.analytics = .shared
        setupObservers()
        checkPermissionStatuses()
    }
    
    // MARK: - Public Methods
    public func requestLocationPermission() async {
        locationManager.requestAuthorization()
        trackPermissionRequest(type: "location")
    }
    
    public func requestNotificationPermission() async {
        do {
            try await notificationManager.requestAuthorization()
            await checkNotificationPermission()
            trackPermissionRequest(type: "notification")
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    public func requestBackgroundRefresh() {
        backgroundManager.enableBackgroundRefresh()
        trackPermissionRequest(type: "background_refresh")
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Location permission changes
        NotificationCenter.default.publisher(for: .locationAuthorizationChanged)
            .sink { [weak self] _ in
                self?.checkLocationPermission()
            }
            .store(in: &cancellables)
        
        // Background refresh changes
        NotificationCenter.default.publisher(for: UIApplication.backgroundRefreshStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.checkBackgroundRefreshStatus()
            }
            .store(in: &cancellables)
    }
    
    private func checkPermissionStatuses() {
        checkLocationPermission()
        checkBackgroundRefreshStatus()
        
        Task {
            await checkNotificationPermission()
        }
    }
    
    private func checkLocationPermission() {
        locationPermissionStatus = CLLocationManager().authorizationStatus
    }
    
    private func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationPermissionStatus = settings.authorizationStatus
    }
    
    private func checkBackgroundRefreshStatus() {
        backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus == .available
    }
    
    private func trackPermissionRequest(type: String) {
        analytics.trackEvent(AnalyticsEvent(
            name: "permission_requested",
            parameters: ["type": type]
        ))
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let locationAuthorizationChanged = Notification.Name("locationAuthorizationChanged")
}

// MARK: - Permission Manager Implementation
final class UnifiedPermissionManager: NSObject, PermissionManaging {
    // MARK: - Publishers
    private let permissionSubject = PassthroughSubject<PermissionUpdate, Never>()
    var permissionUpdates: AnyPublisher<PermissionUpdate, Never> {
        permissionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let services: ServiceContainer
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(services: ServiceContainer = .shared) {
        self.services = services
        super.init()
        
        locationManager.delegate = self
        setupObservers()
    }
    
    // MARK: - Public Methods
    func checkPermission(_ permission: Permission) async -> PermissionStatus {
        switch permission {
        case .location:
            return checkLocationPermission()
        case .locationAlways:
            return checkLocationAlwaysPermission()
        case .notification:
            return await checkNotificationPermission()
        case .camera:
            return checkCameraPermission()
        case .microphone:
            return checkMicrophonePermission()
        case .photoLibrary:
            return await checkPhotoLibraryPermission()
        case .contacts:
            return checkContactsPermission()
        case .calendar:
            return checkCalendarPermission()
        case .bluetooth:
            return checkBluetoothPermission()
        }
    }
    
    func requestPermission(_ permission: Permission) async throws -> Bool {
        do {
            let granted = try await performPermissionRequest(permission)
            let status = await checkPermission(permission)
            permissionSubject.send(.statusChanged(permission, status))
            
            // Track analytics
            services.analyticsManager.trackEvent(AnalyticsEvent(
                name: "permission_request",
                category: .user,
                parameters: [
                    "permission": permission.name,
                    "granted": granted
                ]
            ))
            
            return granted
        } catch {
            permissionSubject.send(.error(permission, error))
            throw error
        }
    }
    
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Observe application state changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshPermissions()
            }
            .store(in: &cancellables)
    }
    
    private func refreshPermissions() {
        Task {
            for permission in Permission.allCases {
                let status = await checkPermission(permission)
                permissionSubject.send(.statusChanged(permission, status))
            }
        }
    }
    
    private func performPermissionRequest(_ permission: Permission) async throws -> Bool {
        switch permission {
        case .location:
            return await withCheckedContinuation { continuation in
                locationManager.requestWhenInUseAuthorization()
                continuation.resume(returning: true)
            }
            
        case .locationAlways:
            return await withCheckedContinuation { continuation in
                locationManager.requestAlwaysAuthorization()
                continuation.resume(returning: true)
            }
            
        case .notification:
            let center = UNUserNotificationCenter.current()
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
        case .camera:
            return try await AVCaptureDevice.requestAccess(for: .video)
            
        case .microphone:
            return try await AVCaptureDevice.requestAccess(for: .audio)
            
        case .photoLibrary:
            return try await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
            
        case .contacts:
            return try await CNContactStore().requestAccess(for: .contacts)
            
        case .calendar:
            return try await EKEventStore().requestAccess(to: .event)
            
        case .bluetooth:
            // Bluetooth permissions are handled through Info.plist
            return true
        }
    }
    
    private func checkLocationPermission() -> PermissionStatus {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkLocationAlwaysPermission() -> PermissionStatus {
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied, .authorizedWhenInUse:
            return .denied
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkNotificationPermission() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .limited
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkCameraPermission() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkMicrophonePermission() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkPhotoLibraryPermission() async -> PermissionStatus {
        let status = await PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkContactsPermission() -> PermissionStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkCalendarPermission() -> PermissionStatus {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkBluetoothPermission() -> PermissionStatus {
        // Bluetooth permissions are handled through Info.plist
        // This is a simplified check
        return .authorized
    }
}

// MARK: - CLLocationManagerDelegate
extension UnifiedPermissionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let locationStatus = checkLocationPermission()
        permissionSubject.send(.statusChanged(.location, locationStatus))
        
        let locationAlwaysStatus = checkLocationAlwaysPermission()
        permissionSubject.send(.statusChanged(.locationAlways, locationAlwaysStatus))
    }
}

// MARK: - Permission Error
enum PermissionError: LocalizedError {
    case denied(Permission)
    case restricted(Permission)
    case unavailable(Permission)
    case unknown(Permission, String)
    
    var errorDescription: String? {
        switch self {
        case .denied(let permission):
            return "\(permission.name) permission denied"
        case .restricted(let permission):
            return "\(permission.name) permission restricted"
        case .unavailable(let permission):
            return "\(permission.name) is not available"
        case .unknown(let permission, let reason):
            return "\(permission.name) permission error: \(reason)"
        }
    }
} 