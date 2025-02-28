import Foundation
import Network
import Combine
import SwiftUI

/// Protocol defining Yeelight management capabilities
protocol YeelightManaging {
    var devices: [UnifiedYeelightDevice] { get }
    func startDiscovery()
    func stopDiscovery()
    func setPower(_ isOn: Bool, for device: UnifiedYeelightDevice)
    func setBrightness(_ level: Int, for device: UnifiedYeelightDevice)
    func setColorTemperature(_ temperature: Int, for device: UnifiedYeelightDevice)
    func setColor(red: Int, green: Int, blue: Int, for device: UnifiedYeelightDevice)
}

/// A manager responsible for managing Yeelight devices
@MainActor
public final class UnifiedYeelightManager: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var devices: [YeelightDevice] = []
    @Published public private(set) var isDiscovering = false
    
    // MARK: - Dependencies
    private weak var deviceManager: UnifiedDeviceManager?
    private weak var networkManager: UnifiedNetworkManager?
    private weak var storageManager: UnifiedStorageManager?
    
    // MARK: - Private Properties
    private var deviceConnections: [String: YeelightConnection] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private struct Constants {
        static let defaultPort: UInt16 = 55443
        static let defaultTimeout: TimeInterval = 5
        static let reconnectInterval: TimeInterval = 5
        static let maxReconnectAttempts = 3
    }
    
    // MARK: - Singleton
    public static let shared = UnifiedYeelightManager()
    
    private init() {
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    public func startDiscovery() {
        guard !isDiscovering else { return }
        isDiscovering = true
        networkManager?.startDiscovery()
    }
    
    public func stopDiscovery() {
        isDiscovering = false
        networkManager?.stopDiscovery()
    }
    
    public func setPower(_ isOn: Bool, for device: YeelightDevice) {
        guard let connection = deviceConnections[device.id] else {
            connectToDevice(device)
            return
        }
        
        let command = YeelightCommand.setPower(isOn)
        connection.send(command)
    }
    
    public func setBrightness(_ level: Int, for device: YeelightDevice) {
        guard let connection = deviceConnections[device.id] else {
            connectToDevice(device)
            return
        }
        
        let command = YeelightCommand.setBrightness(level)
        connection.send(command)
    }
    
    public func setColorTemperature(_ temperature: Int, for device: YeelightDevice) {
        guard let connection = deviceConnections[device.id] else {
            connectToDevice(device)
            return
        }
        
        let command = YeelightCommand.setColorTemperature(temperature)
        connection.send(command)
    }
    
    public func setColor(red: Int, green: Int, blue: Int, for device: YeelightDevice) {
        guard let connection = deviceConnections[device.id] else {
            connectToDevice(device)
            return
        }
        
        let command = YeelightCommand.setColor(red: red, green: green, blue: blue)
        connection.send(command)
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        networkManager?.connectionStatus
            .sink { [weak self] status in
                if case .connected = status {
                    self?.startDiscovery()
                } else {
                    self?.stopDiscovery()
                }
            }
            .store(in: &cancellables)
    }
    
    private func connectToDevice(_ device: YeelightDevice) {
        let connection = YeelightConnection(device: device)
        deviceConnections[device.id] = connection
        
        connection.stateUpdates
            .sink { [weak self] state in
                guard let self = self else { return }
                var updatedDevice = device
                updatedDevice.state = state
                self.deviceManager?.updateDevice(updatedDevice)
            }
            .store(in: &cancellables)
        
        connection.connect()
    }
}

// MARK: - Yeelight Connection
private class YeelightConnection {
    private let device: YeelightDevice
    private var socket: NWConnection?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts = 0
    
    let stateUpdates = PassthroughSubject<DeviceState, Never>()
    
    init(device: YeelightDevice) {
        self.device = device
    }
    
    func connect() {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(device.ipAddress),
            port: NWEndpoint.Port(integerLiteral: UInt16(device.port))
        )
        
        let connection = NWConnection(to: endpoint, using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }
        
        connection.start(queue: .main)
        socket = connection
    }
    
    func disconnect() {
        socket?.cancel()
        socket = nil
        reconnectTask?.cancel()
    }
    
    func send(_ command: YeelightCommand) {
        guard let socket = socket else {
            connect()
            return
        }
        
        let data = command.data
        socket.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("Failed to send command: \(error)")
                self?.handleError(error)
            }
        })
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            reconnectAttempts = 0
            // Start listening for responses
            receiveNextMessage()
            
        case .failed(let error):
            handleError(error)
            
        case .cancelled:
            socket = nil
            
        default:
            break
        }
    }
    
    private func handleError(_ error: Error) {
        print("Connection error: \(error)")
        socket?.cancel()
        socket = nil
        
        if reconnectAttempts < UnifiedYeelightManager.Constants.maxReconnectAttempts {
            reconnectTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(UnifiedYeelightManager.Constants.reconnectInterval * 1_000_000_000))
                reconnectAttempts += 1
                connect()
            }
        }
    }
    
    private func receiveNextMessage() {
        socket?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            if let error = error {
                self?.handleError(error)
                return
            }
            
            if let data = content {
                self?.handleResponse(data)
            }
            
            if !isComplete {
                self?.receiveNextMessage()
            }
        }
    }
    
    private func handleResponse(_ data: Data) {
        // Parse response and update state
        // Implementation depends on the Yeelight protocol
    }
}

// MARK: - Yeelight Command
private enum YeelightCommand {
    case setPower(Bool)
    case setBrightness(Int)
    case setColorTemperature(Int)
    case setColor(red: Int, green: Int, blue: Int)
    
    var data: Data {
        // Convert command to JSON data according to Yeelight protocol
        // Implementation depends on the specific command format
        Data()
    }
}

// MARK: - Supporting Types

/// Represents a Yeelight device
struct UnifiedYeelightDevice: Identifiable, Equatable {
    let id: String
    let ipAddress: String
    let port: Int
    var name: String
    var isOn: Bool
    var brightness: Int
    var colorTemperature: Int
    var model: String
    
    static func == (lhs: UnifiedYeelightDevice, rhs: UnifiedYeelightDevice) -> Bool {
        lhs.id == rhs.id
    }
}

/// Network manager for handling device communication
final class UnifiedNetworkManager: UnifiedNetworkMessageHandler {
    private let protocolManager = UnifiedNetworkProtocolManager.shared
    private var deviceResponses = PassthroughSubject<UnifiedYeelightDevice, Never>()
    
    init() {
        protocolManager.messageHandler = self
    }
    
    func handle(_ message: Data, from endpoint: NWEndpoint) {
        guard let response = String(data: message, encoding: .utf8) else { return }
        
        // Parse SSDP response and create device
        if let device = parseDeviceInfo(from: response, endpoint: endpoint) {
            deviceResponses.send(device)
        }
    }
    
    func sendCommand(to device: UnifiedYeelightDevice, command: UnifiedYeelightCommand) {
        let endpoint = NWEndpoint.hostPort(host: .init(device.ipAddress), port: .init(integerLiteral: UInt16(device.port)))
        
        let commandString = formatCommand(command)
        protocolManager.sendCommand(commandString, to: endpoint) { result in
            switch result {
            case .success(let data):
                print("Command successful: \(String(data: data, encoding: .utf8) ?? "")")
            case .failure(let error):
                print("Command failed: \(error)")
            }
        }
    }
    
    private func formatCommand(_ command: UnifiedYeelightCommand) -> String {
        let baseCommand: [String: Any]
        
        switch command {
        case .setPower(let isOn):
            baseCommand = [
                "id": UUID().uuidString,
                "method": "set_power",
                "params": [isOn ? "on" : "off", "smooth", 500]
            ]
        case .setBrightness(let level):
            baseCommand = [
                "id": UUID().uuidString,
                "method": "set_bright",
                "params": [level, "smooth", 500]
            ]
        case .setColorTemperature(let temp):
            baseCommand = [
                "id": UUID().uuidString,
                "method": "set_ct_abx",
                "params": [temp, "smooth", 500]
            ]
        case .setRGB(let r, let g, let b):
            let rgb = (r * 65536) + (g * 256) + b
            baseCommand = [
                "id": UUID().uuidString,
                "method": "set_rgb",
                "params": [rgb, "smooth", 500]
            ]
        }
        
        let jsonData = try! JSONSerialization.data(withJSONObject: baseCommand)
        return String(data: jsonData, encoding: .utf8)! + "\r\n"
    }
    
    private func parseDeviceInfo(from response: String, endpoint: NWEndpoint) -> UnifiedYeelightDevice? {
        // Parse the SSDP response headers
        let headers = response.components(separatedBy: "\r\n")
            .reduce(into: [String: String]()) { dict, line in
                let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    dict[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
                }
            }
        
        guard case .hostPort(let host, let port) = endpoint,
              let id = headers["id"],
              let model = headers["model"] else {
            return nil
        }
        
        return UnifiedYeelightDevice(
            id: id,
            ipAddress: host.debugDescription,
            port: Int(port.rawValue),
            name: headers["name"] ?? "Yeelight",
            isOn: headers["power"]?.lowercased() == "on",
            brightness: Int(headers["bright"] ?? "100") ?? 100,
            colorTemperature: Int(headers["ct"] ?? "4000") ?? 4000,
            model: model
        )
    }
}

/// Discovery service for finding Yeelight devices
final class UnifiedDiscoveryService {
    let discoveredDevices = PassthroughSubject<[UnifiedYeelightDevice], Never>()
    private let protocolManager = UnifiedNetworkProtocolManager.shared
    
    func startDiscovery() {
        protocolManager.startSSDP()
    }
    
    func stopDiscovery() {
        protocolManager.stopSSDP()
    }
}

/// Yeelight command enumeration
enum UnifiedYeelightCommand {
    case setPower(Bool)
    case setBrightness(Int)
    case setColorTemperature(Int)
    case setRGB(Int, Int, Int)
    // Add more commands as needed
} 