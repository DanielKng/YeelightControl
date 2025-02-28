import Foundation
import Network
import Combine
import SwiftUI

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

@MainActor
public final class UnifiedNetworkManager: ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var isDiscoveryActive = false
    @Published public private(set) var isNetworkReachable = false
    @Published public private(set) var connectionStatus: ConnectionStatus = .disconnected
    
    // MARK: - Public Properties
    public weak var messageHandler: NetworkMessageHandler?
    
    // MARK: - Private Properties
    private let pathMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "com.yeelightcontrol.network", qos: .userInitiated)
    private var activeListeners: [UInt16: NWListener] = [:]
    private var activeConnections: [String: NWConnection] = [:]
    private var discoveryTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    public static let shared = UnifiedNetworkManager()
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    public func startDiscovery() {
        guard !isDiscoveryActive else { return }
        isDiscoveryActive = true
        
        discoveryTask = Task {
            do {
                // Start SSDP discovery
                try await startSSDP()
                
                // Wait for responses
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                
                // Stop discovery
                stopDiscovery()
            } catch {
                print("Discovery failed: \(error)")
                stopDiscovery()
            }
        }
    }
    
    public func stopDiscovery() {
        isDiscoveryActive = false
        discoveryTask?.cancel()
        stopSSDP()
    }
    
    public func connect(to endpoint: NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: .tcp)
        
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state, for: connection)
        }
        
        connection.start(queue: networkQueue)
    }
    
    public func disconnect(from endpoint: NWEndpoint) {
        if let connection = activeConnections[endpoint.debugDescription] {
            connection.cancel()
            activeConnections.removeValue(forKey: endpoint.debugDescription)
        }
    }
    
    public func send(_ data: Data, to endpoint: NWEndpoint) {
        guard let connection = activeConnections[endpoint.debugDescription] else {
            connect(to: endpoint)
            return
        }
        
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.handleError(error, for: connection)
            }
        })
    }
    
    // MARK: - Private Methods
    private func setupNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isNetworkReachable = path.status == .satisfied
                self?.connectionStatus = path.status == .satisfied ? .connected : .disconnected
            }
        }
        pathMonitor.start(queue: networkQueue)
    }
    
    private func handleConnectionState(_ state: NWConnection.State, for connection: NWConnection) {
        switch state {
        case .ready:
            Task { @MainActor in
                connectionStatus = .connected
                activeConnections[connection.endpoint.debugDescription] = connection
            }
            
        case .failed(let error):
            handleError(error, for: connection)
            
        case .cancelled:
            Task { @MainActor in
                activeConnections.removeValue(forKey: connection.endpoint.debugDescription)
                connectionStatus = .disconnected
            }
            
        default:
            break
        }
    }
    
    private func handleError(_ error: Error, for connection: NWConnection) {
        Task { @MainActor in
            connectionStatus = .error(error)
            activeConnections.removeValue(forKey: connection.endpoint.debugDescription)
        }
    }
    
    private func startSSDP() async throws {
        // Implementation for SSDP discovery
        // This would include:
        // 1. Creating UDP multicast connection
        // 2. Sending SSDP M-SEARCH request
        // 3. Handling responses
    }
    
    private func stopSSDP() {
        // Implementation for stopping SSDP discovery
        // This would include:
        // 1. Cancelling active connections
        // 2. Cleaning up resources
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