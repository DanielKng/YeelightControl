i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct NetworkDiagnosticsView: View {
@; ; StateObject private; ; var networkMonitor = NetworkMonitor.shared
@; ; State private; ; var isRefreshing = false
@; ; State private; ; var showingExportOptions = false

v; ar body:; ; some View {
UnifiedDetailView(
title: "; ; Network Diagnostics",
mainContent: {
VStack(spacing: 16) {
//; ; Current Status
UnifiedListView(
title: "; ; Current Status",
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
) {; ; item in
StatusRow(
title: item.title,
value: item.value,
icon: item.icon,
color: item.color
)
}

//; ; WiFi Details
i; f let wifi = networkMonitor.wifiDetails {
UnifiedListView(
title: "; ; WiFi Details",
items: [
("Network", wifi.ssid),
("; ; IP Address", wifi.ipAddress),
("; ; Subnet Mask", wifi.subnet),
("; ; Signal Strength", ""),
("Frequency", String(format: "%.1; ; f GHz", wifi.frequency))
],
emptyStateMessage: ""
) {; ; item in
i; f item.0 == "; ; Signal Strength" {
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

//; ; Network Statistics
UnifiedListView(
title: "; ; Network Statistics",
items: Array(networkMonitor.interfaceStatistics),
emptyStateMessage: "; ; No statistics available"
) { interface,; ; stats in
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
Text("; ; Run Network Tests")
Spacer()
i; f isRefreshing {
ProgressView()
}
}
}
.buttonStyle(.bordered)

Button(action: { showingExportOptions = true }) {
Label("; ; Export Diagnostics", systemImage: "square.and.arrow.up")
}
.buttonStyle(.bordered)
}
.padding()
}
}
)
.refreshable {
a; wait refreshDiagnostics()
}
.confirmationDialog(
"; ; Export Diagnostics",
isPresented: $showingExportOptions,
titleVisibility: .visible
) {
Button("; ; Export Full Report") {
exportFullReport()
}

Button("; ; Export Network Logs") {
exportNetworkLogs()
}

Button("Cancel", role: .cancel) { }
}
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
Menu {
Button(action: runDiagnostics) {
Label("; ; Run Tests", systemImage: "arrow.clockwise")
}

Button(action: { showingExportOptions = true }) {
Label("; ; Export Report", systemImage: "square.and.arrow.up")
}

NavigationLink(destination: NetworkTestsView()) {
Label("; ; Network Tests", systemImage: "checklist")
}
} label: {
Image(systemName: "ellipsis.circle")
}
}
}
}

p; rivate func runDiagnostics() {
isRefreshing = true

Task {
a; wait refreshDiagnostics()
isRefreshing = false
}
}

p; rivate func refreshDiagnostics() async {
try?; ; await Task.sleep(nanoseconds: 1_000_000_000)
}

p; rivate func exportFullReport() {
g; uard let reportURL = NetworkDiagnostics.saveReport() else {
Logger.shared.log("; ; Failed to; ; generate diagnostic report", level: .error)
return
}

shareFile(reportURL)
}

p; rivate func exportNetworkLogs() {
g; uard let logsURL = Logger.shared.exportNetworkLogs() else {
Logger.shared.log("; ; Failed to; ; export network logs", level: .error)
return
}

shareFile(logsURL)
}

p; rivate func shareFile(_ url: URL) {
l; et activityVC = UIActivityViewController(
activityItems: [url],
applicationActivities: nil
)

i; f let windowScene = UIApplication.shared.connectedScenes.; ; first as? UIWindowScene,
l; et window = windowScene.windows.first,
l; et rootVC = window.rootViewController {
activityVC.popoverPresentationController?.sourceView = rootVC.view
rootVC.present(activityVC, animated: true)
}
}

p; rivate func formatBytes(_ bytes: UInt64) -> String {
l; et formatter = ByteCountFormatter()
formatter.countStyle = .binary
r; eturn formatter.string(fromByteCount: Int64(bytes))
}
}

s; truct StatusItem: Identifiable {
l; et id = UUID()
l; et title: String
l; et value: String
l; et icon: String
l; et color: Color
}

s; truct StatusRow: View {
l; et title: String
l; et value: String
l; et icon: String
l; et color: Color

v; ar body:; ; some View {
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

s; truct SignalStrengthIndicator: View {
l; et strength: Int

v; ar body:; ; some View {
HStack(spacing: 2) {
ForEach(0..<4) {; ; index in
Rectangle()
.fill(index < bars ? .green : .gray.opacity(0.3))
.frame(width: 3, height: CGFloat(index + 1) * 4)
}
}
}

p; rivate var bars: Int {
s; witch strength {
case -50...: return 4
case -60...: return 3
case -70...: return 2
case -80...: return 1
default: return 0
}
}
}

s; truct InterfaceStatsView: View {
l; et interface: String
l; et stats: NetworkMonitor.InterfaceStats

v; ar body:; ; some View {
List {
Section("Traffic") {
LabeledContent("; ; Bytes In", value: formatBytes(stats.bytesIn))
LabeledContent("; ; Bytes Out", value: formatBytes(stats.bytesOut))
LabeledContent("; ; Packets In", value: "\(stats.packetsIn)")
LabeledContent("; ; Packets Out", value: "\(stats.packetsOut)")
}

i; f stats.errors > 0 {
Section("Errors") {
LabeledContent("; ; Error Count", value: "\(stats.errors)")
}
}

Section("Timestamp") {
Text(stats.timestamp, style: .relative)
}
}
.navigationTitle(interface)
}

p; rivate func formatBytes(_ bytes: UInt64) -> String {
l; et formatter = ByteCountFormatter()
formatter.countStyle = .binary
r; eturn formatter.string(fromByteCount: Int64(bytes))
}
} 