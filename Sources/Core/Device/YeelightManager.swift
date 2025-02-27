import Foundation
import Network
import UIKit
import Combine
import Core.Storage

/// Manages the discovery and control of Yeelight devices on the local network
class YeelightManager: ObservableObject {
    @Published private(set) var devices: [YeelightDevice] = []
    private var connections: [String: NWConnection] = [:]
    private var responseHandlers: [Int: (String) -> Void] = [:]
    private var nextCommandId = 1
    private var discoveryTimer: Timer?
    
    private let networkDiscovery = NetworkDiscovery.shared
    private let logger = Logger.shared
    
    init() {
        setupBackgroundHandling()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Device Discovery
    
    /// Starts the device discovery process
    /// - Throws: NetworkError if discovery cannot be started
    func startDiscovery() throws {
        guard NetworkStatus.shared.isWiFiEnabled else {
            throw NetworkError.noWiFiConnection
        }
        
        guard NetworkStatus.shared.hasLocalNetworkAuthorization else {
            throw NetworkError.noLocalNetworkPermission
        }
        
        discoverDevices()
        setupDiscoveryTimer()
    }
    
    /// Stops the device discovery process
    func stopDiscovery() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil
        connections.values.forEach { $0.cancel() }
        connections.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func setupBackgroundHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundTransition),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForegroundTransition),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleBackgroundTransition() {
        stopDiscovery()
        saveDeviceState()
    }
    
    @objc private func handleForegroundTransition() {
        try? startDiscovery()
        restoreDeviceState()
    }
    
    private func setupDiscoveryTimer() {
        discoveryTimer?.invalidate()
        discoveryTimer = Timer.scheduledTimer(
            withTimeInterval: 30.0,
            repeats: true
        ) { [weak self] _ in
            self?.discoverDevices()
        }
    }
    
    private func saveDeviceState() {
        // Save current device states to UserDefaults or persistent storage
        let deviceStates = devices.map { device in
            [
                "ip": device.ip,
                "isOn": device.isOn,
                "brightness": device.brightness,
                "name": device.name
            ]
        }
        UserDefaults.standard.set(deviceStates, forKey: "SavedDeviceStates")
    }
    
    private func restoreDeviceState() {
        guard let savedStates = UserDefaults.standard.array(forKey: "SavedDeviceStates") as? [[String: Any]] else {
            return
        }
        
        for state in savedStates {
            guard let ip = state["ip"] as? String,
                  let device = devices.first(where: { $0.ip == ip }) else {
                continue
            }
            
            // Restore saved state
            if let isOn = state["isOn"] as? Bool {
                device.isOn = isOn
            }
            if let brightness = state["brightness"] as? Int {
                device.brightness = brightness
            }
            if let name = state["name"] as? String {
                device.name = name
            }
        }
    }
    
    private func cleanup() {
        stopDiscovery()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Device Discovery
    func discoverDevices() {
        let multicastGroup = "239.255.255.250"
        let ssdpPort: UInt16 = 1982
        
        let connection = NWConnection(
            to: NWEndpoint.hostPort(
                host: NWEndpoint.Host(multicastGroup),
                port: NWEndpoint.Port(integerLiteral: ssdpPort)
            ),
            using: .udp
        )
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.sendDiscoveryMessage(connection)
            case .failed(let error):
                print("Connection failed: \(error)")
                connection.cancel()
            case .cancelled:
                print("Connection cancelled")
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }
    
    private func sendDiscoveryMessage(_ connection: NWConnection) {
        let searchMessage = """
        M-SEARCH * HTTP/1.1\r\n
        HOST: 239.255.255.250:1982\r\n
        MAN: "ssdp:discover"\r\n
        ST: wifi_bulb\r\n
        \r\n
        """
        
        connection.send(content: searchMessage.data(using: .utf8), completion: .contentProcessed { error in
            if let error = error {
                print("Error sending discovery message: \(error)")
                connection.cancel()
            }
        })
        
        // Set up a timer to cancel the connection after 5 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            connection.cancel()
        }
    }
    
    private func listenForResponses(_ socket: NWConnection) {
        socket.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            if let data = content, let response = String(data: data, encoding: .utf8) {
                self?.parseDiscoveryResponse(response)
            }
            
            // Continue listening for more responses if no error
            if !isComplete && error == nil {
                self?.listenForResponses(socket)
            }
        }
    }
    
    private func parseDiscoveryResponse(_ response: String) {
        let lines = response.components(separatedBy: "\r\n")
        var ip: String?
        var port: Int?
        
        for line in lines {
            if line.hasPrefix("Location: yeelight://") {
                let parts = line.replacingOccurrences(of: "Location: yeelight://", with: "").split(separator: ":")
                if parts.count == 2 {
                    ip = String(parts[0])
                    port = Int(parts[1])
                }
            }
        }
        
        if let ip = ip, let port = port {
            // Check if device already exists
            DispatchQueue.main.async { [weak self] in
                if !(self?.devices.contains(where: { $0.ip == ip })) ?? false {
                    let device = YeelightDevice(ip: ip, port: port)
                    self?.devices.append(device)
                    // Establish connection for the new device
                    self?.establishConnection(for: device)
                }
            }
        }
    }
    
    private func establishConnection(for device: YeelightDevice) {
        let connection = NWConnection(
            to: NWEndpoint.hostPort(
                host: NWEndpoint.Host(device.ip),
                port: NWEndpoint.Port(integerLiteral: UInt16(device.port))
            ),
            using: .tcp
        )
        
        connection.stateUpdateHandler = { [weak self, weak device] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    device?.connectionState = .connected
                case .preparing:
                    device?.connectionState = .connecting
                case .failed(let error), .waiting(let error):
                    device?.connectionState = .error(error)
                case .cancelled:
                    device?.connectionState = .disconnected
                default:
                    break
                }
            }
        }
        
        connections[device.ip] = connection
        connection.start(queue: .global())
    }
    
    // MARK: - Basic Controls
    func setPower(_ device: YeelightDevice, on: Bool, mode: String = "sudden", duration: Int = 0) {
        sendCommand(to: device, method: "set_power", params: [on ? "on" : "off", mode, duration, device.powerMode.rawValue])
    }
    
    func setBrightness(_ device: YeelightDevice, brightness: Int, duration: Int = 0) {
        let validBrightness = device.validateBrightness(brightness)
        sendCommand(to: device, method: "set_bright", params: [validBrightness, "smooth", duration])
    }
    
    func setColorTemperature(_ device: YeelightDevice, temperature: Int, duration: Int = 0) {
        let validTemp = device.validateColorTemp(temperature)
        sendCommand(to: device, method: "set_ct_abx", params: [validTemp, "smooth", duration])
    }
    
    func setRGB(_ device: YeelightDevice, red: Int, green: Int, blue: Int, duration: Int = 0) {
        let rgb = (red * 65536) + (green * 256) + blue
        sendCommand(to: device, method: "set_rgb", params: [rgb, "smooth", duration])
    }
    
    func setHSV(_ device: YeelightDevice, hue: Int, saturation: Int, duration: Int = 0) {
        let validHue = device.validateHue(hue)
        let validSat = device.validateSaturation(saturation)
        sendCommand(to: device, method: "set_hsv", params: [validHue, validSat, "smooth", duration])
    }
    
    // MARK: - Color Flow
    func startColorFlow(_ device: YeelightDevice, params: YeelightDevice.FlowParams) {
        let expression = params.transitions.map { transition in
            "\(transition.duration),\(transition.mode),\(transition.value),\(transition.brightness)"
        }.joined(separator: ",")
        
        sendCommand(to: device, method: "start_cf", params: [
            params.count,
            params.action.rawValue,
            expression
        ])
    }
    
    func stopColorFlow(_ device: YeelightDevice) {
        sendCommand(to: device, method: "stop_cf", params: [])
    }
    
    // MARK: - Scene Modes
    func setScene(_ device: YeelightDevice, scene: Scene) {
        var params: [Any] = [scene.type.rawValue]
        params.append(contentsOf: scene.parameters)
        sendCommand(to: device, method: "set_scene", params: params)
    }
    
    enum Scene {
        case color(red: Int, green: Int, blue: Int, brightness: Int)
        case colorTemperature(temperature: Int, brightness: Int)
        case hsv(hue: Int, saturation: Int, brightness: Int)
        case colorFlow(params: YeelightDevice.FlowParams)
        case autoDelayOff(brightness: Int, minutes: Int)
        case multiLight(MultiLightScene)
        case stripEffect(StripEffect)
        
        var type: SceneType {
            switch self {
            case .stripEffect: return .cf
            case .color: return .color
            case .colorTemperature: return .ctAbx
            case .hsv: return .hsv
            case .colorFlow: return .cf
            case .autoDelayOff: return .autoDelayOff
            case .multiLight: return .cf
            }
        }
        
        var parameters: [Any] {
            switch self {
            case .stripEffect(let effect):
                // Strip effects are handled specially
                return [0, 0, "0"] // Placeholder params
            case .color(let r, let g, let b, let brightness):
                return [(r * 65536) + (g * 256) + b, brightness]
            case .colorTemperature(let temp, let brightness):
                return [temp, brightness]
            case .hsv(let h, let s, let brightness):
                return [h, s, brightness]
            case .colorFlow(let params):
                return [params.count, params.action.rawValue, params.transitions.map { "\($0.duration),\($0.mode),\($0.value),\($0.brightness)" }.joined(separator: ",")]
            case .autoDelayOff(let brightness, let minutes):
                return [brightness, minutes]
            case .multiLight(let scene):
                return scene.parameters
            }
        }
        
        enum SceneType: Int {
            case color = 1
            case ctAbx = 2
            case hsv = 3
            case cf = 4
            case autoDelayOff = 5
        }
        
        enum MultiLightScene: String {
            case hollywood = "Hollywood"
            case dualTone = "Dual Tone"
            case rainbow = "Rainbow"
            case nightClub = "Night Club"
            case fireplace = "Fireplace"
            
            func apply(to devices: [YeelightDevice], using manager: YeelightManager) {
                switch self {
                case .hollywood:
                    // Create Hollywood effect with alternating warm and cool lights
                    for (index, device) in devices.enumerated() {
                        if index % 2 == 0 {
                            manager.setScene(device, scene: .colorFlow(params: .init(
                                count: 0,
                                action: .recover,
                                transitions: [
                                    .init(duration: 2000, mode: 1, value: 0xFF9428, brightness: 80), // Warm orange
                                    .init(duration: 2000, mode: 1, value: 0xFF7F00, brightness: 60)  // Deep orange
                                ]
                            )))
                        } else {
                            manager.setScene(device, scene: .colorFlow(params: .init(
                                count: 0,
                                action: .recover,
                                transitions: [
                                    .init(duration: 2000, mode: 1, value: 0x409CFF, brightness: 80), // Cool blue
                                    .init(duration: 2000, mode: 1, value: 0x0064FF, brightness: 60)  // Deep blue
                                ]
                            )))
                        }
                    }
                    
                case .dualTone:
                    // Split lights between warm and cool tones
                    let midPoint = devices.count / 2
                    for (index, device) in devices.enumerated() {
                        if index < midPoint {
                            manager.setScene(device, scene: .colorTemperature(temperature: 2700, brightness: 80))
                        } else {
                            manager.setScene(device, scene: .colorTemperature(temperature: 6500, brightness: 80))
                        }
                    }
                    
                case .rainbow:
                    // Distribute colors across the rainbow
                    let hueStep = 360 / devices.count
                    for (index, device) in devices.enumerated() {
                        manager.setScene(device, scene: .hsv(
                            hue: index * hueStep,
                            saturation: 100,
                            brightness: 80
                        ))
                    }
                    
                case .nightClub:
                    // Create a synchronized nightclub effect
                    for (index, device) in devices.enumerated() {
                        let delay = index * 500 // Stagger the effects
                        let params = YeelightDevice.FlowParams(
                            count: 0,
                            action: .recover,
                            transitions: [
                                .init(duration: 1000, mode: 1, value: 0xFF0000, brightness: 100), // Red
                                .init(duration: 1000, mode: 1, value: 0x0000FF, brightness: 100), // Blue
                                .init(duration: 1000, mode: 1, value: 0xFF00FF, brightness: 100)  // Purple
                            ]
                        )
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                            manager.setScene(device, scene: .colorFlow(params: params))
                        }
                    }
                    
                case .fireplace:
                    // Create a fireplace effect with multiple lights
                    for (index, device) in devices.enumerated() {
                        let params = YeelightDevice.FlowParams(
                            count: 0,
                            action: .recover,
                            transitions: [
                                .init(duration: 2000 + index * 500, mode: 1, value: 0xFF4500, brightness: 80), // Orange-red
                                .init(duration: 1500 + index * 300, mode: 1, value: 0xFF8C00, brightness: 60), // Dark orange
                                .init(duration: 1800 + index * 400, mode: 1, value: 0xFF6347, brightness: 70)  // Tomato
                            ]
                        )
                        manager.setScene(device, scene: .colorFlow(params: params))
                    }
                }
            }
        }
    }
    
    // MARK: - Music Mode
    func setMusicMode(_ device: YeelightDevice, enabled: Bool, host: String = "", port: Int = 0) {
        if enabled {
            sendCommand(to: device, method: "set_music", params: [1, host, port])
        } else {
            sendCommand(to: device, method: "set_music", params: [0])
        }
    }
    
    // MARK: - Advanced Controls
    func setDefault(_ device: YeelightDevice) {
        sendCommand(to: device, method: "set_default", params: [])
    }
    
    func startAdjust(_ device: YeelightDevice, action: AdjustAction, property: AdjustProperty) {
        sendCommand(to: device, method: "start_cf", params: [action.rawValue, property.rawValue])
    }
    
    enum AdjustAction: String {
        case increase = "increase"
        case decrease = "decrease"
        case circle = "circle"
    }
    
    enum AdjustProperty: String {
        case bright = "bright"
        case ct = "ct"
        case color = "color"
    }
    
    func setName(_ device: YeelightDevice, name: String) {
        sendCommand(to: device, method: "set_name", params: [name])
    }
    
    // MARK: - Device Control
    private func sendCommand(to device: YeelightDevice, method: String, params: [Any], completion: ((Result<String, Error>) -> Void)? = nil) {
        let commandId = nextCommandId
        nextCommandId += 1
        
        let command = [
            "id": commandId,
            "method": method,
            "params": params
        ] as [String : Any]
        
        if let completion = completion {
            responseHandlers[commandId] = { response in
                // Handle response and call completion
                completion(.success(response))
            }
        }
        
        guard let connection = connections[device.ip] else {
            establishConnection(for: device)
            return
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: command),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let commandString = jsonString + "\r\n"
            
            connection.send(content: commandString.data(using: .utf8), completion: .contentProcessed { [weak self] error in
                if let error = error {
                    print("Error sending command: \(error)")
                    self?.connections.removeValue(forKey: device.ip)
                    self?.establishConnection(for: device)
                    completion?(.failure(error))
                }
            })
        }
    }
    
    private func handleResponse(_ response: String, from device: YeelightDevice) {
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        if let id = json["id"] as? Int {
            responseHandlers[id]?(response)
            responseHandlers.removeValue(forKey: id)
        }
        
        // Update device state based on response
        DispatchQueue.main.async { [weak self] in
            if let result = json["result"] as? [Any] {
                self?.updateDeviceState(device, with: result)
            }
        }
    }
    
    private func updateDeviceState(_ device: YeelightDevice, with result: [Any]) {
        // Update device properties based on response
        if let powerStatus = result.first as? String {
            device.isOn = powerStatus == "on"
        }
        if let brightness = result.first as? Int {
            device.brightness = brightness
        }
        // Add more property updates as needed
    }
    
    func clearDevices() {
        connections.values.forEach { $0.cancel() }
        connections.removeAll()
        DispatchQueue.main.async {
            self.devices.removeAll()
        }
    }
    
    enum StripEffect {
        case colorWave
        case rainbowWave
        case chaseLights
        case matrix
        case fire
        
        func apply(to devices: [YeelightDevice], using manager: YeelightManager) {
            let totalLights = devices.count
            
            switch self {
            case .colorWave:
                // Create a smooth color wave that moves across all lights
                for (index, device) in devices.enumerated() {
                    manager.startColorFlow(device, params: .colorWave(position: index, totalLights: totalLights))
                }
                
            case .rainbowWave:
                // Create a rainbow that spans across all lights
                for (index, device) in devices.enumerated() {
                    manager.startColorFlow(device, params: .rainbowWave(position: index, totalLights: totalLights))
                }
                
            case .chaseLights:
                // Create a chase effect where one color follows another
                for (index, device) in devices.enumerated() {
                    let delay = index * 200 // 200ms delay between each light
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                        manager.setScene(device, scene: .colorFlow(params: .init(
                            count: 0,
                            action: .recover,
                            transitions: [
                                .init(duration: 500, mode: 1, value: 0xFFFFFF, brightness: 100), // White
                                .init(duration: 500, mode: 1, value: 0x000000, brightness: 1)    // Off
                            ]
                        )))
                    }
                }
                
            case .matrix:
                // Create a Matrix-style digital rain effect
                for (index, device) in devices.enumerated() {
                    let delay = Int.random(in: 0...1000) // Random start time
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                        manager.setScene(device, scene: .colorFlow(params: .init(
                            count: 0,
                            action: .recover,
                            transitions: [
                                .init(duration: 200, mode: 1, value: 0x00FF00, brightness: 100), // Bright green
                                .init(duration: 800, mode: 1, value: 0x003300, brightness: 30),  // Dark green
                                .init(duration: 200, mode: 1, value: 0x000000, brightness: 1)    // Off
                            ]
                        )))
                    }
                }
                
            case .fire:
                // Create a fire effect across all lights
                for (index, device) in devices.enumerated() {
                    let baseDelay = index * 100
                    let params = YeelightDevice.FlowParams(
                        count: 0,
                        action: .recover,
                        transitions: [
                            .init(duration: 1000 + baseDelay, mode: 1, value: 0xFF4500, brightness: 80), // Orange-red
                            .init(duration: 800 + baseDelay, mode: 1, value: 0xFF8C00, brightness: 60),  // Dark orange
                            .init(duration: 1200 + baseDelay, mode: 1, value: 0xFF6347, brightness: 70)  // Tomato
                        ]
                    )
                    manager.startColorFlow(device, params: params)
                }
            }
        }
    }
    
    func startStripEffect(_ effect: StripEffect) {
        effect.apply(to: devices, using: self)
    }
    
    func restoreDevices() {
        let savedDevices = DeviceStorage.shared.loadDevices()
        
        for (ip, savedDevice) in savedDevices {
            let device = YeelightDevice(ip: savedDevice.ip, port: savedDevice.port)
            device.name = savedDevice.name
            
            // Restore last known state
            device.isOn = savedDevice.lastKnownState.isOn
            device.brightness = savedDevice.lastKnownState.brightness
            device.colorTemperature = savedDevice.lastKnownState.colorTemperature
            device.colorMode = ColorMode(rawValue: savedDevice.lastKnownState.colorMode) ?? .temperature
            device.powerMode = PowerMode(rawValue: savedDevice.lastKnownState.powerMode) ?? .normal
            
            devices.append(device)
            establishConnection(for: device)
        }
    }
    
    func saveDeviceState(_ device: YeelightDevice, inRoom room: String) {
        DeviceStorage.shared.saveDevice(device, inRoom: room)
    }
}

// MARK: - Error Handling

extension YeelightManager {
    enum NetworkError: LocalizedError {
        case noWiFiConnection
        case noLocalNetworkPermission
        case discoveryFailed(Error)
        case connectionFailed(Error)
        case timeout
        
        var errorDescription: String? {
            switch self {
            case .noWiFiConnection:
                return "No WiFi connection available"
            case .noLocalNetworkPermission:
                return "Local network permission not granted"
            case .discoveryFailed(let error):
                return "Device discovery failed: \(error.localizedDescription)"
            case .connectionFailed(let error):
                return "Connection failed: \(error.localizedDescription)"
            case .timeout:
                return "Operation timed out"
            }
        }
    }
} 