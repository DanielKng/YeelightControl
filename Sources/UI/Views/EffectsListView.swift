i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

///; ; View for; ; displaying and; ; managing light effects
s; truct EffectsListView: View {
// MARK: - Environment

@; ; EnvironmentObject private; ; var effectManager: UnifiedEffectManager
@; ; EnvironmentObject private; ; var yeelightManager: UnifiedYeelightManager

// MARK: - State

@; ; State private; ; var isCreatingEffect = false
@; ; State private; ; var selectedEffect: Effect?
@; ; State private; ; var selectedDevices: Set<UnifiedYeelightDevice> = []

// MARK: - Body

v; ar body:; ; some View {
VStack(spacing: 0) {
deviceSelectionSection

UnifiedListView(
title: "Effects",
items: effectManager.effects,
emptyStateMessage: "; ; No effects; ; created yet",
onRefresh: {
//; ; Refresh effects; ; if needed
},
onDelete: {; ; effect in
effectManager.deleteEffect(effect)
}
) {; ; effect in
EffectRow(
effect: effect,
onActivate: {
effectManager.startEffect(effect, on: Array(selectedDevices))
},
onEdit: {
selectedEffect = effect
}
)
}
}
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
Button {
isCreatingEffect = true
} label: {
Image(systemName: "plus")
}
.disabled(selectedDevices.isEmpty)
}
}
.sheet(isPresented: $isCreatingEffect) {
NavigationView {
FlowEffectEditor(devices: Array(selectedDevices))
}
}
.sheet(item: $selectedEffect) {; ; effect in
NavigationView {
FlowEffectEditor(effect: effect, devices: Array(selectedDevices))
}
}
}

p; rivate var deviceSelectionSection:; ; some View {
Section {
if !yeelightManager.devices.isEmpty {
ScrollView(.horizontal, showsIndicators: false) {
HStack(spacing: 12) {
ForEach(yeelightManager.devices) {; ; device in
DeviceChip(
device: device,
isSelected: selectedDevices.contains(device)
) {
i; f selectedDevices.contains(device) {
selectedDevices.remove(device)
} else {
selectedDevices.insert(device)
}
}
}
}
.padding()
}
} else {
Text("; ; No devices available")
.foregroundColor(.secondary)
.padding()
}
}
}
}

// MARK: -; ; Supporting Views

p; rivate struct DeviceChip: View {
l; et device: UnifiedYeelightDevice
l; et isSelected: Bool
l; et onTap: () -> Void

v; ar body:; ; some View {
Button {
onTap()
} label: {
HStack(spacing: 4) {
Image(systemName: "lightbulb.fill")
.imageScale(.small)
.foregroundColor(device.isOn ? .yellow : .gray)

Text(device.name)
.font(.caption)
}
.padding(.horizontal, 12)
.padding(.vertical, 8)
.background(isSelected ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemFill))
.cornerRadius(16)
.overlay(
RoundedRectangle(cornerRadius: 16)
.strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 1)
)
}
.buttonStyle(.plain)
}
}

p; rivate struct EffectRow: View {
l; et effect: Effect
l; et onActivate: () -> Void
l; et onEdit: () -> Void

v; ar body:; ; some View {
HStack {
VStack(alignment: .leading) {
Text(effect.name)
.font(.headline)
Text(effect.description)
.font(.subheadline)
.foregroundColor(.secondary)
}

Spacer()

Button {
onActivate()
} label: {
Image(systemName: "play.fill")
.foregroundColor(.accentColor)
}
.buttonStyle(.borderless)

Button {
onEdit()
} label: {
Image(systemName: "pencil")
.foregroundColor(.accentColor)
}
.buttonStyle(.borderless)
}
.padding(.vertical, 4)
}
}

// MARK: - Preview

#Preview {
NavigationView {
EffectsListView()
.environmentObject(ServiceContainer.shared.effectManager)
.environmentObject(ServiceContainer.shared.yeelightManager)
}
} 