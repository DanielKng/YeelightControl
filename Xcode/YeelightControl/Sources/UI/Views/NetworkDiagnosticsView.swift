import SwiftUI

struct NetworkDiagnosticsView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var isRefreshing = false
    @State private var showingExportOptions = false
    
    var body: some View {
        List {
            Section("Current Status") {
                StatusRow(
                    title: "Connection",
                    value: networkMonitor.isConnected ? "Connected" : "Disconnected",
                    icon: networkMonitor.isConnected ? "wifi" : "wifi.slash",
                    color: networkMonitor.isConnected ? .green : .red
                )
                
                StatusRow(
                    title: "Type",
                    value: networkMonitor.connectionType.description,
                    icon: networkMonitor.connectionType.icon,
                    color: .blue
                )
            }
            
            if let wifi = networkMonitor.wifiDetails {
                Section("WiFi Details") {
                    LabeledContent("Network", value: wifi.ssid)
                    LabeledContent("IP Address", value: wifi.ipAddress)
                    LabeledContent("Subnet Mask", value: wifi.subnet)
                    
                    HStack {
                        Text("Signal Strength")
                        Spacer()
                        SignalStrengthIndicator(strength: wifi.strength)
                    }
                    
                    LabeledContent("Frequency", value: String(format: "%.1f GHz", wifi.frequency))
                }
            }
            
            Section("Network Statistics") {
                ForEach(Array(networkMonitor.interfaceStatistics), id: \.key) { interface, stats in
                    NavigationLink {
                        InterfaceStatsView(interface: interface, stats: stats)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(interface)
                            Text("\(formatBytes(stats.bytesIn)) received")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("Diagnostics") {
                Button(action: runDiagnostics) {
                    HStack {
                        Text("Run Network Tests")
                        Spacer()
                        if isRefreshing {
                            ProgressView()
                        }
                    }
                }
                
                Button(action: { showingExportOptions = true }) {
                    Label("Export Diagnostics", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Network Diagnostics")
        .refreshable {
            await refreshDiagnostics()
        }
        .confirmationDialog(
            "Export Diagnostics",
            isPresented: $showingExportOptions,
            titleVisibility: .visible
        ) {
            Button("Export Full Report") {
                exportFullReport()
            }
            
            Button("Export Network Logs") {
                exportNetworkLogs()
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: runDiagnostics) {
                        Label("Run Tests", systemImage: "arrow.clockwise")
                    }
                    
                    Button(action: { showingExportOptions = true }) {
                        Label("Export Report", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink(destination: NetworkTestsView()) {
                        Label("Network Tests", systemImage: "checklist")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private func runDiagnostics() {
        isRefreshing = true
        
        // Run network tests
        Task {
            await refreshDiagnostics()
            isRefreshing = false
        }
    }
    
    private func refreshDiagnostics() async {
        // Implement network tests here
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    private func exportFullReport() {
        guard let reportURL = NetworkDiagnostics.saveReport() else {
            Logger.shared.log("Failed to generate diagnostic report", level: .error)
            return
        }
        
        shareFile(reportURL)
    }
    
    private func exportNetworkLogs() {
        guard let logsURL = Logger.shared.exportNetworkLogs() else {
            Logger.shared.log("Failed to export network logs", level: .error)
            return
        }
        
        shareFile(logsURL)
    }
    
    private func shareFile(_ url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(color)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

struct SignalStrengthIndicator: View {
    let strength: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(index < bars ? .green : .gray.opacity(0.3))
                    .frame(width: 3, height: CGFloat(index + 1) * 4)
            }
        }
    }
    
    private var bars: Int {
        switch strength {
        case -50...: return 4
        case -60...: return 3
        case -70...: return 2
        case -80...: return 1
        default: return 0
        }
    }
}

struct InterfaceStatsView: View {
    let interface: String
    let stats: NetworkMonitor.InterfaceStats
    
    var body: some View {
        List {
            Section("Traffic") {
                LabeledContent("Bytes In", value: formatBytes(stats.bytesIn))
                LabeledContent("Bytes Out", value: formatBytes(stats.bytesOut))
                LabeledContent("Packets In", value: "\(stats.packetsIn)")
                LabeledContent("Packets Out", value: "\(stats.packetsOut)")
            }
            
            if stats.errors > 0 {
                Section("Errors") {
                    LabeledContent("Error Count", value: "\(stats.errors)")
                }
            }
            
            Section("Timestamp") {
                Text(stats.timestamp, style: .relative)
            }
        }
        .navigationTitle(interface)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
} 