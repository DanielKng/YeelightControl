import Foundation
import Combine

// MARK: - Device Types
// Core_Device is defined as a typealias in Device.swift

public enum Core_DeviceType: String, Codable, CaseIterable {
    case bulb
    case strip
    case lamp
    case ceiling
    case ambient
    case unknown
}

// MARK: - Device State
// Commented out to avoid ambiguity with DeviceState.swift
/*
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
*/

// Core_Color is defined in ColorTypes.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Device Protocols
// Core_DeviceManaging protocol is defined in ServiceProtocols.swift
// Removing duplicate definition to resolve ambiguity errors

// ... existing code ... 