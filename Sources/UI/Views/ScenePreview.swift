import SwiftUI
import Core

struct ScenePreview: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var yeelightManager: UnifiedYeelightManager
    
    let scene: any Scene
    @State private var isPlaying = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var currentStep = 0
    @State private var previewTimer: Timer?
    @State private var devices: [YeelightDevice] = []
    
    var body: some View {
        UnifiedDetailView(
            title: scene.name,
            subtitle: "\(scene.devices.count) devices",
            headerContent: {
                VStack(spacing: 16) {
                    Image(systemName: "theatermasks.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text(scene.description ?? "No description")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    previewContent
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
                Button {
                    if isPlaying {
                        self.stopPreview()
                    } else {
                        self.startPreview()
                    }
                } label: {
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
        .onAppear {
            loadDevices()
        }
        .onDisappear {
            self.stopPreview()
        }
    }
    
    private func loadDevices() {
        // Load the devices for this scene
        devices = scene.devices.compactMap { deviceId in
            yeelightManager.getDevice(id: deviceId)
        }
    }
    
    var previewContent: some View {
        Group {
            switch scene.type {
            case .color:
                if let colorScene = scene as? ColorScene {
                    ColorPreview(color: Color(colorScene.color))
                }
            case .temperature:
                if let tempScene = scene as? TemperatureScene {
                    TemperaturePreview(temperature: tempScene.temperature)
                }
            case .flow:
                if let flowScene = scene as? FlowScene {
                    FlowPreview(params: flowScene.params, currentStep: currentStep)
                }
            case .multiLight:
                if let multiScene = scene as? MultiLightScene {
                    MultiLightPreview(scene: multiScene, devices: devices)
                }
            case .strip:
                if let stripScene = scene as? StripEffectScene {
                    StripEffectPreview(effect: stripScene.effect, devices: devices)
                }
            }
            
            HStack(spacing: 20) {
                ForEach(devices) { device in
                    Circle()
                        .fill(device.isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 8)
            
            Button {
                if isPlaying {
                    self.stopPreview()
                } else {
                    self.startPreview()
                }
            } label: {
                Text(isPlaying ? "Stop Preview" : "Start Preview")
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
    }
    
    func startPreview() {
        isPlaying = true

        // Apply scene to devices
        for device in devices {
            yeelightManager.applyScene(scene, to: device)
        }

        // For flow effects, start animation
        if scene.type == .flow {
            if let flowScene = scene as? FlowScene {
                previewTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    currentStep = (currentStep + 1) % flowScene.params.transitions.count
                }
            }
        }
    }

    func stopPreview() {
        isPlaying = false
        previewTimer?.invalidate()
        previewTimer = nil

        // Reset devices to their previous state
        for device in devices {
            yeelightManager.stopEffect(on: device)
        }
    }

    func resetPreview() {
        stopPreview()
        currentStep = 0
    }

    func saveScene() {
        // Save scene implementation
    }
}

struct DeviceStateRow: View {
    let device: DeviceID
    @EnvironmentObject private var yeelightManager: UnifiedYeelightManager
    
    var body: some View {
        HStack {
            if let yeelight = yeelightManager.getDevice(id: device) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(yeelight.isPoweredOn ? .yellow : .gray)
                
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
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                }
            } else {
                Image(systemName: "lightbulb.slash")
                    .foregroundColor(.gray)
                
                Text("Device not found")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 4)
    }
    
    func deviceStatus(_ device: YeelightDevice) -> String {
        if device.isConnected {
            return device.isPoweredOn ? "On" : "Off"
        } else {
            return "Disconnected"
        }
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
    let params: FlowParams
    let currentStep: Int
    
    var body: some View {
        VStack(spacing: 16) {
            if !params.transitions.isEmpty && currentStep < params.transitions.count {
                let transition = params.transitions[currentStep]
                
                TransitionPreview(transition: transition)
                
                Text("Step \(currentStep + 1) of \(params.transitions.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("No transitions defined")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TransitionPreview: View {
    let transition: FlowTransition
    
    var body: some View {
        VStack(spacing: 12) {
            switch transition.mode {
            case .color:
                ColorPreview(color: Color(transition.value))
            case .temperature:
                if let temp = Int(transition.value) {
                    TemperaturePreview(temperature: temp)
                }
            case .sleep:
                Image(systemName: "zzz")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
            
            Text("\(transition.duration)ms")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MultiLightPreview: View {
    let scene: MultiLightScene
    let devices: [YeelightDevice]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(scene.devices.count) devices")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                ForEach(devices) { device in
                    VStack {
                        Circle()
                            .fill(device.isPoweredOn ? .yellow : .gray)
                            .frame(width: 40, height: 40)
                        
                        Text(device.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct StripEffectPreview: View {
    let effect: StripEffect
    let devices: [YeelightDevice]
    
    var body: some View {
        VStack(spacing: 16) {
            Text(effect.name)
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(0..<10, id: \.self) { index in
                    Circle()
                        .fill(colorForIndex(index))
                        .frame(width: 20, height: 20)
                }
            }
            
            Text("\(devices.count) strip lights")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func colorForIndex(_ index: Int) -> Color {
        // Simplified preview of strip effect
        let hue = Double(index) / 10.0
        return Color(hue: hue, saturation: 1.0, brightness: 1.0)
    }
}

// MARK: - Preview

#Preview {
    ScenePreview(scene: PreviewData.sampleScene)
        .environmentObject(ServiceContainer.shared.yeelightManager)
}

// MARK: - Preview Data

private enum PreviewData {
    static let sampleScene = ColorScene(
        id: "preview-scene",
        name: "Sample Scene",
        description: "A sample scene for preview",
        devices: ["device1", "device2"],
        color: Core_Color(red: 255, green: 0, blue: 0)
    )
} 