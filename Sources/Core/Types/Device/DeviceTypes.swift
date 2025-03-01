import Foundation
import Combine

// MARK: - Device Types
public struct Core_Device: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let type: Core_DeviceType
    public let manufacturer: String
    public let model: String
    public let firmwareVersion: String?
    public let ipAddress: String?
    public let macAddress: String?
    public var state: Core_DeviceState
    public var isConnected: Bool
    public var lastSeen: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: Core_DeviceType,
        manufacturer: String,
        model: String,
        firmwareVersion: String? = nil,
        ipAddress: String? = nil,
        macAddress: String? = nil,
        state: Core_DeviceState = .unknown,
        isConnected: Bool = false,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.manufacturer = manufacturer
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.state = state
        self.isConnected = isConnected
        self.lastSeen = lastSeen
    }
}

public enum Core_DeviceType: String, Codable, CaseIterable {
    case bulb
    case strip
    case lamp
    case ceiling
    case ambient
    case unknown
}

// MARK: - Device State
public enum Core_DeviceState: Codable, Hashable {
    case off
    case on(brightness: Int, color: Core_Color)
    case unknown
    
    public var isOn: Bool {
        switch self {
        case .on:
            return true
        case .off, .unknown:
            return false
        }
    }
    
    public var brightness: Int {
        switch self {
        case .on(let brightness, _):
            return brightness
        case .off, .unknown:
            return 0
        }
    }
    
    public var color: Core_Color {
        switch self {
        case .on(_, let color):
            return color
        case .off, .unknown:
            return .white
        }
    }
}

// Core_Color is defined in ColorTypes.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Device Protocols
// Core_DeviceManaging protocol is defined in ServiceProtocols.swift
// Removing duplicate definition to resolve ambiguity errors

// ... existing code ... 