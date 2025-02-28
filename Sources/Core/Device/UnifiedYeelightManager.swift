import Foundation
import Network
import Combine

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
final class UnifiedYeelightManager: ObservableObject, YeelightManaging {
    /// Published array of discovered devices
    @Published private(set) var devices: [UnifiedYeelightDevice] = []
    
    /// Services container reference
    private let services: ServiceContainer
    
    /// Set of cancellables for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialize with services container
    init(services: ServiceContainer) {
        self.services = services
        setupSubscriptions()
        setupMessageHandler()
    }
    
    /// Sets up subscriptions for device discovery and status updates
    private func setupSubscriptions() {
        services.networkManager.networkStatusPublisher
            .sink { [weak self] status in
                if status == .satisfied {
                    self?.startDiscovery()
                } else {
                    self?.stopDiscovery()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Sets up the network message handler
    private func setupMessageHandler() {
        // Implementation will be handled by the network manager
    }
    
    /// Starts device discovery
    func startDiscovery() {
        services.networkManager.startSSDP()
    }
    
    /// Stops device discovery
    func stopDiscovery() {
        services.networkManager.stopSSDP()
    }
    
    /// Controls a device's power state
    func setPower(_ isOn: Bool, for device: UnifiedYeelightDevice) {
        guard let command = formatCommand(.setPower(isOn)) else {
            services.logger.log(.error, "Failed to format power command")
            return
        }
        sendDeviceCommand(command, to: device)
    }
    
    /// Sets brightness for a device
    func setBrightness(_ level: Int, for device: UnifiedYeelightDevice) {
        let brightness = max(1, min(100, level))
        guard let command = formatCommand(.setBrightness(brightness)) else {
            services.logger.log(.error, "Failed to format brightness command")
            return
        }
        sendDeviceCommand(command, to: device)
    }
    
    /// Sets color temperature for a device
    func setColorTemperature(_ temperature: Int, for device: UnifiedYeelightDevice) {
        let temp = max(1700, min(6500, temperature))
        guard let command = formatCommand(.setColorTemperature(temp)) else {
            services.logger.log(.error, "Failed to format color temperature command")
            return
        }
        sendDeviceCommand(command, to: device)
    }
    
    /// Sets RGB color for a device
    func setColor(red: Int, green: Int, blue: Int, for device: UnifiedYeelightDevice) {
        guard let command = formatCommand(.setRGB(red, green, blue)) else {
            services.logger.log(.error, "Failed to format RGB command")
            return
        }
        sendDeviceCommand(command, to: device)
    }
    
    // MARK: - Private Methods
    
    private func sendDeviceCommand(_ command: String, to device: UnifiedYeelightDevice) {
        let endpoint = NWEndpoint.hostPort(host: .init(device.ipAddress), port: .init(integerLiteral: UInt16(device.port)))
        
        services.networkManager.sendCommand(command, to: endpoint) { [weak self] result in
            switch result {
            case .success(let data):
                self?.services.logger.log(.info, "Command successful: \(String(data: data, encoding: .utf8) ?? "")")
            case .failure(let error):
                self?.services.logger.log(.error, "Command failed: \(error)")
            }
        }
    }
    
    private func formatCommand(_ command: UnifiedYeelightCommand) -> String? {
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
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: baseCommand)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                services.logger.log(.error, "Failed to encode command as UTF-8 string")
                return nil
            }
            return jsonString + "\r\n"
        } catch {
            services.logger.log(.error, "Failed to serialize command: \(error)")
            return nil
        }
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