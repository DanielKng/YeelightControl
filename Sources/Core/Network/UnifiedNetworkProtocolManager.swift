import Foundation
import Network

public protocol NetworkProtocolManaging: AnyObject {
    func connect(to endpoint: NWEndpoint)
    func disconnect()
    func send(_ command: String) async throws -> Data
    func startDiscovery()
    func stopDiscovery()
}

public final class UnifiedNetworkProtocolManager: NetworkProtocolManaging {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.yeelightcontrol.protocol")
    
    public init() {
        // Initialize without dependencies
    }
    
    public func connect(to endpoint: NWEndpoint) {
        connection = NWConnection(to: endpoint, using: .tcp)
        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }
        connection?.start(queue: queue)
    }
    
    public func disconnect() {
        connection?.cancel()
        connection = nil
    }
    
    public func send(_ command: String) async throws -> Data {
        guard let connection = connection else {
            throw NetworkError.connectionFailed
        }
        
        guard let data = command.data(using: .utf8) else {
            throw NetworkError.invalidCommand
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                self?.receiveResponse { result in
                    switch result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            })
        }
    }
    
    public func startDiscovery() {
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        
        let endpoint = NWEndpoint.hostPort(host: .init("239.255.255.250"), port: .init(integerLiteral: 1982))
        let connection = NWConnection(to: endpoint, using: parameters)
        
        connection.stateUpdateHandler = { [weak self] state in
            if state == .ready {
                self?.sendDiscoveryMessage(over: connection)
            }
        }
        
        connection.start(queue: queue)
    }
    
    public func stopDiscovery() {
        // Implementation for stopping discovery
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            print("Network connection ready")
        case .failed(let error):
            print("Network connection failed: \(error.localizedDescription)")
            disconnect()
        case .cancelled:
            print("Network connection cancelled")
        default:
            break
        }
    }
    
    private func receiveResponse(completion: @escaping (Result<Data, Error>) -> Void) {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                completion(.success(data))
            }
            
            if isComplete {
                self?.disconnect()
            }
        }
    }
    
    private func sendDiscoveryMessage(over connection: NWConnection) {
        let message = """
        M-SEARCH * HTTP/1.1\r
        HOST: 239.255.255.250:1982\r
        MAN: "ssdp:discover"\r
        ST: wifi_bulb\r
        \r\n
        """
        
        guard let data = message.data(using: .utf8) else { return }
        
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Discovery message failed: \(error.localizedDescription)")
            } else {
                print("Discovery message sent")
            }
        })
    }
}

// Define NetworkError enum if not already defined elsewhere
public enum NetworkError: Error {
    case connectionFailed
    case invalidCommand
    case invalidResponse
    case timeout
} 