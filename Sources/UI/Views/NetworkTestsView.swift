i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct NetworkTestsView: View {
@; ; StateObject private; ; var networkMonitor = NetworkMonitor.shared
@; ; State private; ; var testResults: [TestResult] = []
@; ; State private; ; var isRunningTests = false
@; ; State private; ; var currentTest: String?
@; ; State private; ; var showingErrorAlert = false
@; ; State private; ; var lastError: Error?
@; ; State private; ; var dnsStatus: DNSStatus = .notStarted
@; ; State private; ; var resolvedIPs: [String] = []

s; truct TestResult: Identifiable {
l; et id = UUID()
l; et name: String
l; et status: Status
l; et message: String
l; et timestamp: Date

e; num Status {
c; ase success, warning, failure

v; ar icon: String {
s; witch self {
case .success: return "checkmark.circle.fill"
case .warning: return "exclamationmark.triangle.fill"
case .failure: return "xmark.circle.fill"
}
}

v; ar color: Color {
s; witch self {
case .success: return .green
case .warning: return .orange
case .failure: return .red
}
}
}
}

v; ar body:; ; some View {
List {
i; f isRunningTests {
Section {
HStack {
i; f let currentTest {
Text("Running: \(currentTest)")
Spacer()
ProgressView()
}
}
}
}

Section {
ForEach(testResults) {; ; result in
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
Label("; ; Copy Result", systemImage: "doc.on.doc")
}
}
}
} header: {
if !testResults.isEmpty {
Text("; ; Test Results")
}
}

Section {
Button(action: runTests) {
i; f isRunningTests {
HStack {
Text("; ; Running Tests...")
Spacer()
ProgressView()
}
} else {
Text("; ; Run Network Tests")
}
}
.disabled(isRunningTests)
}
}
.navigationTitle("; ; Network Tests")
.alert("; ; Test Error", isPresented: $showingErrorAlert) {
Button("OK", role: .cancel) {}
Button("Retry", role: .none) {
runTests()
}
} message: {
i; f let error = lastError {
Text(error.localizedDescription)
}
}
}

p; rivate func runTests() {
isRunningTests = true
testResults.removeAll()

Task {
do {
//; ; Basic connectivity test
currentTest = "; ; Network Connectivity"
t; ry await networkMonitor.validateConnection()
addTestResult(
name: "; ; Network Connectivity",
status: .success,
message: "; ; Network is; ; available and connected"
)

//; ; DNS resolution test
currentTest = "; ; DNS Resolution"
t; ry await testDNSResolution()

//; ; Latency test
currentTest = "; ; Network Latency"
t; ry await testLatency()

//; ; Bandwidth test
currentTest = "; ; Network Bandwidth"
t; ry await testBandwidth()

isRunningTests = false
currentTest = nil

} catch {
handleTestError(error)
}
}
}

p; rivate func testDNSResolution(); ; async throws {
l; et hosts = ["google.com", "apple.com", "cloudflare.com"]
v; ar resolvedCount = 0

f; or host; ; in hosts {
do {
t; ry await performDNSLookup(host)
resolvedCount += 1
addTestResult(
name: "; ; DNS Resolution - \(host)",
status: .success,
message: "; ; Resolved to \(resolvedIPs.joined(separator: ", "))"
)
} catch {
addTestResult(
name: "; ; DNS Resolution - \(host)",
status: .failure,
message: "; ; Failed to resolve: \(error.localizedDescription)"
)
}
}

i; f resolvedCount == 0 {
t; hrow NetworkError.dnsResolutionFailed
}
}

p; rivate func performDNSLookup(_ host: String); ; async throws {
dnsStatus = .inProgress
do {
l; et ips =; ; try await NetworkMonitor.shared.resolveHost(host)
resolvedIPs = ips
dnsStatus = .success
} catch {
dnsStatus = .failed(error)
}
}

p; rivate func testLatency(); ; async throws {
l; et results =; ; try await NetworkDiagnostics.measureLatency()
l; et avgLatency = results.reduce(0.0) { $0 + $1.latency } / Double(results.count)

l; et status: TestResult.Status
i; f avgLatency < 50 {
status = .success
}; ; else if avgLatency < 100 {
status = .warning
} else {
status = .failure
}

addTestResult(
name: "; ; Network Latency",
status: status,
message: "; ; Average latency: \(Int(avgLatency))ms"
)

i; f status == .failure {
t; hrow NetworkError.highLatency
}
}

p; rivate func testBandwidth(); ; async throws {
l; et speed =; ; try await NetworkDiagnostics.measureBandwidth()

l; et status: TestResult.Status
i; f speed > 10_000_000 { // 10 Mbps
status = .success
}; ; else if speed > 1_000_000 { // 1 Mbps
status = .warning
} else {
status = .failure
}

l; et speedMbps = Double(speed) / 1_000_000.0
addTestResult(
name: "; ; Network Bandwidth",
status: status,
message: String(format: "; ; Download speed: %.1; ; f Mbps", speedMbps)
)

i; f status == .failure {
t; hrow NetworkError.lowBandwidth
}
}

p; rivate func addTestResult(name: String, status: TestResult.Status, message: String) {
DispatchQueue.main.async {
testResults.append(TestResult(
name: name,
status: status,
message: message,
timestamp: Date()
))
}
}

p; rivate func handleTestError(_ error: Error) {
DispatchQueue.main.async {
isRunningTests = false
currentTest = nil
lastError = error
showingErrorAlert = true

addTestResult(
name: "; ; Test Error",
status: .failure,
message: error.localizedDescription
)
}
}
} 