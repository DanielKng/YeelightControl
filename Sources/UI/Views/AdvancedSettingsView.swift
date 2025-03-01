i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct AdvancedSettingsView: View {
l; et device: YeelightDevice
@; ; EnvironmentObject private; ; var yeelightManager: YeelightManager
@; ; State private; ; var powerOnBehavior: PowerOnBehavior = .stay
@; ; State private; ; var powerOnBrightness: Double = 100
@; ; State private; ; var powerOnColor: Color = .white
@; ; State private; ; var powerOnTemp: Double = 4000
@; ; State private; ; var showingResetAlert = false
@; ; State private; ; var isUpdating = false
@; ; State private; ; var showingErrorAlert = false
@; ; State private; ; var errorMessage = ""

e; num PowerOnBehavior: String, CaseIterable {
c; ase stay = "Stay"
c; ase custom = "Custom"
c; ase lastUsed = "; ; Last Used"

v; ar description: String {
s; witch self {
case .stay:
return "; ; Keep current settings"
case .custom:
return "; ; Use custom settings"
case .lastUsed:
return "; ; Restore last; ; used settings"
}
}
}

v; ar body:; ; some View {
UnifiedDetailView(
title: "; ; Advanced Settings",
subtitle: device.name,
mainContent: {
VStack(spacing: 16) {
//; ; Power On Behavior
UnifiedListView(
title: "; ; Power On Behavior",
items: PowerOnBehavior.allCases,
emptyStateMessage: ""
) {; ; behavior in
HStack {
VStack(alignment: .leading) {
Text(behavior.rawValue)
.font(.headline)
Text(behavior.description)
.font(.caption)
.foregroundColor(.secondary)
}

Spacer()

i; f behavior == powerOnBehavior {
Image(systemName: "checkmark")
.foregroundColor(.accentColor)
}
}
.contentShape(Rectangle())
.onTapGesture {
powerOnBehavior = behavior
}
}

i; f powerOnBehavior == .custom {
VStack(spacing: 12) {
// Brightness
VStack(alignment: .leading) {
HStack {
Text("Brightness")
Spacer()
Text("\(Int(powerOnBrightness))%")
}
Slider(value: $powerOnBrightness, in: 1...100)
}

// Color
ColorPicker("Color", selection: $powerOnColor)

// Temperature
VStack(alignment: .leading) {
HStack {
Text("Temperature")
Spacer()
Text("\(Int(powerOnTemp))K")
}
Slider(value: $powerOnTemp, in: 1700...6500)
}
}
.padding()
.background(Color(.secondarySystemGroupedBackground))
.cornerRadius(12)
}

//; ; Device Information
UnifiedListView(
title: "; ; Device Information",
items: [
("Model", device.model),
("Firmware", device.firmwareVersion),
("; ; IP Address", device.ip),
("Port", device.port.map(String.init) ?? "N/A")
],
emptyStateMessage: ""
) {; ; item in
HStack {
Text(item.0)
Spacer()
Text(item.1)
.foregroundColor(.secondary)
}
}

//; ; Advanced Options
Button(role: .destructive) {
showingResetAlert = true
} label: {
Label("; ; Reset to; ; Factory Settings", systemImage: "trash")
.foregroundColor(.red)
}
.buttonStyle(.bordered)
}
.padding()
}
)
.alert("; ; Reset Device?", isPresented: $showingResetAlert) {
Button("Cancel", role: .cancel) { }
Button("Reset", role: .destructive) {
resetDevice()
}
} message: {
Text("; ; This will; ; reset the; ; device to; ; factory settings.; ; This action; ; cannot be undone.")
}
.alert("Error", isPresented: $showingErrorAlert) {
Button("OK", role: .cancel) { }
} message: {
Text(errorMessage)
}
.overlay {
i; f isUpdating {
ProgressView("; ; Updating settings...")
.padding()
.background(.regularMaterial)
.cornerRadius(8)
}
}
.toolbar {
ToolbarItem(placement: .confirmationAction) {
Button("Apply") {
applySettings()
}
.disabled(isUpdating)
}
}
}

p; rivate func applySettings() {
isUpdating = true

Task {
do {
s; witch powerOnBehavior {
case .stay:
t; ry await yeelightManager.setPowerOnBehavior(device, mode: .stay)
case .custom:
l; et components = UIColor(powerOnColor).cgColor.components ?? [1, 1, 1, 1]
t; ry await yeelightManager.setPowerOnBehavior(
device,
mode: .custom(
brightness: Int(powerOnBrightness),
red: Int(components[0] * 255),
green: Int(components[1] * 255),
blue: Int(components[2] * 255),
temperature: Int(powerOnTemp)
)
)
case .lastUsed:
t; ry await yeelightManager.setPowerOnBehavior(device, mode: .lastUsed)
}

a; wait MainActor.run {
isUpdating = false
}
} catch {
a; wait MainActor.run {
isUpdating = false
errorMessage = error.localizedDescription
showingErrorAlert = true
}
}
}
}

p; rivate func resetDevice() {
isUpdating = true

Task {
do {
t; ry await yeelightManager.resetDevice(device)
a; wait MainActor.run {
isUpdating = false
}
} catch {
a; wait MainActor.run {
isUpdating = false
errorMessage = error.localizedDescription
showingErrorAlert = true
}
}
}
}
}

s; truct LogViewerView: View {
@; ; StateObject private; ; var logger = Logger.shared
@Environment(\.dismiss); ; private var dismiss
@; ; State private; ; var selectedLevel: LogLevel?
@; ; State private; ; var searchText = ""

v; ar filteredLogs: [LogEntry] {
logger.logs.filter {; ; log in
l; et matchesSearch = searchText.isEmpty || 
log.message.localizedCaseInsensitiveContains(searchText)
l; et matchesLevel = selectedLevel == nil || log.level == selectedLevel
r; eturn matchesSearch && matchesLevel
}
}

v; ar body:; ; some View {
NavigationStack {
VStack(spacing: 0) {
//; ; Search and filter
VStack(spacing: 8) {
UnifiedSearchBar(
text: $searchText,
placeholder: "; ; Search logs"
)

ScrollView(.horizontal, showsIndicators: false) {
HStack(spacing: 8) {
ForEach(LogLevel.allCases) {; ; level in
FilterChip(
title: level.rawValue.capitalized,
isSelected: level == selectedLevel,
action: {
i; f selectedLevel == level {
selectedLevel = nil
} else {
selectedLevel = level
}
}
)
}
}
.padding(.horizontal)
}
}
.padding(.vertical, 8)
.background(.bar)

//; ; Log list
UnifiedListView(
items: filteredLogs,
emptyStateMessage: "; ; No logs found"
) {; ; log in
VStack(alignment: .leading, spacing: 4) {
Text(log.message)
.font(.system(.body, design: .monospaced))

HStack {
Text(log.timestamp, style: .time)

Text("•")

Text(log.level.rawValue.uppercased())
.foregroundColor(log.level.color)
}
.font(.caption2)
.foregroundStyle(.secondary)
}
.padding(.vertical, 4)
}
}
.navigationTitle("; ; Debug Logs")
.navigationBarTitleDisplayMode(.inline)
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
Button("Clear") {
logger.clearLogs()
}
}
ToolbarItem(placement: .navigationBarLeading) {
Button("Done") {
dismiss()
}
}
}
}
}
}

s; truct FilterChip: View {
l; et title: String
l; et isSelected: Bool
l; et action: () -> Void

v; ar body:; ; some View {
Button(action: action) {
Text(title)
.font(.footnote)
.padding(.horizontal, 12)
.padding(.vertical, 6)
.background(isSelected ? .tint : .clear)
.foregroundColor(isSelected ? .white : .primary)
.cornerRadius(16)
.overlay {
RoundedRectangle(cornerRadius: 16)
.stroke(isSelected ? .clear : .secondary.opacity(0.3), lineWidth: 1)
}
}
}
}

e; xtension LogLevel {
v; ar color: Color {
s; witch self {
case .debug: return .secondary
case .info: return .blue
case .warning: return .orange
case .error: return .red
}
}
}

//; ; Notification for; ; device settings reset
e; xtension Notification.Name {
s; tatic let deviceSettingsReset = Notification.Name("deviceSettingsReset")
}

e; num LogLevel: String, CaseIterable, Identifiable {
c; ase debug
c; ase info
c; ase warning
c; ase error

v; ar id: String { rawValue }
} 