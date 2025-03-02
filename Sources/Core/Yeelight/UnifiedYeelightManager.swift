import Foundation
import Combine
import Network
import SwiftUI

// MARK: - Color
// Core_Color is defined in CoreYeelightTypes.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Yeelight Managing Protocol
// Core_YeelightManaging protocol is defined in YeelightProtocols.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Unified Yeelight Manager Implementation
public final class UnifiedYeelightManager: ObservableObject, Core_YeelightManaging, Core_BaseService {
    // MARK: - Properties
    private var _isEnabled: Bool = true
    nonisolated public var isEnabled: Bool {
        get {
            // Using a non-async approach to access the property
            _isEnabled
        }
    }
    @Published private var _yeelightDevices: [YeelightDevice] = []
    
    private let deviceUpdateSubject = PassthroughSubject<YeelightDeviceUpdate, Never>()
    private let storageManager: any Core_StorageManaging
    private let networkManager: any Core_NetworkManaging
    
    // Network properties
    private let discoveryPort: UInt16 = 1982
    private let commandPort: UInt16 = 55443
    private var discoveryTimer: Timer?
    private var connections: [String: NWConnection] = [:]
    private let discoveryQueue = DispatchQueue(label: "com.yeelightcontrol.discovery", qos: .utility)
    private let commandQueue = DispatchQueue(label: "com.yeelightcontrol.command", qos: .utility)
    
    // MARK: - Initialization
    public init(storageManager: any Core_StorageManaging, networkManager: any Core_NetworkManaging) {
        self.storageManager = storageManager
        self.networkManager = networkManager
        
        Task {
            await loadDevices()
        }
    }
    
    // MARK: - Core_YeelightManaging
    
    nonisolated public var devices: [YeelightDevice] {
        get {
            _yeelightDevices
        }
    }
    
    nonisolated public var deviceUpdates: AnyPublisher<YeelightDeviceUpdate, Never> {
        deviceUpdateSubject.eraseToAnyPublisher()
    }
    
    public func connect(to device: YeelightDevice) async throws {
        guard let ipAddress = device.ipAddress.isEmpty ? nil : device.ipAddress else {
            throw YeelightError.deviceNotFound
        }
        
        let host = NWEndpoint.Host(ipAddress)
        let port = NWEndpoint.Port(integerLiteral: UInt16(device.port))
        
        let connection = NWConnection(host: host, port: port, using: .tcp)
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .ready:
                    self.connections[device.id] = connection
                    
                    // Update device status
                    Task {
                        var updatedDevice = device
                        updatedDevice.isOnline = true
                        updatedDevice.lastSeen = Date()
                        try await self.updateDevice(updatedDevice)
                    }
                    
                    continuation.resume()
                    
                    // Start receiving data
                    self.receiveData(from: connection, for: device.id)
                    
                case .failed(let error):
                    continuation.resume(throwing: YeelightError.connectionFailed)
                    print("Connection failed: \(error)")
                    
                case .cancelled:
                    self.connections.removeValue(forKey: device.id)
                    
                default:
                    break
                }
            }
            
            connection.start(queue: self.commandQueue)
        }
    }
    
    public func disconnect(from device: YeelightDevice) async {
        if let connection = connections[device.id] {
            connection.cancel()
            connections.removeValue(forKey: device.id)
            
            // Update device status
            var updatedDevice = device
            updatedDevice.isOnline = false
            updatedDevice.lastSeen = Date()
            try? await updateDevice(updatedDevice)
        }
    }
    
    public func send(_ command: YeelightCommand, to device: YeelightDevice) async throws {
        guard let connection = connections[device.id] else {
            // Try to connect if not connected
            try await connect(to: device)
            guard let connection = connections[device.id] else {
                throw YeelightError.connectionFailed
            }
            return try await send(command, to: device)
        }
        
        // Convert command to JSON
        let commandDict: [String: Any] = [
            "id": command.id,
            "method": command.method,
            "params": command.params
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: commandDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw YeelightError.invalidResponse
        }
        
        // Add newline to command as required by Yeelight protocol
        let commandString = jsonString + "\r\n"
        let commandData = Data(commandString.utf8)
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: commandData, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: YeelightError.networkError(error))
                } else {
                    continuation.resume()
                }
            })
        }
    }
    
    public func discover() async throws -> [YeelightDevice] {
        // Stop any existing discovery
        stopDiscovery()
        
        // Create a new discovery session
        let discoveredDevices = await withCheckedContinuation { (continuation: CheckedContinuation<[YeelightDevice], Never>) in
            var discoveredDevices: [YeelightDevice] = []
            
            // Create UDP socket for discovery
            let listener = try? NWListener(using: .udp, on: NWEndpoint.Port(integerLiteral: discoveryPort))
            
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Listener ready for discovery")
                case .failed(let error):
                    print("Listener failed: \(error)")
                    listener?.cancel()
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                guard let self = self else { return }
                
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        print("Connection ready")
                    case .failed(let error):
                        print("Connection failed: \(error)")
                        connection.cancel()
                    default:
                        break
                    }
                }
                
                connection.receiveMessage { [weak self] (data, context, isComplete, error) in
                    guard let self = self,
                          let data = data,
                          let responseString = String(data: data, encoding: .utf8) else {
                        return
                    }
                    
                    // Parse the SSDP response
                    if let device = self.parseDiscoveryResponse(responseString, from: nil) {
                        if !discoveredDevices.contains(where: { $0.id == device.id }) {
                            discoveredDevices.append(device)
                        }
                    }
                }
                
                connection.start(queue: self.discoveryQueue)
            }
            
            listener?.start(queue: self.discoveryQueue)
            
            // Send SSDP discovery message
            self.sendDiscoveryMessage()
            
            // Set a timer to stop discovery after 5 seconds
            self.discoveryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                listener?.cancel()
                continuation.resume(returning: discoveredDevices)
            }
        }
        
        // Update the device list with newly discovered devices
        for device in discoveredDevices {
            if !_yeelightDevices.contains(where: { $0.id == device.id }) {
                _yeelightDevices.append(device)
            } else if let index = _yeelightDevices.firstIndex(where: { $0.id == device.id }) {
                _yeelightDevices[index] = device
            }
        }
        
        await saveDevices()
        return discoveredDevices
    }
    
    nonisolated public func getConnectedDevices() -> [YeelightDevice] {
        return _yeelightDevices.filter { $0.isOnline }
    }
    
    nonisolated public func getDevice(withId id: String) -> YeelightDevice? {
        return _yeelightDevices.first { $0.id == id }
    }
    
    public func updateDevice(_ device: YeelightDevice) async throws {
        if let index = _yeelightDevices.firstIndex(where: { $0.id == device.id }) {
            _yeelightDevices[index] = device
            deviceUpdateSubject.send(YeelightDeviceUpdate(deviceId: device.id, state: device.state))
            await saveDevices()
        } else {
            _yeelightDevices.append(device)
            deviceUpdateSubject.send(YeelightDeviceUpdate(deviceId: device.id, state: device.state))
            await saveDevices()
        }
    }
    
    public func clearDevices() async {
        _yeelightDevices = []
        deviceUpdateSubject.send(YeelightDeviceUpdate(deviceId: "", state: DeviceState()))
        await saveDevices()
    }
    
    // MARK: - Scene Methods
    
    public func applyScene(_ scene: Scene, to device: YeelightDevice) {
        Task {
            do {
                // Create commands based on scene properties
                let commands = createSceneCommands(for: scene, device: device)
                
                // Send each command to the device
                for command in commands {
                    try await send(command, to: device)
                    // Add a small delay between commands
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
            } catch {
                print("Failed to apply scene: \(error)")
            }
        }
    }
    
    public func stopEffect(on device: YeelightDevice) {
        Task {
            do {
                // Send command to stop any active effects
                let command = YeelightCommand(
                    id: Int.random(in: 1...1000),
                    method: "stop_cf",
                    params: []
                )
                try await send(command, to: device)
            } catch {
                print("Failed to stop effect: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    nonisolated public func getDevice(id: String) -> YeelightDevice? {
        return _yeelightDevices.first { $0.id == id }
    }
    
    // MARK: - Private Methods
    
    private func loadDevices() async {
        do {
            let storedDevices: [Core_Device]? = try await storageManager.load([Core_Device].self, forKey: "yeelight_devices")
            if let devices = storedDevices {
                // We need to implement a proper conversion from Core_Device to YeelightDevice
                _yeelightDevices = devices.map { coreDevice in
                    YeelightDevice(
                        id: coreDevice.id,
                        name: coreDevice.name,
                        model: .colorLEDBulb, // Default to color bulb, should be properly mapped
                        firmwareVersion: coreDevice.firmwareVersion ?? "unknown",
                        ipAddress: coreDevice.ipAddress ?? "unknown",
                        port: 55443, // Default Yeelight port
                        state: coreDevice.state != nil ? DeviceState.from(coreState: coreDevice.state!) : DeviceState(),
                        isOnline: coreDevice.isConnected ?? false,
                        lastSeen: coreDevice.lastSeen ?? Date()
                    )
                }
            }
            deviceUpdateSubject.send(YeelightDeviceUpdate(deviceId: "", state: DeviceState()))
        } catch {
            print("Error loading devices: \(error)")
            // Start with empty device list
            _yeelightDevices = []
            deviceUpdateSubject.send(YeelightDeviceUpdate(deviceId: "", state: DeviceState()))
        }
    }
    
    private func saveDevices() async {
        do {
            let coreDevices = _yeelightDevices.map { device -> Core_Device in
                return Core_Device(
                    id: device.id,
                    name: device.name,
                    type: .bulb,
                    manufacturer: "Yeelight",
                    model: device.model.rawValue,
                    firmwareVersion: device.firmwareVersion,
                    ipAddress: device.ipAddress,
                    macAddress: nil,
                    state: device.state.coreState,
                    isConnected: device.isOnline,
                    lastSeen: device.lastSeen
                )
            }
            try await storageManager.save(coreDevices, forKey: "yeelight_devices")
        } catch {
            print("Error saving devices: \(error)")
        }
    }
    
    // MARK: - Network Methods
    
    private func sendDiscoveryMessage() {
        // SSDP discovery message for Yeelight devices
        let discoveryMessage = """
        M-SEARCH * HTTP/1.1
        HOST: 239.255.255.250:1982
        MAN: "ssdp:discover"
        ST: wifi_bulb
        
        """
        
        let data = Data(discoveryMessage.utf8)
        
        // Create a UDP connection to the multicast address
        let connection = NWConnection(
            host: "239.255.255.250",
            port: 1982,
            using: .udp
        )
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                // Send the discovery message
                connection.send(content: data, completion: .contentProcessed { error in
                    if let error = error {
                        print("Error sending discovery message: \(error)")
                    }
                    // Close the connection after sending
                    connection.cancel()
                })
            case .failed(let error):
                print("Discovery connection failed: \(error)")
                connection.cancel()
            default:
                break
            }
        }
        
        connection.start(queue: discoveryQueue)
    }
    
    private func stopDiscovery() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil
    }
    
    private func parseDiscoveryResponse(_ response: String, from endpoint: NWEndpoint?) -> YeelightDevice? {
        // Parse the SSDP response headers
        var headers: [String: String] = [:]
        
        let lines = response.components(separatedBy: "\r\n")
        for line in lines {
            let components = line.components(separatedBy: ": ")
            if components.count == 2 {
                headers[components[0].lowercased()] = components[1]
            }
        }
        
        // Extract device information
        guard let id = headers["id"],
              let model = headers["model"],
              let firmwareVersion = headers["fw_ver"],
              let supportStr = headers["support"],
              let location = headers["location"],
              let locationComponents = URLComponents(string: location),
              let ipAddress = locationComponents.host else {
            return nil
        }
        
        // Parse supported features
        let supportedFeatures = supportStr.components(separatedBy: " ")
        
        // Determine model type
        let modelType: YeelightModel
        if model.contains("color") {
            modelType = .colorLEDBulb
        } else if model.contains("mono") {
            modelType = .monoLEDBulb
        } else if model.contains("strip") {
            modelType = .colorLEDStrip
        } else if model.contains("ceiling") {
            modelType = .ceilingLight
        } else if model.contains("desklamp") {
            modelType = .deskLamp
        } else if model.contains("bedside") {
            modelType = .bedSideLight
        } else {
            modelType = .colorLEDBulb // Default
        }
        
        // Create device state
        let state = DeviceState(
            power: headers["power"]?.lowercased() == "on",
            brightness: Int(headers["bright"] ?? "100") ?? 100,
            colorTemperature: Int(headers["ct"] ?? "4000") ?? 4000,
            color: DeviceColor.white
        )
        
        // Create and return the device
        return YeelightDevice(
            id: id,
            name: "Yeelight \(modelType.displayName)",
            model: modelType,
            firmwareVersion: firmwareVersion,
            ipAddress: ipAddress,
            port: 55443,
            state: state,
            isOnline: true,
            lastSeen: Date()
        )
    }
    
    private func receiveData(from connection: NWConnection, for deviceId: String) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, _, isComplete, error) in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                // Process the received data
                if let responseString = String(data: data, encoding: .utf8) {
                    self.processResponse(responseString, for: deviceId)
                }
                
                // Continue receiving
                self.receiveData(from: connection, for: deviceId)
            } else if let error = error {
                print("Error receiving data: \(error)")
                
                // Update device status
                if let device = self.getDevice(withId: deviceId) {
                    Task {
                        var updatedDevice = device
                        updatedDevice.isOnline = false
                        try? await self.updateDevice(updatedDevice)
                    }
                }
                
                connection.cancel()
                self.connections.removeValue(forKey: deviceId)
            } else if isComplete {
                // Connection closed
                if let device = self.getDevice(withId: deviceId) {
                    Task {
                        var updatedDevice = device
                        updatedDevice.isOnline = false
                        try? await self.updateDevice(updatedDevice)
                    }
                }
                
                connection.cancel()
                self.connections.removeValue(forKey: deviceId)
            }
        }
    }
    
    private func processResponse(_ response: String, for deviceId: String) {
        // Parse the JSON response
        guard let data = response.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // Check if it's a notification (state change)
        if let method = json["method"] as? String, method == "props" {
            if let params = json["params"] as? [String: Any] {
                // Update device state based on notification
                Task {
                    if let device = self.getDevice(withId: deviceId) {
                        var updatedDevice = device
                        var updatedState = device.state
                        
                        // Update state properties
                        if let power = params["power"] as? String {
                            updatedState.power = power.lowercased() == "on"
                        }
                        
                        if let brightness = params["bright"] as? Int {
                            updatedState.brightness = brightness
                        }
                        
                        if let ct = params["ct"] as? Int {
                            updatedState.colorTemperature = ct
                        }
                        
                        if let rgb = params["rgb"] as? Int {
                            let red = (rgb >> 16) & 0xFF
                            let green = (rgb >> 8) & 0xFF
                            let blue = rgb & 0xFF
                            updatedState.color = DeviceColor(red: red, green: green, blue: blue)
                        }
                        
                        updatedDevice.state = updatedState
                        try? await self.updateDevice(updatedDevice)
                    }
                }
            }
        }
    }
    
    private func createSceneCommands(for scene: Scene, device: YeelightDevice) -> [YeelightCommand] {
        var commands: [YeelightCommand] = []
        
        // Generate a random command ID
        let commandId = Int.random(in: 1...1000)
        
        // Create basic power on command
        commands.append(YeelightCommand(
            id: commandId,
            method: "set_power",
            params: ["on", "smooth", 500]
        ))
        
        // Set default brightness
        commands.append(YeelightCommand(
            id: commandId + 1,
            method: "set_bright",
            params: [100, "smooth", 500]
        ))
        
        // Set default color temperature
        commands.append(YeelightCommand(
            id: commandId + 2,
            method: "set_ct_abx",
            params: [4000, "smooth", 500]
        ))
        
        return commands
    }
}

// MARK: - Yeelight Error
// Core_YeelightError is defined in CoreYeelightTypes.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Device Model
// Core_Device is defined in DeviceTypes.swift
// Removing duplicate definition to resolve ambiguity errors

// MARK: - Device Type
// Core_DeviceType is defined in DeviceTypes.swift
// Removing duplicate definition to resolve ambiguity errors
