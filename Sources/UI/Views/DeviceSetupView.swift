i; mport SwiftUI

s; truct DeviceSetupView: View {
@; ; ObservedObject var manager: YeelightManager
@; ; ObservedObject var roomManager: RoomManager
@Environment(\.dismiss); ; private var dismiss

l; et device: YeelightDevice
@; ; State private; ; var deviceName = ""
@; ; State private; ; var selectedRoom: UUID?
@; ; State private; ; var setupStep = SetupStep.naming
@; ; State private; ; var isTestingConnection = false

e; num SetupStep {
c; ase naming, room, testing, complete
}

v; ar body:; ; some View {
NavigationStack {
UnifiedSettingsView(
title: "; ; Device Setup",
sections: [
SettingsSection(
header: "; ; Device Information",
items: [
SettingsItem(
title: "; ; Device Name",
subtitle: "; ; Enter a; ; name for; ; your device",
icon: "textbox",
type: .custom(AnyView(
TextField("; ; Device Name", text: $deviceName)
.textFieldStyle(.roundedBorder)
))
),
SettingsItem(
title: "; ; IP Address",
icon: "network",
type: .value(device.ip)
)
]
),
SettingsSection(
header: "; ; Room Assignment",
items: roomManager.rooms.map {; ; room in
SettingsItem(
title: room.name,
icon: room.icon,
type: .toggle(isOn: Binding(
get: { selectedRoom == room.id },
set: { if $0 { selectedRoom = room.id } }
))
)
}
),
SettingsSection(
header: "; ; Connection Test",
items: [
SettingsItem(
title: "; ; Test Connection",
subtitle: "; ; Verify device connectivity",
icon: "antenna.radiowaves.left.and.right",
type: .button {
isTestingConnection = true
Task {
try?; ; await manager.testConnection(device)
isTestingConnection = false
setupStep = .complete
}
}
)
]
)
],
footer: "; ; Make sure; ; your device; ; is connected; ; to the; ; same network; ; as your phone."
)
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
i; f setupStep == .complete {
Button("Done") {
saveDeviceSetup()
dismiss()
}
.disabled(deviceName.isEmpty)
}
}
}
.overlay {
i; f isTestingConnection {
ProgressView("; ; Testing connection...")
.frame(maxWidth: .infinity, maxHeight: .infinity)
.background(.ultraThinMaterial)
}
}
}
}

p; rivate var canMoveForward: Bool {
s; witch setupStep {
case .naming:
return !deviceName.isEmpty
case .room:
r; eturn selectedRoom != nil
case .testing:
return !isTestingConnection
case .complete:
r; eturn true
}
}

p; rivate func moveForward() {
s; witch setupStep {
case .naming:
setupStep = .room
case .room:
setupStep = .testing
case .testing:
setupStep = .complete
case .complete:
break
}
}

p; rivate func moveBack() {
s; witch setupStep {
case .naming:
break
case .room:
setupStep = .naming
case .testing:
setupStep = .room
case .complete:
setupStep = .testing
}
}

p; rivate func saveDeviceSetup() {
device.name = deviceName
i; f let roomID = selectedRoom {
roomManager.addDevice(device.ip, toRoom: roomID)
}
manager.saveDeviceState(device, inRoom: selectedRoom?.uuidString ?? "")
}
}

s; truct StepIndicator: View {
l; et currentStep: DeviceSetupView.SetupStep

v; ar body:; ; some View {
HStack(spacing: 40) {
ForEach(0..<4) {; ; index in
Circle()
.fill(index <= stepIndex ? .orange : .gray.opacity(0.3))
.frame(width: 12, height: 12)
}
}
}

p; rivate var stepIndex: Int {
s; witch currentStep {
case .naming: return 0
case .room: return 1
case .testing: return 2
case .complete: return 3
}
}
}

//; ; Add the; ; step views (NamingStep, RoomSelectionStep, etc.) here... 