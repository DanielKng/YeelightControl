import Foundation
import Network
import Combine

// MARK: - Type Aliases

public typealias CoreNetworkManaging = Core_NetworkManaging

// MARK: - Network Message Handler Protocol

/// Protocol for network message handling
public protocol Core_NetworkMessageHandler: AnyObject {
    func didReceiveMessage(_ message: Data)
    func didUpdateConnectionStatus(_ status: Bool)
}

// MARK: - Network Manager

/// Actor responsible for managing network connectivity and message handling
public actor UnifiedNetworkManager: Core_NetworkManaging, Core_BaseService {
    // MARK: - Properties
    
    private var monitor: NWPathMonitor?
    private var messageHandlers: [Core_NetworkMessageHandler] = []
    private var isMonitoring = false
    private var isReachable = false
    private let monitorQueue: DispatchQueue
    private var _isEnabled: Bool = true
    
    @Published public private(set) var serviceStatus: Core_ServiceStatus = .inactive
    
    // MARK: - Core_BaseService
    
    nonisolated public var isEnabled: Bool {
        get {
            // Using a non-async approach to access the property
            // This is a simplification - in a real app, you might need a more robust solution
            return _isEnabled
        }
    }
    
    public var serviceIdentifier: String {
        return "core.network"
    }
    
    // MARK: - Initialization
    
    public init() {
        self.monitorQueue = DispatchQueue(label: "com.yeelight.networkMonitor", qos: .utility)
        self.monitor = NWPathMonitor()
    }
    
    // MARK: - Core_NetworkManaging
    
    public func startMonitoring() async {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        setupMonitor()
        serviceStatus = .active
    }
    
    public func stopMonitoring() async {
        await stopMonitoringInternal()
        serviceStatus = .inactive
    }
    
    // MARK: - Private Methods
    
    private func stopMonitoringInternal() async {
        guard isMonitoring, let monitor = monitor else { return }
        
        monitor.cancel()
        isMonitoring = false
    }
    
    public func send(_ data: Data) async throws {
        guard isReachable else {
            throw Core_NetworkError.connectionFailed
        }
        
        // Implementation would depend on the specific network protocol
    }
    
    public func addMessageHandler(_ handler: Core_NetworkMessageHandler) async {
        if !messageHandlers.contains(where: { $0 === handler }) {
            messageHandlers.append(handler)
        }
    }
    
    public func removeMessageHandler(_ handler: Core_NetworkMessageHandler) async {
        messageHandlers.removeAll(where: { $0 === handler })
    }
    
    // MARK: - Core_NetworkManaging Protocol Methods
    
    public func request<T: Decodable>(_ endpoint: String, method: String, headers: [String: String]?, body: Data?) async throws -> T {
        // Implementation for making network requests
        throw Core_NetworkError.connectionFailed
    }
    
    public func download(_ url: URL) async throws -> Data {
        // Implementation for downloading data
        throw Core_NetworkError.connectionFailed
    }
    
    private func setupMonitor() {
        guard let monitor = monitor else { return }
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            Task {
                await self.updateReachabilityStatus(path.status == .satisfied)
            }
        }
        
        monitor.start(queue: monitorQueue)
    }
    
    private func updateReachabilityStatus(_ isReachable: Bool) async {
        self.isReachable = isReachable
        await updateConnectionStatus(isReachable)
    }
    
    private func notifyHandlers(_ message: Data) async {
        for handler in messageHandlers {
            handler.didReceiveMessage(message)
        }
    }
    
    private func updateConnectionStatus(_ isConnected: Bool) async {
        for handler in messageHandlers {
            handler.didUpdateConnectionStatus(isConnected)
        }
    }
}
