import Foundation
import Network
import Combine

/// Protocol defining network management capabilities
protocol NetworkManaging {
    /// Check if network is reachable
    var isNetworkReachable: Bool { get }
    
    /// Publisher for network status changes
    var networkStatusPublisher: AnyPublisher<NWPath.Status, Never> { get }
    
    /// Start monitoring network status
    func startMonitoring()
    
    /// Stop monitoring network status
    func stopMonitoring()
    
    /// Send data over network
    func send(_ data: Data, to endpoint: NWEndpoint) -> AnyPublisher<Data, Error>
    
    /// Listen for incoming data
    func listen(on port: UInt16) -> AnyPublisher<(Data, NWEndpoint), Error>
    
    /// Send a command to a device
    func sendCommand(_ command: String, to endpoint: NWEndpoint, completion: @escaping (Result<Data, Error>) -> Void)
    
    /// Start SSDP discovery
    func startSSDP()
    
    /// Stop SSDP discovery
    func stopSSDP()
}

/// Unified manager for handling network operations
final class UnifiedNetworkManager: NetworkManaging {
    // MARK: - Properties
    
    /// Network path monitor
    private let pathMonitor: NWPathMonitor
    
    /// Network status subject
    private let networkStatusSubject = CurrentValueSubject<NWPath.Status, Never>(.satisfied)
    
    /// Queue for network operations
    private let networkQueue = DispatchQueue(label: "com.yeelightcontrol.network", qos: .userInitiated)
    
    /// Active listeners
    private var activeListeners: [UInt16: NWListener] = [:]
    
    /// Active connections
    private var activeConnections: [String: NWConnection] = [:]
    
    /// Connection lock for thread safety
    private let connectionLock = NSLock()
    
    /// SSDP multicast address
    private let ssdpMulticastGroup = "239.255.255.250"
    
    /// SSDP port
    private let ssdpPort: UInt16 = 1982
    
    /// Message handler delegate
    private weak var messageHandler: UnifiedNetworkMessageHandler?
    
    /// Services container reference
    private let services: ServiceContainer
    
    // MARK: - NetworkManaging Properties
    
    var isNetworkReachable: Bool {
        networkStatusSubject.value == .satisfied
    }
    
    var networkStatusPublisher: AnyPublisher<NWPath.Status, Never> {
        networkStatusSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(services: ServiceContainer) {
        self.services = services
        self.pathMonitor = NWPathMonitor()
        setupPathMonitor()
    }
    
    deinit {
        stopMonitoring()
        cleanupConnections()
    }
    
    // MARK: - NetworkManaging Methods
    
    func startMonitoring() {
        pathMonitor.start(queue: networkQueue)
    }
    
    func stopMonitoring() {
        pathMonitor.cancel()
    }
    
    func send(_ data: Data, to endpoint: NWEndpoint) -> AnyPublisher<Data, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NetworkError.managerDeallocated))
                return
            }
            
            let connection = self.getOrCreateConnection(to: endpoint)
            
            connection.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.sendData(data, over: connection, promise: promise)
                case .failed(let error):
                    promise(.failure(error))
                    self?.cleanupConnection(connection)
                case .cancelled:
                    promise(.failure(NetworkError.connectionCancelled))
                    self?.cleanupConnection(connection)
                default:
                    break
                }
            }
            
            connection.start(queue: self.networkQueue)
        }
        .eraseToAnyPublisher()
    }
    
    func listen(on port: UInt16) -> AnyPublisher<(Data, NWEndpoint), Error> {
        let subject = PassthroughSubject<(Data, NWEndpoint), Error>()
        
        do {
            let parameters = NWParameters.tcp
            let listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            
            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .failed(let error):
                    subject.send(completion: .failure(error))
                    self?.cleanupListener(on: port)
                case .cancelled:
                    subject.send(completion: .finished)
                    self?.cleanupListener(on: port)
                default:
                    break
                }
            }
            
            listener.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection, subject: subject)
            }
            
            listener.start(queue: networkQueue)
            activeListeners[port] = listener
            
        } catch {
            subject.send(completion: .failure(error))
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    func sendCommand(_ command: String, to endpoint: NWEndpoint, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let data = command.data(using: .utf8) else {
            completion(.failure(NetworkError.invalidCommand))
            return
        }
        
        let connection = getOrCreateConnection(to: endpoint)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.sendData(data, over: connection) { result in
                    completion(result)
                }
            case .failed(let error):
                completion(.failure(error))
                self?.cleanupConnection(connection)
            case .cancelled:
                completion(.failure(NetworkError.connectionCancelled))
                self?.cleanupConnection(connection)
            default:
                break
            }
        }
        
        connection.start(queue: networkQueue)
    }
    
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
            activeListeners[ssdpPort] = listener
            
            sendDiscoveryMessage()
        } catch {
            services.logger.log(.error, "Failed to start SSDP: \(error)")
        }
    }
    
    func stopSSDP() {
        cleanupListener(on: ssdpPort)
    }
    
    // MARK: - Private Methods
    
    private func setupPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.networkStatusSubject.send(path.status)
            if path.status == .unsatisfied {
                self?.cleanupConnections()
            }
        }
    }
    
    private func getOrCreateConnection(to endpoint: NWEndpoint) -> NWConnection {
        connectionLock.lock()
        defer { connectionLock.unlock() }
        
        let key = endpoint.debugDescription
        if let existingConnection = activeConnections[key] {
            return existingConnection
        }
        
        let connection = NWConnection(to: endpoint, using: .tcp)
        activeConnections[key] = connection
        return connection
    }
    
    private func sendData(_ data: Data, over connection: NWConnection, promise: @escaping (Result<Data, Error>) -> Void) {
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                promise(.failure(error))
                self?.cleanupConnection(connection)
                return
            }
            
            self?.receiveResponse(on: connection, promise: promise)
        })
    }
    
    private func receiveResponse(on connection: NWConnection, promise: @escaping (Result<Data, Error>) -> Void) {
        connection.receiveMessage { [weak self] content, _, isComplete, error in
            if let error = error {
                promise(.failure(error))
                self?.cleanupConnection(connection)
                return
            }
            
            if let data = content {
                promise(.success(data))
            }
            
            if isComplete {
                self?.cleanupConnection(connection)
            }
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection, subject: PassthroughSubject<(Data, NWEndpoint), Error>) {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receiveData(on: connection, subject: subject)
            case .failed(let error):
                subject.send(completion: .failure(error))
                self?.cleanupConnection(connection)
            case .cancelled:
                self?.cleanupConnection(connection)
            default:
                break
            }
        }
        
        connection.start(queue: networkQueue)
    }
    
    private func receiveData(on connection: NWConnection, subject: PassthroughSubject<(Data, NWEndpoint), Error>) {
        connection.receiveMessage { [weak self] content, _, isComplete, error in
            if let error = error {
                subject.send(completion: .failure(error))
                self?.cleanupConnection(connection)
                return
            }
            
            if let data = content {
                subject.send((data, connection.endpoint))
            }
            
            if isComplete {
                self?.cleanupConnection(connection)
            } else {
                self?.receiveData(on: connection, subject: subject)
            }
        }
    }
    
    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            services.logger.log(.info, "SSDP listener ready")
        case .failed(let error):
            services.logger.log(.error, "SSDP listener failed: \(error)")
            stopSSDP()
        case .cancelled:
            services.logger.log(.info, "SSDP listener cancelled")
        default:
            break
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
        
        let endpoint = NWEndpoint.hostPort(host: .init(ssdpMulticastGroup), port: .init(integerLiteral: ssdpPort))
        let connection = NWConnection(to: endpoint, using: .udp)
        
        connection.stateUpdateHandler = { [weak self] state in
            if case .ready = state {
                self?.sendData(discoveryMessage.data(using: .utf8)!, over: connection) { _ in }
            }
        }
        
        connection.start(queue: networkQueue)
    }
    
    private func cleanupConnection(_ connection: NWConnection) {
        connectionLock.lock()
        defer { connectionLock.unlock() }
        
        let key = connection.endpoint.debugDescription
        connection.cancel()
        activeConnections.removeValue(forKey: key)
    }
    
    private func cleanupListener(on port: UInt16) {
        activeListeners[port]?.cancel()
        activeListeners.removeValue(forKey: port)
    }
    
    private func cleanupConnections() {
        connectionLock.lock()
        defer { connectionLock.unlock() }
        
        activeConnections.values.forEach { $0.cancel() }
        activeConnections.removeAll()
        
        activeListeners.values.forEach { $0.cancel() }
        activeListeners.removeAll()
    }
}

// MARK: - Network Errors

enum NetworkError: Error {
    case managerDeallocated
    case connectionCancelled
    case invalidEndpoint
    case timeout
    case invalidCommand
    
    var localizedDescription: String {
        switch self {
        case .managerDeallocated:
            return "Network manager was deallocated"
        case .connectionCancelled:
            return "Connection was cancelled"
        case .invalidEndpoint:
            return "Invalid network endpoint"
        case .timeout:
            return "Network operation timed out"
        case .invalidCommand:
            return "Invalid command format"
        }
    }
} 