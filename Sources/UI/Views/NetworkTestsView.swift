import SwiftUI
import Core

struct NetworkTestsView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @EnvironmentObject private var networkManager: ObservableNetworkManager
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    @State private var currentTest: String?
    @State private var showingErrorAlert = false
    @State private var lastError: Error?
    @State private var dnsStatus: DNSStatus = .notStarted
    @State private var resolvedIPs: [String] = []
    
    struct TestResult: Identifiable {
        let id = UUID()
        let name: String
        let status: StatusRow.Status
        let message: String
        let timestamp = Date()
    }
    
    enum DNSStatus {
        case notStarted, resolving, resolved, failed
    }
    
    var body: some View {
        ScrollView {
            if isRunningTests {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    if let currentTest {
                        Text("Running: \(currentTest)")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                VStack(spacing: 20) {
                    // Connection Status
                    StatusSection(title: "Connection Status") {
                        StatusRow(
                            title: "Network",
                            value: networkMonitor.connectionDescription,
                            icon: "network",
                            status: networkMonitor.isConnected ? .success : .error
                        )
                        
                        StatusRow(
                            title: "Interface",
                            value: networkMonitor.interfaceDescription,
                            icon: "wifi",
                            status: .success
                        )
                        
                        if let ipAddress = networkMonitor.ipAddress {
                            StatusRow(
                                title: "IP Address",
                                value: ipAddress,
                                icon: "number",
                                status: .success
                            )
                        }
                    }
                    
                    // Test Results
                    if !testResults.isEmpty {
                        StatusSection(title: "Test Results") {
                            ForEach(testResults) { result in
                                StatusRow(
                                    title: result.name,
                                    value: result.message,
                                    icon: statusIcon(for: result.status),
                                    status: result.status
                                )
                            }
                        }
                    }
                    
                    // DNS Resolution
                    if dnsStatus != .notStarted {
                        StatusSection(title: "DNS Resolution") {
                            StatusRow(
                                title: "Status",
                                value: dnsStatusDescription,
                                icon: dnsStatusIcon,
                                status: dnsStatus == .resolved ? .success : (dnsStatus == .failed ? .error : .warning)
                            )
                            
                            if !resolvedIPs.isEmpty {
                                ForEach(resolvedIPs, id: \.self) { ip in
                                    StatusRow(
                                        title: "Resolved IP",
                                        value: ip,
                                        icon: "server.rack",
                                        status: .success
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Network Tests")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    if isRunningTests {
                        // Cancel tests
                    } else {
                        Task { await startTests() }
                    }
                }) {
                    Text(isRunningTests ? "Cancel" : "Run Tests")
                }
            }
        }
        .alert("Test Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = lastError {
                Text("An error occurred: \(error.localizedDescription)")
            } else {
                Text("An unknown error occurred")
            }
        }
    }
    
    private func startTests() async {
        testResults = []
        isRunningTests = true
        dnsStatus = .notStarted
        resolvedIPs = []
        
        do {
            // Basic connectivity test
            currentTest = "Connectivity Test"
            if networkMonitor.isConnected {
                addTestResult(
                    name: "Connectivity",
                    status: .success,
                    message: "Network is available and connected"
                )
            } else {
                addTestResult(
                    name: "Connectivity",
                    status: .error,
                    message: "No network connection available"
                )
                throw NetworkError.noConnection
            }
            
            // DNS resolution test
            currentTest = "DNS Resolution"
            try await testDNSResolution()
            
            // Latency test
            currentTest = "Latency Test"
            try await testLatency()
            
            // Bandwidth test
            currentTest = "Bandwidth Test"
            try await testBandwidth()
            
            currentTest = nil
        } catch {
            await handleTestError(error)
        }
        
        isRunningTests = false
    }
    
    private func testDNSResolution() async throws {
        dnsStatus = .resolving
        var resolvedCount = 0
        
        // Test multiple domains for redundancy
        let hosts = [
            "yeelight.com",
            "google.com",
            "apple.com"
        ]
        
        for host in hosts {
            do {
                try await performDNSLookup(host)
                resolvedCount += 1
            } catch {
                // Continue with other hosts
            }
        }
        
        if resolvedCount > 0 {
            dnsStatus = .resolved
            addTestResult(
                name: "DNS Resolution",
                status: resolvedCount == hosts.count ? .success : .warning,
                message: "Resolved \(resolvedCount)/\(hosts.count) domains"
            )
        } else {
            dnsStatus = .failed
            throw NetworkError.dnsResolutionFailed
        }
    }
    
    private func performDNSLookup(_ host: String) async throws {
        // Simulated DNS lookup
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In a real app, perform actual DNS resolution
        let ip = "192.168.\(Int.random(in: 1...254)).\(Int.random(in: 1...254))"
        resolvedIPs.append(ip)
    }
    
    private func testLatency() async throws {
        // Simulated latency test
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let avgLatency = Double.random(in: 10...200) // ms
        let status: TestResult.Status
        let message: String
        
        if avgLatency < 50 {
            status = .success
            message = "Excellent: \(Int(avgLatency))ms"
        } else if avgLatency < 100 {
            status = .success
            message = "Good: \(Int(avgLatency))ms"
        } else if avgLatency < 150 {
            status = .warning
            message = "Fair: \(Int(avgLatency))ms"
        } else {
            status = .error
            message = "Poor: \(Int(avgLatency))ms"
        }
        
        addTestResult(name: "Latency", status: status, message: message)
        
        if status == .error {
            throw NetworkError.highLatency
        }
    }
    
    private func testBandwidth() async throws {
        // Simulated bandwidth test
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let speed = Double.random(in: 1_000_000...50_000_000) // bps
        let status: TestResult.Status
        let message: String
        
        if speed > 10_000_000 { // 10 Mbps
            status = .success
            message = "Good: \(formatBandwidth(speed))"
        } else if speed > 5_000_000 { // 5 Mbps
            status = .success
            message = "Adequate: \(formatBandwidth(speed))"
        } else if speed > 2_000_000 { // 2 Mbps
            status = .warning
            message = "Slow: \(formatBandwidth(speed))"
        } else {
            status = .error
            message = "Very slow: \(formatBandwidth(speed))"
        }
        
        addTestResult(name: "Bandwidth", status: status, message: message)
        
        if status == .error {
            throw NetworkError.lowBandwidth
        }
    }
    
    private func addTestResult(name: String, status: TestResult.Status, message: String) {
        testResults.append(TestResult(name: name, status: status, message: message))
    }
    
    private func statusIcon(for status: StatusRow.Status) -> String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private var dnsStatusDescription: String {
        switch dnsStatus {
        case .notStarted: return "Not started"
        case .resolving: return "Resolving..."
        case .resolved: return "Resolved successfully"
        case .failed: return "Resolution failed"
        }
    }
    
    private var dnsStatusIcon: String {
        switch dnsStatus {
        case .notStarted: return "questionmark.circle"
        case .resolving: return "arrow.triangle.2.circlepath"
        case .resolved: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
    
    private func handleTestError(_ error: Error) {
        lastError = error
        showingErrorAlert = true
    }
    
    private func formatBandwidth(_ bps: Double) -> String {
        if bps >= 1_000_000 {
            return String(format: "%.1f Mbps", bps / 1_000_000)
        } else {
            return String(format: "%.1f Kbps", bps / 1_000)
        }
    }
}

enum NetworkError: Error {
    case noConnection
    case dnsResolutionFailed
    case highLatency
    case lowBandwidth
} 