import Foundation
import Combine

public enum Core_ConfigKey: String, Codable, CaseIterable, Hashable {
    case appTheme
    case deviceRefreshInterval
    case analyticsEnabled
    case notificationsEnabled
    case locationEnabled
    case lastSyncDate
    case userPreferences
    case deviceSettings
    case networkSettings
    case securitySettings
    case debugMode
    case backgroundRefreshEnabled
    case sceneSettings
    case effectSettings
    case apiEndpoint
    case apiKey
}

@preconcurrency public protocol Core_ConfigurationManaging: Core_BaseService {
    nonisolated var values: [Core_ConfigKey: Any] { get }
    nonisolated var configurationUpdates: AnyPublisher<Core_ConfigKey, Never> { get }
    
    nonisolated func getValue<T>(for key: Core_ConfigKey) throws -> T
    nonisolated func setValue<T>(_ value: T, for key: Core_ConfigKey) throws
    nonisolated func removeValue(for key: Core_ConfigKey) throws
}

// Core_ConfigurationError is defined in UnifiedConfigurationManager.swift
// No need to redefine it here 