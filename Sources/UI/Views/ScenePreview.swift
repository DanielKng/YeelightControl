import SwiftUI

struct ScenePreview: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var yeelightManager: YeelightManager
    
    let scene: Scene
    @State private var isPlaying = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        UnifiedDetailView(
            title: scene.name,
            subtitle: "\(scene.devices.count) devices",
            headerContent: {
                VStack(spacing: 16) {
                    Image(systemName: scene.icon)
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text(scene.description ?? "No description")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            },
            mainContent: {
                UnifiedListView(
                    title: "Device States",
                    items: scene.devices,
                    emptyStateMessage: "No devices in this scene"
                ) { device in
                    DeviceStateRow(device: device)
                }
            },
            onEdit: {
                // Handle edit action
            },
            onDelete: {
                // Handle delete action
            },
            onShare: {
                // Handle share action
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
    
    private func toggleScene() {
        do {
            if isPlaying {
                try yeelightManager.stopScene(scene)
            } else {
                try yeelightManager.playScene(scene)
            }
            isPlaying.toggle()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct DeviceStateRow: View {
    let device: DeviceID
    @EnvironmentObject private var yeelightManager: YeelightManager
    
    var body: some View {
        HStack {
            if let yeelight = yeelightManager.getDevice(id: device) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(yeelight.isOn ? .yellow : .gray)
                
                VStack(alignment: .leading) {
                    Text(yeelight.name)
                        .font(.headline)
                    
                    Text(deviceStatus(yeelight))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if yeelight.isConnected {
                    Circle()
                        .fill(yeelight.isOn ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                } else {
                    Text("Offline")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                Image(systemName: "lightbulb.slash")
                    .foregroundColor(.gray)
                
                Text("Unknown device")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Not found")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func deviceStatus(_ device: YeelightDevice) -> String {
        if !device.isConnected {
            return "Disconnected"
        }
        
        if !device.isOn {
            return "Off"
        }
        
        var status = "On"
        
        if let brightness = device.brightness {
            status += ", Brightness: \(brightness)%"
        }
        
        if let colorTemp = device.colorTemperature {
            status += ", Temp: \(colorTemp)K"
        }
        
        return status
    }
}

#Preview {
NavigationView {
ScenePreview(scene: Scene.preview)
VStack(spacing: 20) {
// Preview visualization
ZStack {
// Background
RoundedRectangle(cornerRadius: 16)
.fill(Color(.systemGroupedBackground))
.shadow(radius: 5)

VStack(spacing: 16) {
// Scene visualization
switch scene {
case .color(let red, let green, let blue, _):
ColorPreview(color: Color(red: Double(red)/255, green: Double(green)/255, blue: Double(blue)/255))
case .colorTemperature(let temp, _):
TemperaturePreview(temperature: temp)
case .colorFlow(let params):
FlowPreview(params: params, currentStep: currentStep)
case .multiLight(let scene):
MultiLightPreview(scene: scene, devices: devices)
case .stripEffect(let effect):
StripEffectPreview(effect: effect, devices: devices)
}
}
.padding()
}
.frame(height: 200)

// Device list
ScrollView(.horizontal, showsIndicators: false) {
HStack(spacing: 12) {
ForEach(devices) { device in
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
Text("Save Scene")
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

private func togglePreview() {
    if isPlaying {
        stopPreview()
    } else {
        startPreview()
    }
}

private func startPreview() {
    isPlaying = true

    // Apply scene to devices
    for device in devices {
        deviceManager.setScene(device, scene: scene)
    }

    // For flow effects, start animation
    if case .colorFlow(let params) = scene {
        previewTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentStep = (currentStep + 1) % params.transitions.count
        }
    }
}

private func stopPreview() {
    isPlaying = false
    previewTimer?.invalidate()
    previewTimer = nil

    // Reset devices to their previous state
    for device in devices {
        deviceManager.stopColorFlow(device)
    }
}

private func resetPreview() {
    stopPreview()
    currentStep = 0
}

private func saveScene() {
    // Save scene implementation
}
}

struct ColorPreview: View {
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 100, height: 100)
            .overlay {
                Circle()
                    .stroke(.white, lineWidth: 2)
            }
    }
}

struct TemperaturePreview: View {
    let temperature: Int
    
    var body: some View {
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
    
    private var temperatureDescription: String {
        switch temperature {
        case 1700...2700:
            return "Warm White"
        case 2701...4000:
            return "Neutral White"
        case 4001...5500:
            return "Cool White"
        default:
            return "Daylight"
        }
    }
}

struct FlowPreview: View {
    let params: YeelightDevice.FlowParams
    let currentStep: Int
    
    var body: some View {
        VStack {
            // Current transition visualization
            if !params.transitions.isEmpty {
                let transition = params.transitions[currentStep]
                TransitionPreview(transition: transition)
            }
            
            // Flow progress
            if params.transitions.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<params.transitions.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? .orange : .gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }
}

struct TransitionPreview: View {
    let transition: YeelightDevice.FlowParams.FlowTransition
    
    var body: some View {
        VStack(spacing: 8) {
            switch transition.mode {
            case 1: // Color
                let rgb = YeelightDevice.RGB.from(rgb: transition.value)
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

struct MultiLightPreview: View {
    let scene: YeelightManager.Scene.MultiLightScene
    let devices: [YeelightDevice]
    
    var body: some View {
        VStack {
            Text(scene.rawValue)
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(devices) { device in
                    Circle()
                        .fill(.orange)
                        .frame(width: 20, height: 20)
                }
            }
        }
    }
}

struct StripEffectPreview: View {
    let effect: YeelightManager.StripEffect
    let devices: [YeelightDevice]
    
    var body: some View {
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

struct DevicePreviewCard: View {
    let device: YeelightDevice
    
    var body: some View {
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