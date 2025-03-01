import Foundation
import Network
import Combine

// Define a type alias for the Core module's NetworkManaging protocol
typealias CoreNetworkManaging = NetworkManaging

/// Protocol for network message handling
public protocol UnifiedNetworkMessageHandler: AnyObject {
    func didReceiveMessage(_ message: Data)
    func didUpdateConnectionStatus(_ status: NWConnection.State)
}

/// Protocol defining network management capabilities
public protocol NetworkManaging: AnyObject {
    /// Check if network is reachable
    var isReachable: Bool { get }
    
    /// Check if network is monitoring
    var isMonitoring: Bool { get }
    
    /// Start monitoring network status
    func startMonitoring()
    
    /// Stop monitoring network status
    func stopMonitoring()
    
    /// Send data over network
    func send(_ data: Data) throws
    
    /// Add a message handler
    func addMessageHandler(_ handler: UnifiedNetworkMessageHandler)
    
    /// Remove a message handler
    func removeMessageHandler(_ handler: UnifiedNetworkMessageHandler)
}

/// Unified manager for handling network operations
public final class UnifiedNetworkManager: NetworkManaging {
    // MARK: - Properties
    
    /// Network path monitor
    private let monitor: NWPathMonitor
    
    /// Queue for network operations
    private let queue: DispatchQueue
    
    /// Message handlers
    private var messageHandlers = NSHashTable<AnyObject>.weakObjects()
    
    /// Network status
    public private(set) var isReachable = false
    
    /// Monitoring status
    public private(set) var isMonitoring = false
    
    // MARK: - Initialization
    
    public init() {
        self.monitor = NWPathMonitor()
        self.queue = DispatchQueue(label: "com.yeelightcontrol.network")
        setupMonitor()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - NetworkManaging Methods
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        monitor.start(queue: queue)
        isMonitoring = true
    }
    
    public func stopMonitoring() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }
    
    public func send(_ data: Data) throws {
        guard isReachable else {
            throw NetworkError.connectionFailed
        }
        // Implementation for sending data
    }
    
    public func addMessageHandler(_ handler: UnifiedNetworkMessageHandler) {
        messageHandlers.add(handler)
    }
    
    public func removeMessageHandler(_ handler: UnifiedNetworkMessageHandler) {
        messageHandlers.remove(handler)
    }
    
    // MARK: - Private Methods
    
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.isReachable = path.status == .satisfied
        }
    }
    
    private func notifyHandlers(message: Data) {
        for case let handler as UnifiedNetworkMessageHandler in messageHandlers.allObjects {
            handler.didReceiveMessage(message)
        }
    }
    
    private func updateConnectionStatus(_ status: NWConnection.State) {
        for case let handler as UnifiedNetworkMessageHandler in messageHandlers.allObjects {
            handler.didUpdateConnectionStatus(status)
        }
    }
}

// Define NetworkError enum if not already defined elsewhere
public enum NetworkError: Error {
    case connectionFailed
    case invalidResponse
    case dataError
    case timeout
} 
