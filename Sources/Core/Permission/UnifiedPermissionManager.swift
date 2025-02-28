import Foundation
import CoreLocation
import Photos
import Contacts
import AVFoundation
import UserNotifications
import Combine
import SwiftUI
import EventKit
import CoreBluetooth

// MARK: - Permission Managing Protocol
@preconcurrency public protocol PermissionManaging: Actor {
    nonisolated var permissionUpdates: AnyPublisher<PermissionUpdate, Never> { get }
    
    func checkPermission(_ type: PermissionType) async -> PermissionStatus
    func requestPermission(_ type: PermissionType) async throws -> PermissionStatus
    nonisolated func openSettings()
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

// MARK: - Permission Update
public struct PermissionUpdate: Equatable {
    public let type: PermissionType
    public let status: PermissionStatus
    public let error: Error?
    
    public static func == (lhs: PermissionUpdate, rhs: PermissionUpdate) -> Bool {
        lhs.type == rhs.type && lhs.status == rhs.status
    }
}

@MainActor
public final class UnifiedPermissionManager: NSObject, PermissionManaging {
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let photoLibrary = PHPhotoLibrary.shared()
    private let contactStore = CNContactStore()
    private let eventStore = EKEventStore()
    private let bluetoothManager = CBCentralManager()
    
    private var permissionStatuses: [PermissionType: PermissionStatus] = [:]
    private let permissionSubject = PassthroughSubject<PermissionUpdate, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    public nonisolated var permissionUpdates: AnyPublisher<PermissionUpdate, Never> {
        permissionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    public override init() {
        super.init()
        setupObservers()
    }
    
    // MARK: - Public Methods
    public func checkPermission(_ type: PermissionType) async -> PermissionStatus {
        switch type {
        case .location:
            return checkLocationPermission()
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
        case .reminders:
            return checkRemindersPermission()
        case .bluetooth:
            return checkBluetoothPermission()
        case .backgroundRefresh:
            return checkBackgroundRefreshPermission()
        case .localNetwork:
            return checkLocalNetworkPermission()
        }
    }
    
    public func requestPermission(_ type: PermissionType) async throws -> PermissionStatus {
        switch type {
        case .location:
            return try await requestLocationPermission()
        case .notification:
            return try await requestNotificationPermission()
        case .camera:
            return try await requestCameraPermission()
        case .microphone:
            return try await requestMicrophonePermission()
        case .photoLibrary:
            return try await requestPhotoLibraryPermission()
        case .contacts:
            return try await requestContactsPermission()
        case .calendar:
            return try await requestCalendarPermission()
        case .reminders:
            return try await requestRemindersPermission()
        case .bluetooth:
            return try await requestBluetoothPermission()
        case .backgroundRefresh:
            return try await requestBackgroundRefreshPermission()
        case .localNetwork:
            return try await requestLocalNetworkPermission()
        }
    }
    
    public nonisolated func openSettings() {
        Task { @MainActor in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        NotificationCenter.default.publisher(for: .locationAuthorizationChanged)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    let status = self.checkLocationPermission()
                    self.updatePermissionStatus(.location, status: status)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updatePermissionStatus(_ type: PermissionType, status: PermissionStatus) {
        permissionStatuses[type] = status
        permissionSubject.send(PermissionUpdate(type: type, status: status, error: nil))
    }
    
    private func updatePermissionError(_ type: PermissionType, error: Error) {
        let status = permissionStatuses[type] ?? .notDetermined
        permissionSubject.send(PermissionUpdate(type: type, status: status, error: error))
    }
    
    // MARK: - Permission Request Methods
    private func requestLocationPermission() async throws -> PermissionStatus {
        // Implementation for location permission request
        return .notDetermined
    }
    
    private func requestNotificationPermission() async throws -> PermissionStatus {
        // Implementation for notification permission request
        return .notDetermined
    }
    
    private func requestCameraPermission() async throws -> PermissionStatus {
        // Implementation for camera permission request
        return .notDetermined
    }
    
    private func requestMicrophonePermission() async throws -> PermissionStatus {
        // Implementation for microphone permission request
        return .notDetermined
    }
    
    private func requestPhotoLibraryPermission() async throws -> PermissionStatus {
        // Implementation for photo library permission request
        return .notDetermined
    }
    
    private func requestContactsPermission() async throws -> PermissionStatus {
        // Implementation for contacts permission request
        return .notDetermined
    }
    
    private func requestCalendarPermission() async throws -> PermissionStatus {
        // Implementation for calendar permission request
        return .notDetermined
    }
    
    private func requestRemindersPermission() async throws -> PermissionStatus {
        // Implementation for reminders permission request
        return .notDetermined
    }
    
    private func requestBluetoothPermission() async throws -> PermissionStatus {
        // Implementation for bluetooth permission request
        return .notDetermined
    }
    
    private func requestBackgroundRefreshPermission() async throws -> PermissionStatus {
        // Implementation for background refresh permission request
        return .notDetermined
    }
    
    private func requestLocalNetworkPermission() async throws -> PermissionStatus {
        // Implementation for local network permission request
        return .notDetermined
    }
    
    // MARK: - Permission Check Methods
    private func checkLocationPermission() -> PermissionStatus {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkNotificationPermission() async -> PermissionStatus {
        let settings = await notificationCenter.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .ephemeral:
            return .ephemeral
        case .provisional:
            return .provisional
        case .authorized:
            return .authorized
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
    
    private func checkRemindersPermission() -> PermissionStatus {
        // Implementation for reminders permission check
        return .notDetermined
    }
    
    private func checkBluetoothPermission() -> PermissionStatus {
        // Bluetooth permissions are handled through Info.plist
        // This is a simplified check
        return .authorized
    }
    
    private func checkBackgroundRefreshPermission() -> PermissionStatus {
        // Implementation for background refresh permission check
        return .notDetermined
    }
    
    private func checkLocalNetworkPermission() -> PermissionStatus {
        // Implementation for local network permission check
        return .notDetermined
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let locationAuthorizationChanged = Notification.Name("locationAuthorizationChanged")
} 