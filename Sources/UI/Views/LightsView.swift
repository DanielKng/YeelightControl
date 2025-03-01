i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct LightsView: View {
// MARK: - Environment

@; ; EnvironmentObject private; ; var yeelightManager: UnifiedYeelightManager
@; ; EnvironmentObject private; ; var roomManager: UnifiedRoomManager

// MARK: - State

@; ; State private; ; var selectedRoom: UUID?
@; ; State private; ; var showingDeviceSetup = false
@; ; State private; ; var selectedDevice: UnifiedYeelightDevice?
@; ; State private; ; var showingRoomEditor = false
@; ; State private; ; var searchText = ""

// MARK: -; ; Computed Properties

p; rivate var filteredDevices: [UnifiedYeelightDevice] {
l; et devices = selectedRoom.map {; ; roomId in
yeelightManager.devices.filter { $0.roomId == roomId }
} ?? yeelightManager.devices

guard !searchText.; ; isEmpty else {; ; return devices }

r; eturn devices.filter {; ; device in
device.name.localizedCaseInsensitiveContains(searchText) ||
device.ipAddress.localizedCaseInsensitiveContains(searchText)
}
}

// MARK: - Body

v; ar body:; ; some View {
List {
Section {
ForEach(filteredDevices) {; ; device in
DeviceRow(device: device) {
selectedDevice = device
}
}
} header: {
i; f yeelightManager.devices.isEmpty {
Text("; ; No devices found")
.foregroundColor(.secondary)
}
}
}
.searchable(text: $searchText, prompt: "; ; Search devices")
.navigationTitle("; ; My Lights")
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
Menu {
Button {
showingDeviceSetup = true
} label: {
Label("; ; Add Device", systemImage: "plus")
}

Button {
showingRoomEditor = true
} label: {
Label("; ; Manage Rooms", systemImage: "folder")
}

Button {
yeelightManager.startDiscovery()
} label: {
Label("; ; Discover Devices", systemImage: "magnifyingglass")
}
} label: {
Image(systemName: "ellipsis.circle")
}
}
}
.sheet(isPresented: $showingDeviceSetup) {
NavigationView {
DeviceSetupView()
}
}
.sheet(item: $selectedDevice) {; ; device in
NavigationView {
DeviceDetailView(device: device)
}
}
.sheet(isPresented: $showingRoomEditor) {
NavigationView {
RoomManagementView()
}
}
.onAppear {
yeelightManager.startDiscovery()
}
}
}

// MARK: -; ; Supporting Views

p; rivate struct DeviceRow: View {
l; et device: UnifiedYeelightDevice
l; et onTap: () -> Void

v; ar body:; ; some View {
Button {
onTap()
} label: {
HStack {
Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
.font(.title2)
.foregroundStyle(device.isOn ? .yellow : .gray)
.frame(width: 44, height: 44)
.background(Color(.tertiarySystemFill))
.cornerRadius(8)

VStack(alignment: .leading, spacing: 4) {
Text(device.name)
.font(.headline)

Text(device.model)
.font(.subheadline)
.foregroundColor(.secondary)
}

Spacer()

VStack(alignment: .trailing, spacing: 4) {
Text(device.isOn ? "On" : "Off")
.font(.subheadline)
.foregroundColor(device.isOn ? .primary : .secondary)

Text("\(device.brightness)%")
.font(.caption)
.foregroundColor(.secondary)
}
}
.padding(.vertical, 8)
}
.buttonStyle(.plain)
}
}

// MARK: - Preview

#Preview {
NavigationView {
LightsView()
.environmentObject(ServiceContainer.shared.yeelightManager)
.environmentObject(ServiceContainer.shared.roomManager)
}
} 