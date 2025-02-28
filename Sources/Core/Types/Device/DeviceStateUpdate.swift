import Foundation

public struct DeviceStateUpdate: Codable, Equatable {
    public let deviceId: String
    public let oldState: DeviceState
    public let newState: DeviceState
    public let timestamp: Date
    
    public init(deviceId: String, oldState: DeviceState, newState: DeviceState, timestamp: Date = Date()) {
        self.deviceId = deviceId
        self.oldState = oldState
        self.newState = newState
        self.timestamp = timestamp
    }
} 