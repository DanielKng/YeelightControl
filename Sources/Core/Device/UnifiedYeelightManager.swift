import Foundation
import Network
import Combine
import Core

@preconcurrency protocol YeelightManaging: Actor {
    nonisolated var devices: [UnifiedYeelightDevice] { get }
    func startDiscovery()
    func stopDiscovery()
    func setPower(_ isOn: Bool, for device: UnifiedYeelightDevice) async
    func setBrightness(_ level: Int, for device: UnifiedYeelightDevice) async
    func setColorTemperature(_ temperature: Int, for device: UnifiedYeelightDevice) async
    func setColor(red: Int, green: Int, blue: Int, for device: UnifiedYeelightDevice) async
}

/// A manager responsible for managing Yeelight devices
@MainActor
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
        services.networkManager.messageHandler = self
    }
    
    /// Sets up subscriptions for device discovery and status updates
    private func setupSubscriptions() {
        services.networkManager.networkStatusPublisher
            .sink { [weak self] status in
                Task { @MainActor [weak self] in
                    if status == .satisfied {
                        self?.startDiscovery()
                    } else {
                        self?.stopDiscovery()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Starts device discovery
    nonisolated func startDiscovery() {
        services.networkManager.startSSDP()
    }
    
    /// Stops device discovery
    nonisolated func stopDiscovery() {
        services.networkManager.stopSSDP()
    }
    
    /// Controls a device's power state
    func setPower(_ isOn: Bool, for device: UnifiedYeelightDevice) async {
        guard let command = formatCommand(.setPower(isOn)) else {
            await services.logger.log(.error, "Failed to format power command")
            return
        }
        await sendDeviceCommand(command, to: device)
    }
    
    /// Sets brightness for a device
    func setBrightness(_ level: Int, for device: UnifiedYeelightDevice) async {
        let brightness = max(1, min(100, level))
        guard let command = formatCommand(.setBrightness(brightness)) else {
            await services.logger.log(.error, "Failed to format brightness command")
            return
        }
        await sendDeviceCommand(command, to: device)
    }
    
    /// Sets color temperature for a device
    func setColorTemperature(_ temperature: Int, for device: UnifiedYeelightDevice) async {
        let temp = max(1700, min(6500, temperature))
        guard let command = formatCommand(.setColorTemperature(temp)) else {
            await services.logger.log(.error, "Failed to format color temperature command")
            return
        }
        await sendDeviceCommand(command, to: device)
    }
    
    /// Sets RGB color for a device
    func setColor(red: Int, green: Int, blue: Int, for device: UnifiedYeelightDevice) async {
        guard let command = formatCommand(.setRGB(red, green, blue)) else {
            await services.logger.log(.error, "Failed to format RGB command")
            return
        }
        await sendDeviceCommand(command, to: device)
    }
}

// MARK: - UnifiedNetworkMessageHandler

extension UnifiedYeelightManager: UnifiedNetworkMessageHandler {
    nonisolated func handle(_ message: Data, from endpoint: NWEndpoint) {
        guard let response = String(data: message, encoding: .utf8) else { return }
        
        if let device = parseDeviceInfo(from: response, endpoint: endpoint) {
            Task { @MainActor [weak self] in
                if let index = self?.devices.firstIndex(where: { $0.id == device.id }) {
                    self?.devices[index] = device
                } else {
                    self?.devices.append(device)
                }
            }
        }
    }
}

// MARK: - Private Methods

private extension UnifiedYeelightManager {
    func sendDeviceCommand(_ command: String, to device: UnifiedYeelightDevice) async {
        let endpoint = NWEndpoint.hostPort(host: .init(device.ipAddress), port: .init(integerLiteral: UInt16(device.port)))
        
        do {
            let data = try await services.networkManager.sendCommand(command, to: endpoint)
            await services.logger.log(.info, "Command successful: \(String(data: data, encoding: .utf8) ?? "")")
        } catch {
            await services.logger.log(.error, "Command failed: \(error)")
        }
    }
    
    nonisolated func formatCommand(_ command: UnifiedYeelightCommand) -> String? {
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
                Task { @MainActor in
                    await services.logger.log(.error, "Failed to encode command as UTF-8 string")
                }
                return nil
            }
            return jsonString + "\r\n"
        } catch {
            Task { @MainActor in
                await services.logger.log(.error, "Failed to serialize command: \(error)")
            }
            return nil
        }
    }
    
    nonisolated func parseDeviceInfo(from response: String, endpoint: NWEndpoint) -> UnifiedYeelightDevice? {
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

/// Yeelight command enumeration
enum UnifiedYeelightCommand {
    case setPower(Bool)
    case setBrightness(Int)
    case setColorTemperature(Int)
    case setRGB(Int, Int, Int)
} 