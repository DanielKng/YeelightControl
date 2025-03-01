import Foundation
import Combine

// MARK: - Yeelight Types
public struct Core_Yeelight: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let model: String
    public let firmwareVersion: String?
    public let ipAddress: String
    public let port: Int
    public var state: Core_DeviceState
    public var isConnected: Bool
    public var lastSeen: Date
    public var supportedFeatures: [Core_YeelightFeature]
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        model: String,
        firmwareVersion: String? = nil,
        ipAddress: String,
        port: Int = 55443,
        state: Core_DeviceState = .off,
        isConnected: Bool = false,
        lastSeen: Date = Date(),
        supportedFeatures: [Core_YeelightFeature] = []
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.ipAddress = ipAddress
        self.port = port
        self.state = state
        self.isConnected = isConnected
        self.lastSeen = lastSeen
        self.supportedFeatures = supportedFeatures
    }
}

public enum Core_YeelightFeature: String, Codable, CaseIterable {
    case color
    case colorTemperature
    case brightness
    case flow
    case name
    case toggle
    case scene
    case music
    case nightLight
}

public enum Core_YeelightError: LocalizedError, Hashable {
    case notFound
    case connectionFailed
    case commandFailed
    case invalidState
    case unsupportedFeature
    case timeout
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .notFound: return "Yeelight device not found"
        case .connectionFailed: return "Yeelight connection failed"
        case .commandFailed: return "Yeelight command failed"
        case .invalidState: return "Invalid Yeelight state"
        case .unsupportedFeature: return "Unsupported Yeelight feature"
        case .timeout: return "Yeelight operation timed out"
        case .unknown: return "Unknown Yeelight error"
        }
    }
}

// MARK: - Yeelight Protocols
// Core_YeelightManaging protocol is defined in YeelightProtocols.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Yeelight Color
// Moving Core_Color to a separate file to avoid duplicate definitions
// This will be defined in a new file called ColorTypes.swift 