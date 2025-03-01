// MARK: - Type Definitions
// This file contains type definitions and protocols that are used throughout the Core module.
// Many types have been moved to their own dedicated files to avoid duplication.

import Foundation
import SwiftUI
import CoreLocation
import Combine

// MARK: - Theme Types
// Core_Theme is defined in ThemeTypes.swift

// Theme-related protocols
public protocol ThemeColors {
    var primary: Color { get }
    var secondary: Color { get }
    var accent: Color { get }
    var background: Color { get }
    var text: Color { get }
    var error: Color { get }
    var success: Color { get }
    var warning: Color { get }
    var info: Color { get }
}

public protocol ThemeFonts {
    var title: Font { get }
    var headline: Font { get }
    var body: Font { get }
    var caption: Font { get }
    var button: Font { get }
}

public protocol ThemeMetrics {
    var spacing: CGFloat { get }
    var padding: CGFloat { get }
    var cornerRadius: CGFloat { get }
    var iconSize: CGFloat { get }
    var buttonHeight: CGFloat { get }
}

// MARK: - Permission Types
// Core_PermissionType is defined in PermissionTypes.swift
// Core_PermissionStatus is defined in PermissionTypes.swift

// MARK: - Notification Types
// Core_NotificationCategory is defined in NotificationTypes.swift
// Core_NotificationTrigger is defined in NotificationTypes.swift
// Core_NotificationRequest is defined in NotificationTypes.swift
// Core_NotificationEvent is defined in NotificationTypes.swift

// MARK: - Network Types
// Network types are defined in NetworkTypes.swift

// MARK: - Analytics Types
// Analytics types are defined in AnalyticsTypes.swift

// MARK: - Effect Types
// Effect types are defined in EffectTypes.swift

// MARK: - Scene Types
// Scene types are defined in SceneTypes.swift

// MARK: - Log Types
// Log types are defined in LogTypes.swift

// MARK: - Storage Types
// Storage types are defined in StorageTypes.swift

// MARK: - Configuration Types
// Configuration types are defined in ConfigurationTypes.swift

// MARK: - Device Types
// Device types are defined in DeviceTypes.swift

// MARK: - Yeelight Types
// Yeelight types are defined in YeelightTypes.swift

// MARK: - Service Types
// Service types are defined in ServiceTypes.swift 