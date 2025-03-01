import Foundation
import Combine
import CoreLocation
import Photos
import UserNotifications
import AVFoundation
import UIKit

// MARK: - Permission Types
public enum Core_AppPermissionType: String, CaseIterable, Codable {
    case location
    case notification
    case camera
    case microphone
    case photoLibrary
}

// Use the Core_PermissionStatus from PermissionTypes.swift

// MARK: - Permission Update Type
public struct Core_PermissionUpdate: Codable {
    public let type: Core_AppPermissionType
    public let status: Core_PermissionStatus
    
    public init(type: Core_AppPermissionType, status: Core_PermissionStatus) {
        self.type = type
        self.status = status
    }
    
    // Explicit implementation of Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(Core_AppPermissionType.self, forKey: .type)
        status = try container.decode(Core_PermissionStatus.self, forKey: .status)
    }
    
    // Explicit implementation of Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case status
    }
}

// MARK: - Unified Permission Manager Implementation
public final class UnifiedPermissionManager: Core_PermissionManaging {
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private let permissionSubject = PassthroughSubject<(Core_PermissionType, Core_PermissionStatus), Never>()
    private var _isEnabled: Bool = true
    
    // MARK: - Core_BaseService Implementation
    public nonisolated var isEnabled: Bool {
        return _isEnabled
    }
    
    // MARK: - Initialization
    public init() {
        locationManager.delegate = nil // We'll use one-time requests
    }
    
    // MARK: - Core_PermissionManaging Implementation
    public nonisolated var permissionUpdates: AnyPublisher<(Core_PermissionType, Core_PermissionStatus), Never> {
        return permissionSubject.eraseToAnyPublisher()
    }
    
    public func requestPermission(_ permission: Core_PermissionType) async -> Core_PermissionStatus {
        let status: Core_PermissionStatus
        
        switch permission {
        case .location:
            status = await requestLocationPermission()
        case .notification:
            status = await requestNotificationPermission()
        case .camera:
            status = await requestCameraPermission()
        case .microphone:
            status = await requestMicrophonePermission()
        case .photoLibrary:
            status = await requestPhotoLibraryPermission()
        case .bluetooth:
            // Implement bluetooth permission request if needed
            status = .notDetermined
        }
        
        // Publish the update
        permissionSubject.send((permission, status))
        
        return status
    }
    
    public func getPermissionStatus(_ permission: Core_PermissionType) async -> Core_PermissionStatus {
        switch permission {
        case .location:
            return checkLocationPermissionStatus()
        case .notification:
            return await checkNotificationPermissionStatus()
        case .camera:
            return checkCameraPermissionStatus()
        case .microphone:
            return checkMicrophonePermissionStatus()
        case .photoLibrary:
            return await checkPhotoLibraryPermissionStatus()
        case .bluetooth:
            // Implement bluetooth permission check if needed
            return .notDetermined
        }
    }
    
    public func isPermissionGranted(_ permission: Core_PermissionType) async -> Bool {
        let status = await getPermissionStatus(permission)
        return status == .authorized
    }
    
    // MARK: - Permission Request Methods
    private func requestLocationPermission() async -> Core_PermissionStatus {
        let status = locationManager.authorizationStatus
        
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            // Wait for the user's decision
            // In a real app, you'd use a continuation to wait for the delegate callback
        }
        
        return mapCLAuthorizationStatus(status)
    }
    
    private func requestNotificationPermission() async -> Core_PermissionStatus {
        do {
            let settings = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return settings ? .authorized : .denied
        } catch {
            print("Error requesting notification permission: \(error)")
            return .denied
        }
    }
    
    private func requestCameraPermission() async -> Core_PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        }
        
        return mapAVAuthorizationStatus(status)
    }
    
    private func requestMicrophonePermission() async -> Core_PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            return granted ? .authorized : .denied
        }
        
        return mapAVAuthorizationStatus(status)
    }
    
    private func requestPhotoLibraryPermission() async -> Core_PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return mapPhotoAuthorizationStatus(newStatus)
        }
        
        return mapPhotoAuthorizationStatus(status)
    }
    
    // MARK: - Permission Status Check Methods
    private func checkLocationPermissionStatus() -> Core_PermissionStatus {
        let status = locationManager.authorizationStatus
        return mapCLAuthorizationStatus(status)
    }
    
    private func checkNotificationPermissionStatus() async -> Core_PermissionStatus {
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
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
    
    private func checkCameraPermissionStatus() -> Core_PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return mapAVAuthorizationStatus(status)
    }
    
    private func checkMicrophonePermissionStatus() -> Core_PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return mapAVAuthorizationStatus(status)
    }
    
    private func checkPhotoLibraryPermissionStatus() async -> Core_PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return mapPhotoAuthorizationStatus(status)
    }
    
    private func mapPhotoAuthorizationStatus(_ status: PHAuthorizationStatus) -> Core_PermissionStatus {
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
    
    private func mapAVAuthorizationStatus(_ status: AVAuthorizationStatus) -> Core_PermissionStatus {
        switch status {
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
    
    private func mapCLAuthorizationStatus(_ status: CLAuthorizationStatus) -> Core_PermissionStatus {
        switch status {
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
} 
