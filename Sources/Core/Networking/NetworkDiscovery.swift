import Foundation
import Network

class NetworkDiscovery: NSObject {
    static let shared = NetworkDiscovery()
    private var browser: NWBrowser?
    private var discoveredDevices: Set<String> = []
    var onDeviceFound: ((String, Int) -> Void)?
    
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    func startDiscovery(completion: @escaping (Result<Void, Error>) -> Void) {
        startDiscoveryWithRetry(retriesLeft: maxRetries, completion: completion)
    }
    
    private func startDiscoveryWithRetry(retriesLeft: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        // Start SSDP discovery
        startSSDPDiscovery { [weak self] result in
            switch result {
            case .success:
                // Start Bonjour discovery
                self?.startBonjourDiscovery { bonjourResult in
                    completion(bonjourResult)
                }
            case .failure(let error):
                if retriesLeft > 0 {
                    self?.logger.log("Discovery failed, retrying... (\(retriesLeft) attempts left)", level: .warning)
                    DispatchQueue.global().asyncAfter(deadline: .now() + self?.retryDelay ?? 2.0) {
                        self?.startDiscoveryWithRetry(retriesLeft: retriesLeft - 1, completion: completion)
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func startSSDPDiscovery(completion: @escaping (Result<Void, Error>) -> Void) {
        let multicastGroup = "239.255.255.250"
        let ssdpPort: UInt16 = 1982
        
        do {
            let connection = try NWConnection(
                to: NWEndpoint.hostPort(
                    host: NWEndpoint.Host(multicastGroup),
                    port: NWEndpoint.Port(integerLiteral: ssdpPort)
                ),
                using: .udp
            )
            
            connection.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.sendDiscoveryMessage(connection) { result in
                        completion(result)
                    }
                case .failed(let error):
                    completion(.failure(error))
                case .cancelled:
                    completion(.failure(NSError(domain: "NetworkDiscovery", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection cancelled"])))
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
        } catch {
            completion(.failure(error))
        }
    }
    
    private func sendDiscoveryMessage(_ connection: NWConnection, completion: @escaping (Result<Void, Error>) -> Void) {
        let searchMessage = """
        M-SEARCH * HTTP/1.1\r\n
        HOST: 239.255.255.250:1982\r\n
        MAN: "ssdp:discover"\r\n
        ST: wifi_bulb\r\n
        \r\n
        """
        
        connection.send(content: searchMessage.data(using: .utf8), completion: .contentProcessed { error in
            if let error = error {
                completion(.failure(error))
                connection.cancel()
            } else {
                completion(.success(()))
            }
        })
        
        // Set up a timeout
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            connection.cancel()
        }
    }
    
    private func startBonjourDiscovery() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        browser = NWBrowser(for: .bonjour(type: "_yeelight._tcp", domain: nil), using: parameters)
        browser?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Browser ready")
            case .failed(let error):
                print("Browser failed: \(error)")
            default:
                break
            }
        }
        
        browser?.browseResultsChangedHandler = { results, changes in
            for result in results {
                if case .service(let name, let type, let domain, let interface) = result.endpoint {
                    self.resolveBonjourService(name: name, type: type, domain: domain)
                }
            }
        }
        
        browser?.start(queue: .main)
    }
    
    private func resolveBonjourService(name: String, type: String, domain: String) {
        // Resolve Bonjour service to get IP and port
        NetService(domain: domain, type: type, name: name).resolve(withTimeout: 5)
    }
    
    private func listenForResponses(_ socket: NWConnection) {
        socket.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            if let data = content, let response = String(data: data, encoding: .utf8) {
                self?.parseDiscoveryResponse(response)
            }
            
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
        
        if let ip = ip, let port = port, !discoveredDevices.contains(ip) {
            discoveredDevices.insert(ip)
            DispatchQueue.main.async {
                self.onDeviceFound?(ip, port)
            }
        }
    }
}

// MARK: - Error Handling
extension NetworkDiscovery {
    enum DiscoveryError: LocalizedError {
        case timeout
        case networkUnavailable
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .timeout:
                return "Discovery timed out"
            case .networkUnavailable:
                return "Network is unavailable"
            case .invalidResponse:
                return "Received invalid response from device"
            }
        }
    }
} 