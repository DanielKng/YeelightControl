import Foundation
import Combine

public enum Core_ConfigKey: String, Codable, CaseIterable {
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
}

@preconcurrency public protocol Core_ConfigurationManaging: Core_BaseService {
    var values: [Core_ConfigKey: Any] { get }
    var configurationUpdates: AnyPublisher<Core_ConfigKey, Never> { get }
    
    func getValue<T>(for key: Core_ConfigKey) throws -> T
    func setValue<T>(_ value: T, for key: Core_ConfigKey) throws
    func removeValue(for key: Core_ConfigKey) throws
}

// Core_ConfigurationError is defined in ErrorTypes.swift
// No need to redefine it here 