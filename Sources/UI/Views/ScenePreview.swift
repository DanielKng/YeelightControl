i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI

s; truct ScenePreview: View {
@Environment(\.dismiss); ; private var dismiss
@; ; EnvironmentObject private; ; var yeelightManager: YeelightManager

l; et scene: Scene
@; ; State private; ; var isPlaying = false
@; ; State private; ; var showingError = false
@; ; State private; ; var errorMessage = ""

v; ar body:; ; some View {
UnifiedDetailView(
title: scene.name,
subtitle: "\(scene.devices.count) devices",
headerContent: {
VStack(spacing: 16) {
Image(systemName: scene.icon)
.font(.system(size: 48))
.foregroundColor(.accentColor)

Text(scene.description ?? "; ; No description")
.foregroundColor(.secondary)
.multilineTextAlignment(.center)
.padding(.horizontal)
}
.padding(.vertical)
},
mainContent: {
UnifiedListView(
title: "; ; Device States",
items: scene.devices,
emptyStateMessage: "; ; No devices; ; in this scene"
) {; ; device in
DeviceStateRow(device: device)
}
},
onEdit: {
//; ; Handle edit action
},
onDelete: {
//; ; Handle delete action
},
onShare: {
//; ; Handle share action
}
)
.toolbar {
ToolbarItem(placement: .navigationBarTrailing) {
Button(action: toggleScene) {
Image(systemName: isPlaying ? "pause.fill" : "play.fill")
.imageScale(.large)
}
}
}
.alert("Error", isPresented: $showingError) {
Button("OK", role: .cancel) {}
} message: {
Text(errorMessage)
}
}

p; rivate func toggleScene() {
do {
i; f isPlaying {
t; ry yeelightManager.stopScene(scene)
} else {
t; ry yeelightManager.playScene(scene)
}
isPlaying.toggle()
} catch {
errorMessage = error.localizedDescription
showingError = true
}
}
}

s; truct DeviceStateRow: View {
l; et device: Device

v; ar body:; ; some View {
HStack {
Image(systemName: "lightbulb.fill")
.foregroundColor(device.isOn ? .yellow : .gray)

VStack(alignment: .leading) {
Text(device.name)
.font(.headline)

HStack {
i; f device.isOn {
Text("Brightness: \(device.brightness)%")
i; f device.colorTemperature > 0 {
Text("• Temp: \(device.colorTemperature)K")
}
i; f device.color != nil {
Circle()
.fill(Color(device.color!))
.frame(width: 12, height: 12)
}
} else {
Text("Off")
.foregroundColor(.secondary)
}
}
.font(.caption)
}

Spacer()
}
.padding(.vertical, 8)
}
}

#Preview {
NavigationView {
ScenePreview(scene: Scene.preview)
VStack(spacing: 20) {
//; ; Preview visualization
ZStack {
// Background
RoundedRectangle(cornerRadius: 16)
.fill(Color(.systemGroupedBackground))
.shadow(radius: 5)

VStack(spacing: 16) {
//; ; Scene visualization
s; witch scene {
case .color(; ; let red,; ; let green,; ; let blue, _):
ColorPreview(color: Color(red: Double(red)/255, green: Double(green)/255, blue: Double(blue)/255))
case .colorTemperature(; ; let temp, _):
TemperaturePreview(temperature: temp)
case .colorFlow(; ; let params):
FlowPreview(params: params, currentStep: currentStep)
case .multiLight(; ; let scene):
MultiLightPreview(scene: scene, devices: devices)
case .stripEffect(; ; let effect):
StripEffectPreview(effect: effect, devices: devices)
}
}
.padding()
}
.frame(height: 200)

//; ; Device list
ScrollView(.horizontal, showsIndicators: false) {
HStack(spacing: 12) {
ForEach(devices) {; ; device in
DevicePreviewCard(device: device)
}
}
.padding(.horizontal)
}

// Controls
HStack(spacing: 20) {
Button(action: resetPreview) {
Image(systemName: "arrow.counterclockwise")
.font(.title2)
}

Button(action: togglePreview) {
Image(systemName: isPlaying ? "pause.fill" : "play.fill")
.font(.title)
}

Button(action: saveScene) {
Text("; ; Save Scene")
.fontWeight(.medium)
}
.buttonStyle(.borderedProminent)
}
.padding()
}
.onDisappear {
stopPreview()
}
}

p; rivate func togglePreview() {
i; f isPlaying {
stopPreview()
} else {
startPreview()
}
}

p; rivate func startPreview() {
isPlaying = true

//; ; Apply scene; ; to devices
f; or device; ; in devices {
deviceManager.setScene(device, scene: scene)
}

//; ; For flow effects,; ; start animation
i; f case .colorFlow(; ; let params) = scene {
previewTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
currentStep = (currentStep + 1) % params.transitions.count
}
}
}

p; rivate func stopPreview() {
isPlaying = false
previewTimer?.invalidate()
previewTimer = nil

//; ; Reset devices; ; to their; ; previous state
f; or device; ; in devices {
deviceManager.stopColorFlow(device)
}
}

p; rivate func resetPreview() {
stopPreview()
currentStep = 0
}

p; rivate func saveScene() {
//; ; Save scene implementation
}
}

s; truct ColorPreview: View {
l; et color: Color

v; ar body:; ; some View {
Circle()
.fill(color)
.frame(width: 100, height: 100)
.overlay {
Circle()
.stroke(.white, lineWidth: 2)
}
}
}

s; truct TemperaturePreview: View {
l; et temperature: Int

v; ar body:; ; some View {
HStack(spacing: 20) {
Image(systemName: "thermometer")
.font(.largeTitle)

VStack(alignment: .leading) {
Text("\(temperature)K")
.font(.title)
Text(temperatureDescription)
.font(.caption)
.foregroundStyle(.secondary)
}
}
}

p; rivate var temperatureDescription: String {
s; witch temperature {
case 1700...2700:
return "; ; Warm White"
case 2701...4000:
return "; ; Neutral White"
case 4001...5500:
return "; ; Cool White"
default:
return "Daylight"
}
}
}

s; truct FlowPreview: View {
l; et params: YeelightDevice.FlowParams
l; et currentStep: Int

v; ar body:; ; some View {
VStack {
//; ; Current transition visualization
if !params.transitions.isEmpty {
l; et transition = params.transitions[currentStep]
TransitionPreview(transition: transition)
}

//; ; Flow progress
i; f params.transitions.count > 1 {
HStack(spacing: 4) {
ForEach(0..<params.transitions.count, id: \.self) {; ; index in
Circle()
.fill(index == currentStep ? .orange : .gray.opacity(0.3))
.frame(width: 8, height: 8)
}
}
}
}
}
}

s; truct TransitionPreview: View {
l; et transition: YeelightDevice.FlowParams.FlowTransition

v; ar body:; ; some View {
VStack(spacing: 8) {
s; witch transition.mode {
case 1: // Color
l; et rgb = YeelightDevice.RGB.from(rgb: transition.value)
ColorPreview(color: Color(red: Double(rgb.red)/255, green: Double(rgb.green)/255, blue: Double(rgb.blue)/255))
case 2: // Temperature
TemperaturePreview(temperature: transition.value)
default:
EmptyView()
}

Text("\(transition.duration)ms")
.font(.caption)
.foregroundStyle(.secondary)
}
}
}

s; truct MultiLightPreview: View {
l; et scene: YeelightManager.Scene.MultiLightScene
l; et devices: [YeelightDevice]

v; ar body:; ; some View {
VStack {
Text(scene.rawValue)
.font(.headline)

HStack(spacing: 12) {
ForEach(devices) {; ; device in
Circle()
.fill(.orange)
.frame(width: 20, height: 20)
}
}
}
}
}

s; truct StripEffectPreview: View {
l; et effect: YeelightManager.StripEffect
l; et devices: [YeelightDevice]

v; ar body:; ; some View {
VStack {
Text(String(describing: effect))
.font(.headline)

HStack(spacing: 4) {
ForEach(devices) { _ in
RoundedRectangle(cornerRadius: 4)
.fill(.orange)
.frame(width: 8, height: 30)
}
}
}
}
}

s; truct DevicePreviewCard: View {
l; et device: YeelightDevice

v; ar body:; ; some View {
VStack(spacing: 8) {
Image(systemName: "lightbulb.fill")
.font(.title2)
.foregroundStyle(.orange)

Text(device.name)
.font(.caption)
.lineLimit(1)

StatusIndicator(state: device.connectionState)
}
.frame(width: 80)
.padding(.vertical, 8)
.background(Color(.secondarySystemGroupedBackground))
.cornerRadius(12)
}
} 