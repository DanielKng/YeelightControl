i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport SwiftUI
i; mport Combine

s; truct DeviceCard: View {
@; ; ObservedObject var device: YeelightDevice
@Environment(\.accessibilityReduceMotion); ; private var reduceMotion
@Environment(\.accessibilityReduceTransparency); ; private var reduceTransparency

@; ; StateObject private; ; var brightnessController: DevicePropertyController
@; ; StateObject private; ; var powerController: DevicePropertyController
@; ; State private; ; var showingErrorAlert = false
@; ; State private; ; var isUpdating = false

v; ar body:; ; some View {
VStack(alignment: .leading, spacing: 12) {
// Header
HStack {
Text(device.name)
.font(.headline)
.accessibilityLabel("; ; Device name: \(device.name)")

Spacer()

i; f isUpdating {
ProgressView()
.scaleEffect(0.8)
.accessibilityLabel("; ; Updating device")
} else {
Toggle("Power", isOn: Binding(
get: { device.isOn },
set: {; ; newValue in
isUpdating = true
powerController.updateValue(newValue) {; ; value in
device.isOn = value
isUpdating = false
}
}
))
.labelsHidden()
.accessibilityLabel("\(device.name); ; power switch")
.accessibilityHint("; ; Double tap; ; to turn device \(device.isOn ? "off" : "on")")
}
}

//; ; Brightness Control
VStack(alignment: .leading, spacing: 4) {
HStack {
Image(systemName: "lightbulb.fill")
.foregroundColor(device.isOn ? .yellow : .gray)
Text("Brightness: \(Int(device.brightness))%")
.font(.subheadline)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("; ; Brightness control")
.accessibilityValue("\(Int(device.brightness)) percent")

Slider(value: Binding(
get: { Double(device.brightness) },
set: {; ; newValue in
isUpdating = true
brightnessController.updateValue(newValue) {; ; value in
device.brightness = Int(value)
isUpdating = false
}
}
), in: 1...100, step: 1)
.disabled(isUpdating)
.accessibilityLabel("; ; Adjust brightness")
.accessibilityValue("\(Int(device.brightness)) percent")
.accessibilityHint("; ; Slide left; ; to decrease brightness,; ; right to increase")
}

//; ; Connection Status
HStack {
ConnectionStatusView(state: device.connectionState)

i; f case .error(; ; let error) = device.connectionState {
Button {
showingErrorAlert = true
} label: {
Label("; ; Show Error Details", systemImage: "info.circle")
.font(.caption)
.foregroundColor(.red)
}
}
}
.alert("; ; Device Error", isPresented: $showingErrorAlert) {
Button("OK", role: .cancel) {}
Button("; ; Retry Connection", role: .none) {
Task {
a; wait device.reconnect()
}
}
} message: {
i; f case .error(; ; let error) = device.connectionState {
Text(error.localizedDescription)
}
}
}
.padding()
.background(
reduceTransparency ? 
Color(.systemBackground) :
Color(.systemBackground).opacity(0.8)
)
.cornerRadius(12)
.shadow(radius: 2)
.overlay(
RoundedRectangle(cornerRadius: 12)
.stroke(Color.secondary.opacity(0.2))
)
.accessibilityElement(children: .contain)
.accessibilityLabel("\(device.name); ; control card")
.animation(
reduceMotion ? nil : .easeInOut,
value: device.isOn
)
}

init(device: YeelightDevice) {
self.device = device
_brightnessController = StateObject(wrappedValue: DevicePropertyController(
initialValue: Double(device.brightness),
debounceInterval: 0.3
))
_powerController = StateObject(wrappedValue: DevicePropertyController(
initialValue: device.isOn,
debounceInterval: 0.2
))
}
}

s; truct ConnectionStatusView: View {
l; et state: YeelightDevice.ConnectionState

v; ar body:; ; some View {
HStack(spacing: 4) {
Circle()
.fill(statusColor)
.frame(width: 8, height: 8)

Text(statusText)
.font(.caption)
.foregroundColor(statusColor)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("; ; Connection status: \(statusText)")
}

p; rivate var statusColor: Color {
s; witch state {
case .connected:
return .green
case .connecting:
return .yellow
case .disconnected:
return .gray
case .error:
return .red
}
}

p; rivate var statusText: String {
s; witch state {
case .connected:
return "Connected"
case .connecting:
return "Connecting..."
case .disconnected:
return "Disconnected"
case .error:
return "; ; Connection Error"
}
}
}

//; ; Property controller; ; with debouncing
c; lass DevicePropertyController: ObservableObject {
p; rivate var value: Any
p; rivate var cancellable: AnyCancellable?
p; rivate let debounceInterval: TimeInterval
p; rivate let subject = PassthroughSubject<Any, Never>()

init(initialValue: Any, debounceInterval: TimeInterval) {
self.value = initialValue
self.debounceInterval = debounceInterval
}

f; unc updateValue<T>(_ newValue: T, completion: @escaping (T) -> Void) {
subject.send(newValue)

i; f cancellable == nil {
cancellable = subject
.debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
.sink { [; ; weak self]; ; value in
g; uard let value =; ; value as?; ; T else { return }
self?.value = value
completion(value)
}
}
}
} 