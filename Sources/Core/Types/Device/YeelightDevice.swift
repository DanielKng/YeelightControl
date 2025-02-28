import Foundation

public struct YeelightDevice: Codable, Identifiable, Equatable {
    public let id: String
    public var state: DeviceState
    public var ipAddress: String
    public var port: Int
    public var model: String
    public var firmwareVersion: String
    public var supportedFeatures: Set<String>
    
    public init(id: String,
                state: DeviceState = DeviceState(),
                ipAddress: String,
                port: Int,
                model: String,
                firmwareVersion: String,
                supportedFeatures: Set<String>) {
        self.id = id
        self.state = state
        self.ipAddress = ipAddress
        self.port = port
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.supportedFeatures = supportedFeatures
    }
} 