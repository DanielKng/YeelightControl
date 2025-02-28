import Foundation
import Network
import Combine

/// Protocol for network message handling
protocol UnifiedNetworkMessageHandler {
    func handle(_ message: Data, from endpoint: NWEndpoint)
}

/// Manager class for network protocols including SSDP
final class UnifiedNetworkProtocolManager {
    /// Shared instance
    static let shared = UnifiedNetworkProtocolManager()
    
    /// SSDP multicast address
    private let ssdpMulticastGroup = "239.255.255.250"
    
    /// SSDP port
    private let ssdpPort: UInt16 = 1982
    
    /// UDP listener for SSDP
    private var udpListener: NWListener?
    
    /// Message handler delegate
    private weak var messageHandler: UnifiedNetworkMessageHandler?
    
    /// Connection group for managing multiple connections
    private let connectionGroup = DispatchGroup()
    
    /// Queue for handling network operations
    private let networkQueue = DispatchQueue(label: "com.yeelightcontrol.network", qos: .userInitiated)
    
    /// Initialize with optional message handler
    init(messageHandler: UnifiedNetworkMessageHandler? = nil) {
        self.messageHandler = messageHandler
    }
    
    /// Start SSDP discovery
    func startSSDP() {
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        
        do {
            let listener = try NWListener(using: parameters)
            listener.stateUpdateHandler = { [weak self] state in
                self?.handleListenerState(state)
            }
            
            listener.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener.start(queue: networkQueue)
            self.udpListener = listener
            
            // Send SSDP discovery message
            sendDiscoveryMessage()
        } catch {
            print("Failed to start SSDP listener: \(error)")
        }
    }
    
    /// Stop SSDP discovery
    func stopSSDP() {
        udpListener?.cancel()
        udpListener = nil
    }
    
    /// Send a command to a specific device
    func sendCommand(_ command: String, to endpoint: NWEndpoint, completion: @escaping (Result<Data, Error>) -> Void) {
        let connection = NWConnection(to: endpoint, using: .tcp)
        
        connection.stateUpdateHandler = { [weak self] state in
            self?.handle(connection: connection, state: state, command: command, completion: completion)
        }
        
        connection.start(queue: networkQueue)
    }
    
    // MARK: - Private Methods
    
    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            print("SSDP listener ready")
        case .failed(let error):
            print("SSDP listener failed: \(error)")
            stopSSDP()
        case .cancelled:
            print("SSDP listener cancelled")
        default:
            break
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        connection.receiveMessage { [weak self] content, context, isComplete, error in
            if let data = content, let handler = self?.messageHandler {
                handler.handle(data, from: connection.endpoint)
            }
            
            if let error = error {
                print("Error receiving message: \(error)")
            }
        }
        
        connection.start(queue: networkQueue)
    }
    
    private func handle(connection: NWConnection, state: NWConnection.State, command: String, completion: @escaping (Result<Data, Error>) -> Void) {
        switch state {
        case .ready:
            sendData(command.data(using: .utf8)!, over: connection, completion: completion)
        case .failed(let error):
            completion(.failure(error))
            connection.cancel()
        case .cancelled:
            completion(.failure(NSError(domain: "com.yeelightcontrol", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection cancelled"])))
        default:
            break
        }
    }
    
    private func sendData(_ data: Data, over connection: NWConnection, completion: @escaping (Result<Data, Error>) -> Void) {
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self?.receiveResponse(on: connection, completion: completion)
        })
    }
    
    private func receiveResponse(on connection: NWConnection, completion: @escaping (Result<Data, Error>) -> Void) {
        connection.receiveMessage { content, context, isComplete, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = content {
                completion(.success(data))
            }
            
            if isComplete {
                connection.cancel()
            }
        }
    }
    
    private func sendDiscoveryMessage() {
        let discoveryMessage = """
        M-SEARCH * HTTP/1.1\r
        HOST: \(ssdpMulticastGroup):\(ssdpPort)\r
        MAN: "ssdp:discover"\r
        ST: wifi_bulb\r
        \r\n
        """
        
        let endpoint = NWEndpoint.hostPort(host: .init(ssdpMulticastGroup), port: .init(integerLiteral: UInt16(ssdpPort)))
        let connection = NWConnection(to: endpoint, using: .udp)
        
        connection.stateUpdateHandler = { [weak self] state in
            if state == .ready {
                self?.sendData(discoveryMessage.data(using: .utf8)!, over: connection) { _ in }
            }
        }
        
        connection.start(queue: networkQueue)
    }
} 