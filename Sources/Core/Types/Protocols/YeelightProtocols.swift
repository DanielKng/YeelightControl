import Foundation
import Combine

// Create a typealias to disambiguate types
public typealias CoreYeelightManaging = Core_YeelightManaging

public protocol LegacyServiceBase: Core_BaseService {
    var isEnabled: Bool { get set }
}

@preconcurrency public protocol Core_YeelightManaging: Core_BaseService {
    nonisolated var devices: [YeelightDevice] { get }
    nonisolated var deviceUpdates: AnyPublisher<YeelightDeviceUpdate, Never> { get }
    
    func connect(to device: YeelightDevice) async throws
    func disconnect(from device: YeelightDevice) async
    func send(_ command: YeelightCommand, to device: YeelightDevice) async throws
    func discover() async throws -> [YeelightDevice]
    nonisolated func getConnectedDevices() -> [YeelightDevice]
    nonisolated func getDevice(withId id: String) -> YeelightDevice?
    func updateDevice(_ device: YeelightDevice) async throws
    func clearDevices() async
} 