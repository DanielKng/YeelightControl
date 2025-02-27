import SwiftUI

struct NetworkTestsView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
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
        let status: Status
        let message: String
        let timestamp: Date
        
        enum Status {
            case success, warning, failure
            
            var icon: String {
                switch self {
                case .success: return "checkmark.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .failure: return "xmark.circle.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .success: return .green
                case .warning: return .orange
                case .failure: return .red
                }
            }
        }
    }
    
    var body: some View {
        List {
            if isRunningTests {
                Section {
                    HStack {
                        if let currentTest {
                            Text("Running: \(currentTest)")
                            Spacer()
                            ProgressView()
                        }
                    }
                }
            }
            
            Section {
                ForEach(testResults) { result in
                    HStack {
                        Image(systemName: result.status.icon)
                            .foregroundStyle(result.status.color)
                        
                        VStack(alignment: .leading) {
                            Text(result.name)
                                .font(.headline)
                            Text(result.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = result.message
                        }) {
                            Label("Copy Result", systemImage: "doc.on.doc")
                        }
                    }
                }
            } header: {
                if !testResults.isEmpty {
                    Text("Test Results")
                }
            }
            
            Section {
                Button(action: runTests) {
                    if isRunningTests {
                        HStack {
                            Text("Running Tests...")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Text("Run Network Tests")
                    }
                }
                .disabled(isRunningTests)
            }
        }
        .navigationTitle("Network Tests")
        .alert("Test Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
            Button("Retry", role: .none) {
                runTests()
            }
        } message: {
            if let error = lastError {
                Text(error.localizedDescription)
            }
        }
    }
    
    private func runTests() {
        isRunningTests = true
        testResults.removeAll()
        
        Task {
            do {
                // Basic connectivity test
                currentTest = "Network Connectivity"
                try await networkMonitor.validateConnection()
                addTestResult(
                    name: "Network Connectivity",
                    status: .success,
                    message: "Network is available and connected"
                )
                
                // DNS resolution test
                currentTest = "DNS Resolution"
                try await testDNSResolution()
                
                // Latency test
                currentTest = "Network Latency"
                try await testLatency()
                
                // Bandwidth test
                currentTest = "Network Bandwidth"
                try await testBandwidth()
                
                isRunningTests = false
                currentTest = nil
                
            } catch {
                handleTestError(error)
            }
        }
    }
    
    private func testDNSResolution() async throws {
        let hosts = ["google.com", "apple.com", "cloudflare.com"]
        var resolvedCount = 0
        
        for host in hosts {
            do {
                try await performDNSLookup(host)
                resolvedCount += 1
                addTestResult(
                    name: "DNS Resolution - \(host)",
                    status: .success,
                    message: "Resolved to \(resolvedIPs.joined(separator: ", "))"
                )
            } catch {
                addTestResult(
                    name: "DNS Resolution - \(host)",
                    status: .failure,
                    message: "Failed to resolve: \(error.localizedDescription)"
                )
            }
        }
        
        if resolvedCount == 0 {
            throw NetworkError.dnsResolutionFailed
        }
    }
    
    private func performDNSLookup(_ host: String) async throws {
        dnsStatus = .inProgress
        do {
            let ips = try await NetworkMonitor.shared.resolveHost(host)
            resolvedIPs = ips
            dnsStatus = .success
        } catch {
            dnsStatus = .failed(error)
        }
    }
    
    private func testLatency() async throws {
        let results = try await NetworkDiagnostics.measureLatency()
        let avgLatency = results.reduce(0.0) { $0 + $1.latency } / Double(results.count)
        
        let status: TestResult.Status
        if avgLatency < 50 {
            status = .success
        } else if avgLatency < 100 {
            status = .warning
        } else {
            status = .failure
        }
        
        addTestResult(
            name: "Network Latency",
            status: status,
            message: "Average latency: \(Int(avgLatency))ms"
        )
        
        if status == .failure {
            throw NetworkError.highLatency
        }
    }
    
    private func testBandwidth() async throws {
        let speed = try await NetworkDiagnostics.measureBandwidth()
        
        let status: TestResult.Status
        if speed > 10_000_000 { // 10 Mbps
            status = .success
        } else if speed > 1_000_000 { // 1 Mbps
            status = .warning
        } else {
            status = .failure
        }
        
        let speedMbps = Double(speed) / 1_000_000.0
        addTestResult(
            name: "Network Bandwidth",
            status: status,
            message: String(format: "Download speed: %.1f Mbps", speedMbps)
        )
        
        if status == .failure {
            throw NetworkError.lowBandwidth
        }
    }
    
    private func addTestResult(name: String, status: TestResult.Status, message: String) {
        DispatchQueue.main.async {
            testResults.append(TestResult(
                name: name,
                status: status,
                message: message,
                timestamp: Date()
            ))
        }
    }
    
    private func handleTestError(_ error: Error) {
        DispatchQueue.main.async {
            isRunningTests = false
            currentTest = nil
            lastError = error
            showingErrorAlert = true
            
            addTestResult(
                name: "Test Error",
                status: .failure,
                message: error.localizedDescription
            )
        }
    }
}

enum NetworkError: LocalizedError {
    case dnsResolutionFailed
    case highLatency
    case lowBandwidth
    
    var errorDescription: String? {
        switch self {
        case .dnsResolutionFailed:
            return "Failed to resolve DNS names"
        case .highLatency:
            return "Network latency is too high"
        case .lowBandwidth:
            return "Network bandwidth is too low"
        }
    }
} 