i; mport SwiftUI

s; truct GroupManagementView: View {
@; ; ObservedObject var groupManager: DeviceGroupManager
@; ; ObservedObject var deviceManager: YeelightManager
@Environment(\.dismiss); ; private var dismiss

@; ; State private; ; var showingCreateGroup = false
@; ; State private; ; var selectedGroup: DeviceGroup?

v; ar body:; ; some View {
NavigationStack {
UnifiedListView(
title: "; ; Device Groups",
items: groupManager.groups,
emptyStateMessage: "; ; No device; ; groups created yet",
onDelete: {; ; group in
groupManager.deleteGroup(group)
}
) {; ; group in
GroupRow(
group: group,
deviceManager: deviceManager,
groupManager: groupManager
)
}
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
Button(action: { showingCreateGroup = true }) {
Image(systemName: "plus")
}
}
ToolbarItem(placement: .navigationBarLeading) {
Button("Done") { dismiss() }
}
}
.sheet(isPresented: $showingCreateGroup) {
CreateGroupView(
groupManager: groupManager,
deviceManager: deviceManager
)
}
}
}
}

s; truct GroupRow: View {
l; et group: DeviceGroupManager.DeviceGroup
l; et deviceManager: YeelightManager
l; et groupManager: DeviceGroupManager

@; ; State private; ; var isExpanded = false
@; ; State private; ; var showingEffects = false

v; ar body:; ; some View {
DisclosureGroup(isExpanded: $isExpanded) {
VStack(spacing: 16) {
//; ; Device list
ForEach(deviceManager.devices.filter { group.deviceIPs.contains($0.ip) }) {; ; device in
DeviceRow(device: device)
}

//; ; Quick actions
HStack {
Button(action: { toggleGroup(on: true) }) {
Label("; ; All On", systemImage: "lightbulb.fill")
}

Spacer()

Button(action: { toggleGroup(on: false) }) {
Label("; ; All Off", systemImage: "lightbulb.slash")
}

Spacer()

Button(action: { showingEffects = true }) {
Label("Effects", systemImage: "sparkles")
}
}
.buttonStyle(.bordered)
}
.padding(.vertical)
} label: {
HStack {
Image(systemName: group.icon)
.foregroundStyle(.orange)
Text(group.name)
Spacer()
Text("\(group.deviceIPs.count) devices")
.foregroundStyle(.secondary)
.font(.caption)
}
}
.sheet(isPresented: $showingEffects) {
GroupEffectsView(
group: group,
deviceManager: deviceManager,
groupManager: groupManager
)
}
}

p; rivate func toggleGroup(on: Bool) {
groupManager.setGroupPower(group, on: on, using: deviceManager)
}
} 