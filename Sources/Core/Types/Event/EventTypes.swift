import Foundation
import CoreLocation

public enum Core_SecurityEvent {
    case authenticationRequired
    case authenticationSucceeded
    case authenticationFailed(Error)
    case biometricAuthenticationAvailable
    case biometricAuthenticationUnavailable
}

// Already defined elsewhere - commenting out to avoid redeclaration
/*
// Commented out to avoid ambiguity
// // Commented out to avoid ambiguity
// public enum Core_NotificationEvent {
    case received(Core_NotificationRequest)
    case scheduled(Core_NotificationRequest)
    case delivered(Core_NotificationRequest)
    case failed(Core_NotificationRequest, Error)
    case permissionGranted
    case permissionDenied
}
*/

public enum Core_SceneEvent {
    case activated(Core_Scene)
    case deactivated(Core_Scene)
    case failed(Core_Scene, Error)
}

public enum Core_DeviceEvent {
    case added(Core_Device)
    case removed(Core_Device)
    case updated(Core_Device)
    case stateChanged(Core_Device, Core_DeviceState)
    case error(Core_Device, Error)
}

public enum Core_EffectEvent {
    case started(Core_Effect, Core_Device)
    case stopped(Core_Effect, Core_Device)
    case failed(Core_Effect, Core_Device, Error)
}

// Already defined elsewhere - commenting out to avoid redeclaration
/*
// Commented out to avoid ambiguity
// // Commented out to avoid ambiguity
// public enum Core_PermissionEvent {
    case granted(Core_PermissionType)
    case denied(Core_PermissionType)
    case restricted(Core_PermissionType)
    case notDetermined(Core_PermissionType)
}
*/

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