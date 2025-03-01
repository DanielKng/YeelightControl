import SwiftUI

struct NetworkDiagnosticsView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @State private var isRefreshing = false
    @State private var showingShareSheet = false
    @State private var diagnosticReport: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Connection Status
                Section(header: Text("Connection Status")) {
                    StatusRow(
                        title: "Connection Type",
                        value: networkMonitor.connectionType.rawValue,
                        icon: networkMonitor.connectionIcon,
                        color: networkMonitor.isConnected ? .green : .red
                    )
                    
                    StatusRow(
                        title: "IP Address",
                        value: networkMonitor.ipAddress ?? "Unknown",
                        icon: "network",
                        color: .blue
                    )
                    
                    if let ssid = networkMonitor.wifiSSID {
                        StatusRow(
                            title: "Wi-Fi Network",
                            value: ssid,
                            icon: "wifi",
                            color: .blue
                        )
                        
                        if let strength = networkMonitor.wifiSignalStrength {
                            HStack {
                                Text("Signal Strength")
                                Spacer()
                                SignalStrengthIndicator(strength: strength)
                            }
                        }
                    }
                    
                    StatusRow(
                        title: "Cellular Data",
                        value: networkMonitor.isCellularEnabled ? "Enabled" : "Disabled",
                        icon: "antenna.radiowaves.left.and.right",
                        color: networkMonitor.isCellularEnabled ? .green : .gray
                    )
                    
                    if networkMonitor.isCellularEnabled {
                        StatusRow(
                            title: "Carrier",
                            value: networkMonitor.carrierName ?? "Unknown",
                            icon: "personalhotspot",
                            color: .blue
                        )
                    }
                }
                
                // Network Performance
                Section(header: Text("Network Performance")) {
                    StatusRow(
                        title: "Latency",
                        value: "\(networkMonitor.latency) ms",
                        icon: "speedometer",
                        color: networkMonitor.latencyColor
                    )
                    
                    StatusRow(
                        title: "Download Speed",
                        value: formatBitrate(networkMonitor.downloadSpeed),
                        icon: "arrow.down.circle",
                        color: .green
                    )
                    
                    StatusRow(
                        title: "Upload Speed",
                        value: formatBitrate(networkMonitor.uploadSpeed),
                        icon: "arrow.up.circle",
                        color: .blue
                    )
                }
                
                // Network Usage
                Section(header: Text("Network Usage")) {
                    ForEach(networkMonitor.interfaceStats.sorted(by: { $0.key < $1.key }), id: \.key) { interface, stats in
                        DisclosureGroup(interface) {
                            InterfaceStatsView(interface: interface, stats: stats)
                        }
                    }
                }
                
                // Device Discovery
                Section(header: Text("Device Discovery")) {
                    StatusRow(
                        title: "Multicast",
                        value: networkMonitor.isMulticastEnabled ? "Enabled" : "Disabled",
                        icon: "dot.radiowaves.left.and.right",
                        color: networkMonitor.isMulticastEnabled ? .green : .red
                    )
                    
                    StatusRow(
                        title: "Bonjour/mDNS",
                        value: networkMonitor.isMDNSEnabled ? "Enabled" : "Disabled",
                        icon: "network.badge.shield.half.filled",
                        color: networkMonitor.isMDNSEnabled ? .green : .red
                    )
                    
                    StatusRow(
                        title: "UPnP",
                        value: networkMonitor.isUPnPEnabled ? "Enabled" : "Disabled",
                        icon: "rectangle.connected.to.line.below",
                        color: networkMonitor.isUPnPEnabled ? .green : .red
                    )
                }
                
                // Firewall Status
                Section(header: Text("Firewall Status")) {
                    StatusRow(
                        title: "Firewall",
                        value: networkMonitor.isFirewallEnabled ? "Enabled" : "Disabled",
                        icon: "shield",
                        color: networkMonitor.isFirewallEnabled ? .orange : .green
                    )
                    
                    StatusRow(
                        title: "VPN",
                        value: networkMonitor.isVPNActive ? "Active" : "Inactive",
                        icon: "lock.shield",
                        color: networkMonitor.isVPNActive ? .orange : .green
                    )
                }
                
                // Troubleshooting
                Section(header: Text("Troubleshooting")) {
                    Button(action: runDiagnostics) {
                        Label("Run Network Diagnostics", systemImage: "waveform.path.ecg")
                    }
                    
                    Button(action: shareReport) {
                        Label("Share Diagnostic Report", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink(destination: NetworkTroubleshootingView()) {
                        Label("Troubleshooting Guide", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Network Diagnostics")
            .refreshable {
                await refreshData()
            }
            .onAppear {
                networkMonitor.startMonitoring()
            }
            .onDisappear {
                networkMonitor.stopMonitoring()
            }
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        await networkMonitor.refreshStats()
        isRefreshing = false
    }
    
    private func runDiagnostics() {
        Task {
            await networkMonitor.runDiagnostics()
        }
    }
    
    private func shareReport() {
        diagnosticReport = networkMonitor.generateDiagnosticReport()
        showingShareSheet = true
        
        // Present share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            let activityVC = UIActivityViewController(
                activityItems: [diagnosticReport],
                applicationActivities: nil
            )
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func formatBitrate(_ bitsPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        
        // Convert bits to bytes for the formatter
        let bytesPerSecond = bitsPerSecond / 8
        return formatter.string(fromByteCount: Int64(bytesPerSecond)) + "/s"
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
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct SignalStrengthIndicator: View {
    let strength: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Rectangle()
                    .fill(index < strength ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 6, height: CGFloat(index + 1) * 4)
                    .cornerRadius(2)
            }
        }
    }
}

struct InterfaceStatsView: View {
    let interface: String
    let stats: NetworkMonitor.InterfaceStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bytes In")
                Spacer()
                Text(formatBytes(stats.bytesIn))
            }
            
            HStack {
                Text("Bytes Out")
                Spacer()
                Text(formatBytes(stats.bytesOut))
            }
            
            HStack {
                Text("Packets In")
                Spacer()
                Text("\(stats.packetsIn)")
            }
            
            HStack {
                Text("Packets Out")
                Spacer()
                Text("\(stats.packetsOut)")
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
} 