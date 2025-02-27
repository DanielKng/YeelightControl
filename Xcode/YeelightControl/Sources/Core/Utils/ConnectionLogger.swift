import Foundation

class ConnectionLogger {
    static let shared = ConnectionLogger()
    private let maxEntries = 1000
    
    struct ConnectionEvent: Codable {
        let timestamp: Date
        let event: String
        let deviceIP: String?
        let status: Status
        let details: String?
        
        enum Status: String, Codable {
            case connected
            case disconnected
            case error
            case discovery
            case command
            case response
        }
    }
    
    @Published private(set) var history: [ConnectionEvent] = []
    private let queue = DispatchQueue(label: "com.yeelight.connectionlogger")
    private let storage = DeviceStorage.shared
    
    private init() {
        loadHistory()
    }
    
    func logEvent(_ event: String, deviceIP: String? = nil, status: ConnectionEvent.Status, details: String? = nil) {
        let entry = ConnectionEvent(
            timestamp: Date(),
            event: event,
            deviceIP: deviceIP,
            status: status,
            details: details
        )
        
        queue.async {
            self.history.append(entry)
            if self.history.count > self.maxEntries {
                self.history.removeFirst(self.history.count - self.maxEntries)
            }
            self.saveHistory()
        }
    }
    
    func clearHistory() {
        queue.async {
            self.history.removeAll()
            self.saveHistory()
        }
    }
    
    private func loadHistory() {
        // Load from storage if needed
    }
    
    private func saveHistory() {
        // Save to storage if needed
    }
    
    func generateReport() -> String {
        var report = "Connection History Report\n"
        report += "Generated: \(Date().formatted())\n\n"
        
        for event in history.suffix(100) {
            report += "[\(event.timestamp.formatted())] "
            report += "[\(event.status.rawValue.uppercased())] "
            if let ip = event.deviceIP {
                report += "[\(ip)] "
            }
            report += event.event
            if let details = event.details {
                report += " - \(details)"
            }
            report += "\n"
        }
        
        return report
    }
} 