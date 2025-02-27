import SwiftUI

struct NetworkDiagnosticsView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var isRefreshing = false
    @State private var showingExportOptions = false
    
    var body: some View {
        UnifiedDetailView(
            title: "Network Diagnostics",
            mainContent: {
                VStack(spacing: 16) {
                    // Current Status
                    UnifiedListView(
                        title: "Current Status",
                        items: [
                            StatusItem(
                                title: "Connection",
                                value: networkMonitor.isConnected ? "Connected" : "Disconnected",
                                icon: networkMonitor.isConnected ? "wifi" : "wifi.slash",
                                color: networkMonitor.isConnected ? .green : .red
                            ),
                            StatusItem(
                                title: "Type",
                                value: networkMonitor.connectionType.description,
                                icon: networkMonitor.connectionType.icon,
                                color: .blue
                            )
                        ],
                        emptyStateMessage: ""
                    ) { item in
                        StatusRow(
                            title: item.title,
                            value: item.value,
                            icon: item.icon,
                            color: item.color
                        )
                    }
                    
                    // WiFi Details
                    if let wifi = networkMonitor.wifiDetails {
                        UnifiedListView(
                            title: "WiFi Details",
                            items: [
                                ("Network", wifi.ssid),
                                ("IP Address", wifi.ipAddress),
                                ("Subnet Mask", wifi.subnet),
                                ("Signal Strength", ""),
                                ("Frequency", String(format: "%.1f GHz", wifi.frequency))
                            ],
                            emptyStateMessage: ""
                        ) { item in
                            if item.0 == "Signal Strength" {
                                HStack {
                                    Text(item.0)
                                    Spacer()
                                    SignalStrengthIndicator(strength: wifi.strength)
                                }
                            } else {
                                HStack {
                                    Text(item.0)
                                    Spacer()
                                    Text(item.1)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Network Statistics
                    UnifiedListView(
                        title: "Network Statistics",
                        items: Array(networkMonitor.interfaceStatistics),
                        emptyStateMessage: "No statistics available"
                    ) { interface, stats in
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
                    
                    // Diagnostics
                    VStack(spacing: 12) {
                        Button(action: runDiagnostics) {
                            HStack {
                                Text("Run Network Tests")
                                Spacer()
                                if isRefreshing {
                                    ProgressView()
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: { showingExportOptions = true }) {
                            Label("Export Diagnostics", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
        )
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
        
        Task {
            await refreshDiagnostics()
            isRefreshing = false
        }
    }
    
    private func refreshDiagnostics() async {
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

struct StatusItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
}

struct StatusRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
            
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