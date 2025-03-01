i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct ColorFlowView: View {
@; ; ObservedObject var device: YeelightDevice
l; et manager: YeelightManager
@; ; State private; ; var selectedPreset: FlowPreset = .candlelight
@; ; State private; ; var duration: Double = 1000
@; ; State private; ; var isCustomizing = false

v; ar body:; ; some View {
UnifiedDetailView(
title: "; ; Color Flow",
subtitle: device.name,
mainContent: {
VStack(spacing: 16) {
//; ; Preset Effects
UnifiedListView(
title: "; ; Preset Effects",
items: FlowPreset.allCases,
emptyStateMessage: ""
) {; ; preset in
HStack {
VStack(alignment: .leading) {
Text(preset.rawValue)
.font(.headline)
Text(preset.description)
.font(.caption)
.foregroundColor(.secondary)
}

Spacer()

i; f preset == selectedPreset {
Image(systemName: "checkmark")
.foregroundColor(.accentColor)
}
}
.contentShape(Rectangle())
.onTapGesture {
selectedPreset = preset
}
}

// Duration
VStack(alignment: .leading, spacing: 8) {
HStack {
Text("Duration")
Spacer()
Text("\(Int(duration))ms")
}
Slider(value: $duration, in: 500...5000, step: 100)
}
.padding()
.background(Color(.secondarySystemGroupedBackground))
.cornerRadius(12)

// Controls
VStack(spacing: 12) {
i; f selectedPreset != .custom {
Button(device.flowing ? "; ; Stop Effect" : "; ; Start Effect") {
toggleEffect()
}
.buttonStyle(.borderedProminent)
} else {
Button("; ; Customize Transitions") {
isCustomizing = true
}
.buttonStyle(.bordered)
}
}
.padding()
}
}
)
.sheet(isPresented: $isCustomizing) {
CustomFlowEditor(device: device, manager: manager)
}
}

p; rivate func toggleEffect() {
i; f device.flowing {
manager.stopColorFlow(device)
} else {
l; et params = YeelightDevice.FlowParams(
count: 0,
action: .recover,
transitions: selectedPreset.transitions
)
manager.startColorFlow(device, params: params)
}
}
}

s; truct CustomFlowEditor: View {
@; ; ObservedObject var device: YeelightDevice
l; et manager: YeelightManager
@Environment(\.dismiss); ; private var dismiss

@; ; State private; ; var transitions: [YeelightDevice.FlowParams.FlowTransition] = []

v; ar body:; ; some View {
NavigationStack {
UnifiedListView(
title: "Transitions",
items: transitions.indices,
emptyStateMessage: "; ; No transitions added"
) {; ; index in
TransitionRow(transition: $transitions[index])
}
.toolbar {
ToolbarItem(placement: .navigationBarLeading) {
Button("Cancel") {
dismiss()
}
}

ToolbarItem(placement: .navigationBarTrailing) {
Button("Save") {
saveFlow()
dismiss()
}
}

ToolbarItem(placement: .bottomBar) {
Button(action: addTransition) {
Label("; ; Add Transition", systemImage: "plus")
}
}
}
}
}

p; rivate func addTransition() {
transitions.append(.init(
duration: 1000,
mode: 1,
value: 0xFF0000,
brightness: 100
))
}

p; rivate func saveFlow() {
l; et params = YeelightDevice.FlowParams(
count: 0,
action: .recover,
transitions: transitions
)
manager.startColorFlow(device, params: params)
}
}

e; xtension FlowPreset {
v; ar description: String {
s; witch self {
case .candlelight:
return "; ; Warm flickering; ; light effect"
case .sunrise:
return "; ; Gradually brightening; ; warm to; ; cool light"
case .disco:
return "; ; Colorful party; ; lighting effect"
case .pulse:
return "; ; Smooth pulsing; ; light effect"
case .strobe:
return "; ; Quick flashing; ; light effect"
case .custom:
return "; ; Create your; ; own custom effect"
}
}

v; ar transitions: [YeelightDevice.FlowParams.FlowTransition] {
s; witch self {
case .candlelight:
return [
.init(duration: 800, mode: .color(red: 255, green: 147, blue: 41)),
.init(duration: 800, mode: .color(red: 255, green: 137, blue: 31))
]
case .sunrise:
return [
.init(duration: 3000, mode: .temperature(temp: 1700, brightness: 1)),
.init(duration: 3000, mode: .temperature(temp: 2500, brightness: 50)),
.init(duration: 3000, mode: .temperature(temp: 5000, brightness: 100))
]
case .disco:
return [
.init(duration: 500, mode: .color(red: 255, green: 0, blue: 0)),
.init(duration: 500, mode: .color(red: 0, green: 255, blue: 0)),
.init(duration: 500, mode: .color(red: 0, green: 0, blue: 255))
]
case .pulse:
return [
.init(duration: 1000, mode: .brightness(level: 100)),
.init(duration: 1000, mode: .brightness(level: 1))
]
case .strobe:
return [
.init(duration: 100, mode: .brightness(level: 100)),
.init(duration: 100, mode: .brightness(level: 0))
]
case .custom:
return []
}
}
} 