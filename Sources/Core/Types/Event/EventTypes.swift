import Foundation
import CoreLocation

public enum SecurityEvent {
    case authenticationRequired
    case authenticationSucceeded
    case authenticationFailed(Error)
    case biometricAuthenticationAvailable
    case biometricAuthenticationUnavailable
}

public enum NotificationEvent {
    case received(NotificationRequest)
    case scheduled(NotificationRequest)
    case delivered(NotificationRequest)
    case failed(NotificationRequest, Error)
    case permissionGranted
    case permissionDenied
}

public enum SceneEvent {
    case activated(Scene)
    case deactivated(Scene)
    case failed(Scene, Error)
}

public enum DeviceEvent {
    case added(YeelightDevice)
    case removed(YeelightDevice)
    case updated(YeelightDevice)
    case stateChanged(YeelightDevice, DeviceState)
    case error(YeelightDevice, Error)
}

public enum EffectEvent {
    case started(Effect, YeelightDevice)
    case stopped(Effect, YeelightDevice)
    case failed(Effect, YeelightDevice, Error)
}

public enum PermissionEvent {
    case granted(Core_PermissionType)
    case denied(Core_PermissionType)
    case restricted(Core_PermissionType)
    case notDetermined(Core_PermissionType)
}

// Deprecated - use Core_PermissionType instead
public enum Permission {
    case location
    case notification
    case camera
    case microphone
    case photoLibrary
    case bluetooth
    case calendar
    case contacts
    case reminders
    case motion
    case health
    case homeKit
}

// Deprecated - use Core_PermissionStatus instead
public enum PermissionStatus {
    case authorized
    case denied
    case restricted
    case notDetermined
} 