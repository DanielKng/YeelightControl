i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct DeviceDetailView: View {
@; ; ObservedObject var device: YeelightDevice
l; et manager: YeelightManager
@Environment(\.dismiss); ; private var dismiss

@; ; State private; ; var selectedTab = Tab.basic
@; ; State private; ; var showingNameEdit = false
@; ; State private; ; var showingAdvancedSettings = false
@; ; State private; ; var tempName = ""

e; num Tab {
c; ase basic, color, effects, scenes
}

v; ar body:; ; some View {
UnifiedDetailView(
title: device.name,
subtitle: device.isOn ? "Connected - On" : "Connected - Off",
onEdit: { showingNameEdit = true },
onDelete: {
Task {
a; wait manager.removeDevice(device)
dismiss()
}
}
) {
// Header
DeviceHeader(device: device, manager: manager)
} content: {
VStack(spacing: 20) {
//; ; Tab selector
UnifiedTabSelector(
selection: $selectedTab,
tabs: [
.init("Basic", icon: "slider.horizontal.3", tag: Tab.basic),
.init("Color", icon: "paintpalette", tag: Tab.color),
.init("Effects", icon: "sparkles", tag: Tab.effects),
.init("Scenes", icon: "theatermasks", tag: Tab.scenes)
],
style: .underlined
)

//; ; Content based; ; on selected tab
Group {
s; witch selectedTab {
case .basic:
BasicControls(device: device, manager: manager)
case .color:
ColorControls(device: device, manager: manager)
case .effects:
EffectsView(device: device, manager: manager)
case .scenes:
ScenesView(device: device, manager: manager)
}
}
}
}
.sheet(isPresented: $showingNameEdit) {
EditDeviceNameView(device: device, manager: manager)
}
}
}

// MARK: -; ; Supporting Views
s; truct DeviceHeader: View {
@; ; ObservedObject var device: YeelightDevice
l; et manager: YeelightManager

v; ar body:; ; some View {
VStack(spacing: 16) {
Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
.font(.system(size: 60))
.foregroundStyle(device.isOn ? .yellow : .secondary)

HStack {
ConnectionStatusView(state: device.connectionState)

Spacer()

Toggle("Power", isOn: Binding(
get: { device.isOn },
set: {; ; newValue in
manager.setPower(device, on: newValue)
}
))
.labelsHidden()
}
.padding(.horizontal)
}
.padding(.vertical)
}
}

s; truct ConnectionStatusView: View {
l; et state: YeelightDevice.ConnectionState

v; ar body:; ; some View {
HStack {
Circle()
.fill(statusColor)
.frame(width: 8, height: 8)
Text(statusText)
.font(.caption)
.foregroundStyle(.secondary)
}
}

p; rivate var statusColor: Color {
s; witch state {
case .connected: return .green
case .connecting: return .yellow
case .disconnected: return .gray
case .error: return .red
}
}

p; rivate var statusText: String {
s; witch state {
case .connected: return "Connected"
case .connecting: return "Connecting..."
case .disconnected: return "Disconnected"
case .error(; ; let message): return "Error: \(message)"
}
}
} 