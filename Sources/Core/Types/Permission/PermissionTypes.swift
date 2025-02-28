import Foundation

public enum PermissionType: String, Codable, Hashable {
    case location
    case notification
    case camera
    case microphone
    case photoLibrary
    case contacts
    case calendar
    case reminders
    case bluetooth
    case backgroundRefresh
    case localNetwork
}

public enum PermissionStatus: String, Codable, Hashable {
    case notDetermined
    case denied
    case restricted
    case authorized
    case provisional // For notifications
    case ephemeral  // For location
    
    public init?(rawValue: String) {
        switch rawValue {
        case "notDetermined": self = .notDetermined
        case "denied": self = .denied
        case "restricted": self = .restricted
        case "authorized": self = .authorized
        case "provisional": self = .provisional
        case "ephemeral": self = .ephemeral
        default: return nil
        }
    }
} 