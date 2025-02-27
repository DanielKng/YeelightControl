import Foundation
import Network
import SystemConfiguration.CaptiveNetwork

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected = false
    @Published private(set) var connectionType: ConnectionType = .unknown
    @Published private(set) var wifiDetails: WiFiDetails?
    @Published private(set) var interfaceStatistics: [String: InterfaceStats] = [:]
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    struct WiFiDetails {
        let ssid: String
        let bssid: String
        let strength: Int // RSSI in dBm
        let frequency: Double // in GHz
        let ipAddress: String
        let subnet: String
    }
    
    struct InterfaceStats {
        var bytesIn: UInt64
        var bytesOut: UInt64
        var packetsIn: UInt64
        var packetsOut: UInt64
        var errors: UInt64
        let timestamp: Date
    }
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case loopback
        case unknown
    }
    
    init() {
        setupMonitoring()
        startInterfaceMonitoring()
    }
    
    private func setupMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
                if path.usesInterfaceType(.wifi) {
                    self?.updateWiFiDetails()
                } else {
                    self?.wifiDetails = nil
                }
                
                // Log network changes
                Logger.shared.log("Network status changed: \(path.status == .satisfied ? "Connected" : "Disconnected")", level: .info)
                ConnectionLogger.shared.logEvent("Network interface changed to: \(self?.connectionType ?? .unknown)")
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else if path.usesInterfaceType(.loopback) {
            connectionType = .loopback
        } else {
            connectionType = .unknown
        }
    }
    
    private func updateWiFiDetails() {
        // Note: This requires additional entitlements in production
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return }
        
        for interface in interfaces {
            guard let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] else { continue }
            
            wifiDetails = WiFiDetails(
                ssid: info[kCNNetworkInfoKeySSID as String] as? String ?? "Unknown",
                bssid: info[kCNNetworkInfoKeyBSSID as String] as? String ?? "Unknown",
                strength: getWiFiStrength() ?? 0,
                frequency: getWiFiFrequency() ?? 0,
                ipAddress: getIPAddress() ?? "Unknown",
                subnet: getSubnetMask() ?? "Unknown"
            )
            break
        }
    }
    
    private func startInterfaceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateInterfaceStatistics()
        }
    }
    
    private func updateInterfaceStatistics() {
        var stats = InterfaceStats(
            bytesIn: 0,
            bytesOut: 0,
            packetsIn: 0,
            packetsOut: 0,
            errors: 0,
            timestamp: Date()
        )
        
        // Implementation would use system APIs to get actual network statistics
        // This is a placeholder for the actual implementation
        
        interfaceStatistics[connectionType.description] = stats
    }
    
    // Helper methods for network details
    private func getWiFiStrength() -> Int? {
        // Implementation would use system APIs to get actual RSSI
        return nil
    }
    
    private func getWiFiFrequency() -> Double? {
        // Implementation would use system APIs to get actual frequency
        return nil
    }
    
    private func getIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interface = ptr?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: (interface?.ifa_name)!)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface?.ifa_addr,
                              socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                              &hostname,
                              socklen_t(hostname.count),
                              nil,
                              0,
                              NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        return address
    }
    
    private func getSubnetMask() -> String? {
        // Implementation would get actual subnet mask
        return nil
    }
} 