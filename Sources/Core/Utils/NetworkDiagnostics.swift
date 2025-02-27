import Foundation
import Network

extension Bundle {
    var version: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}

class NetworkDiagnostics {
    static func generateReport() -> String {
        var report = "Yeelight App Diagnostic Report\n"
        report += "Generated: \(Date().formatted())\n\n"
        
        // System Information
        report += "=== System Information ===\n"
        report += "iOS Version: \(UIDevice.current.systemVersion)\n"
        report += "Device Model: \(UIDevice.current.model)\n"
        report += "App Version: \(Bundle.main.version)\n\n"
        
        // Network Status
        report += "=== Network Status ===\n"
        report += "WiFi Enabled: \(NetworkStatus.shared.isWiFiEnabled)\n"
        report += "Local Network Permission: \(NetworkStatus.shared.hasLocalNetworkAuthorization)\n"
        report += "Current Network: \(NetworkStatus.shared.currentSSID ?? "Unknown")\n\n"
        
        // Device Information
        report += "=== Discovered Devices ===\n"
        let devices = YeelightManager.shared.devices
        for device in devices {
            report += "Device: \(device.name)\n"
            report += "  IP: \(device.ip)\n"
            report += "  Port: \(device.port)\n"
            report += "  Status: \(device.connectionState.description)\n"
            report += "  Last Seen: \(device.lastSeen.formatted())\n"
            report += "  Power: \(device.isOn ? "On" : "Off")\n"
            report += "  Mode: \(device.powerMode.rawValue)\n\n"
        }
        
        // Connection History
        report += "=== Connection History ===\n"
        for entry in ConnectionLogger.shared.history {
            report += "\(entry.timestamp.formatted()): \(entry.event)\n"
        }
        report += "\n"
        
        // Debug Logs
        if UserDefaults.standard.bool(forKey: "debugMode") {
            report += "=== Debug Logs ===\n"
            for log in Logger.shared.logs {
                report += "[\(log.timestamp.formatted())] [\(log.level.rawValue.uppercased())] \(log.message)\n"
            }
        }
        
        return report
    }
    
    static func saveReport() -> URL? {
        let report = generateReport()
        
        // Get the documents directory
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let reportURL = documentsPath.appendingPathComponent("yeelight_report_\(timestamp).txt")
        
        do {
            try report.write(to: reportURL, atomically: true, encoding: .utf8)
            return reportURL
        } catch {
            Logger.shared.log("Failed to save diagnostic report: \(error.localizedDescription)", level: .error)
            return nil
        }
    }
}

// Helper class to track connection events
class ConnectionLogger {
    static let shared = ConnectionLogger()
    
    struct ConnectionEvent {
        let timestamp: Date
        let event: String
    }
    
    private(set) var history: [ConnectionEvent] = []
    private let maxEvents = 100
    
    func logEvent(_ event: String) {
        let newEvent = ConnectionEvent(timestamp: Date(), event: event)
        history.append(newEvent)
        
        if history.count > maxEvents {
            history.removeFirst(history.count - maxEvents)
        }
    }
}

// Network status monitoring
class NetworkStatus {
    static let shared = NetworkStatus()
    
    private let monitor = NWPathMonitor()
    private(set) var isWiFiEnabled = false
    private(set) var currentSSID: String?
    
    var hasLocalNetworkAuthorization: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSLocalNetworkUsageDescription") != nil
    }
    
    init() {
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isWiFiEnabled = path.usesInterfaceType(.wifi)
            self?.updateSSID()
        }
        monitor.start(queue: .main)
    }
    
    private func updateSSID() {
        // Note: Getting SSID requires additional entitlements
        // This is a placeholder for the actual implementation
        currentSSID = "Network Name"
    }
} 