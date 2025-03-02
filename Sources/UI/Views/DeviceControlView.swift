import SwiftUI
import Core

struct DeviceControlView: View {
    // MARK: - Properties
    
    @ObservedObject var device: YeelightDevice
    @EnvironmentObject var yeelightManager: ObservableYeelightManager
    
    @State private var brightness: Double
    @State private var colorTemperature: Double
    @State private var selectedColor: Color
    @State private var isPowerOn: Bool
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var selectedTab: ControlTab = .brightness
    
    enum ControlTab {
        case brightness
        case colorTemperature
        case color
    }
    
    // MARK: - Initialization
    
    init(device: YeelightDevice) {
        self.device = device
        
        // Initialize state from device
        _brightness = State(initialValue: Double(device.state.brightness))
        _colorTemperature = State(initialValue: Double(device.state.colorTemperature))
        _selectedColor = State(initialValue: device.state.color.uiColor)
        _isPowerOn = State(initialValue: device.state.power)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Power button
            Button(action: togglePower) {
                HStack {
                    Image(systemName: isPowerOn ? "power.circle.fill" : "power.circle")
                        .foregroundColor(isPowerOn ? .green : .red)
                        .font(.system(size: 24))
                    
                    Text(isPowerOn ? "Turn Off" : "Turn On")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
            .disabled(isUpdating)
            
            // Control tabs
            Picker("Control", selection: $selectedTab) {
                Text("Brightness").tag(ControlTab.brightness)
                Text("Temperature").tag(ControlTab.colorTemperature)
                Text("Color").tag(ControlTab.color)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .disabled(!isPowerOn || isUpdating)
            
            // Control content
            ScrollView {
                VStack(spacing: 20) {
                    if isPowerOn {
                        switch selectedTab {
                        case .brightness:
                            brightnessControl
                        case .colorTemperature:
                            colorTemperatureControl
                        case .color:
                            colorControl
                        }
                        
                        // Preset buttons
                        presetButtons
                    } else {
                        Text("Turn on the device to access controls")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
        }
        .padding()
        .overlay(
            ZStack {
                if isUpdating {
                    Color.black.opacity(0.3)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        )
        .alert(item: Binding<AlertItem?>(
            get: { errorMessage.map { AlertItem(message: $0) } },
            set: { errorMessage = $0?.message }
        )) { alert in
            Alert(
                title: Text("Error"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Control Views
    
    private var brightnessControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Brightness: \(Int(brightness))%")
                .font(.headline)
            
            Slider(value: $brightness, in: 1...100, step: 1)
                .onChange(of: brightness) { newValue in
                    debounceUpdate {
                        var newState = device.state
                        newState.brightness = Int(newValue)
                        try await updateDeviceState(newState)
                    }
                }
            
            HStack {
                Button(action: { setBrightness(10) }) {
                    Text("10%")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                
                Button(action: { setBrightness(50) }) {
                    Text("50%")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                
                Button(action: { setBrightness(100) }) {
                    Text("100%")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
            }
        }
    }
    
    private var colorTemperatureControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color Temperature: \(Int(colorTemperature))K")
                .font(.headline)
            
            Slider(value: $colorTemperature, in: 1700...6500, step: 100)
                .onChange(of: colorTemperature) { newValue in
                    debounceUpdate {
                        var newState = device.state
                        newState.colorTemperature = Int(newValue)
                        try await updateDeviceState(newState)
                    }
                }
            
            HStack {
                Button(action: { setColorTemperature(2700) }) {
                    Text("Warm")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                
                Button(action: { setColorTemperature(4000) }) {
                    Text("Neutral")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(5)
                }
                
                Button(action: { setColorTemperature(6500) }) {
                    Text("Cool")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
            }
        }
    }
    
    private var colorControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(.headline)
            
            ColorPicker("Select Color", selection: $selectedColor)
                .onChange(of: selectedColor) { newValue in
                    debounceUpdate {
                        var newState = device.state
                        newState.color = DeviceColor.from(uiColor: newValue)
                        try await updateDeviceState(newState)
                    }
                }
            
            HStack {
                ForEach([Color.red, Color.green, Color.blue, Color.yellow, Color.purple, Color.orange], id: \.self) { color in
                    Button(action: { setColor(color) }) {
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }
            }
        }
    }
    
    private var presetButtons: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presets")
                .font(.headline)
            
            HStack {
                Button(action: { setPreset(.night) }) {
                    VStack {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 24))
                        Text("Night")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
                }
                
                Button(action: { setPreset(.reading) }) {
                    VStack {
                        Image(systemName: "book.fill")
                            .font(.system(size: 24))
                        Text("Reading")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(10)
                }
                
                Button(action: { setPreset(.movie) }) {
                    VStack {
                        Image(systemName: "tv.fill")
                            .font(.system(size: 24))
                        Text("Movie")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(10)
                }
                
                Button(action: { setPreset(.party) }) {
                    VStack {
                        Image(systemName: "music.note")
                            .font(.system(size: 24))
                        Text("Party")
                            .font(.caption)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.pink.opacity(0.2))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func togglePower() {
        Task {
            isUpdating = true
            defer { isUpdating = false }
            
            do {
                var newState = device.state
                newState.power = !isPowerOn
                try await updateDeviceState(newState)
                isPowerOn = !isPowerOn
            } catch {
                errorMessage = "Failed to toggle power: \(error.localizedDescription)"
            }
        }
    }
    
    private func setBrightness(_ value: Double) {
        brightness = value
        
        Task {
            isUpdating = true
            defer { isUpdating = false }
            
            do {
                var newState = device.state
                newState.brightness = Int(value)
                try await updateDeviceState(newState)
            } catch {
                errorMessage = "Failed to set brightness: \(error.localizedDescription)"
            }
        }
    }
    
    private func setColorTemperature(_ value: Double) {
        colorTemperature = value
        
        Task {
            isUpdating = true
            defer { isUpdating = false }
            
            do {
                var newState = device.state
                newState.colorTemperature = Int(value)
                try await updateDeviceState(newState)
            } catch {
                errorMessage = "Failed to set color temperature: \(error.localizedDescription)"
            }
        }
    }
    
    private func setColor(_ color: Color) {
        selectedColor = color
        
        Task {
            isUpdating = true
            defer { isUpdating = false }
            
            do {
                var newState = device.state
                newState.color = DeviceColor.from(uiColor: color)
                try await updateDeviceState(newState)
            } catch {
                errorMessage = "Failed to set color: \(error.localizedDescription)"
            }
        }
    }
    
    private func setPreset(_ preset: SceneType) {
        Task {
            isUpdating = true
            defer { isUpdating = false }
            
            do {
                // Create a scene with the preset type
                let scene = Scene(
                    id: UUID().uuidString,
                    name: preset.displayName,
                    description: "Preset \(preset.displayName) mode",
                    type: preset,
                    isBuiltIn: true,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                // Apply the scene to the device
                yeelightManager.applyScene(scene, to: device)
                
                // Update local state based on preset
                switch preset {
                case .night:
                    brightness = 1
                    colorTemperature = 2700
                case .reading:
                    brightness = 50
                    colorTemperature = 4000
                case .movie:
                    brightness = 20
                    selectedColor = Color.blue
                case .party:
                    brightness = 100
                    selectedColor = Color.purple
                case .custom:
                    break
                }
            } catch {
                errorMessage = "Failed to apply preset: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateDeviceState(_ newState: DeviceState) async throws {
        // Send the command to update the device state
        let command = createCommandForState(newState)
        try await yeelightManager.send(command, to: device)
        
        // Update the device state locally
        var updatedDevice = device
        updatedDevice.state = newState
        try await yeelightManager.updateDevice(updatedDevice)
    }
    
    private func createCommandForState(_ state: DeviceState) -> YeelightCommand {
        // Create a command based on what changed
        let id = Int.random(in: 1...1000)
        
        if state.power != device.state.power {
            return YeelightCommand(
                id: id,
                method: "set_power",
                params: [state.power ? "on" : "off", "smooth", 500]
            )
        } else if state.brightness != device.state.brightness {
            return YeelightCommand(
                id: id,
                method: "set_bright",
                params: [state.brightness, "smooth", 500]
            )
        } else if state.colorTemperature != device.state.colorTemperature {
            return YeelightCommand(
                id: id,
                method: "set_ct_abx",
                params: [state.colorTemperature, "smooth", 500]
            )
        } else {
            // Color change
            let red = state.color.red
            let green = state.color.green
            let blue = state.color.blue
            let rgb = (red << 16) + (green << 8) + blue
            
            return YeelightCommand(
                id: id,
                method: "set_rgb",
                params: [rgb, "smooth", 500]
            )
        }
    }
    
    private func debounceUpdate(action: @escaping () async throws -> Void) {
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            isUpdating = true
            defer { isUpdating = false }
            
            do {
                try await action()
            } catch {
                errorMessage = "Failed to update device: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview

struct DeviceControlView_Previews: PreviewProvider {
    static var previews: some View {
        let device = YeelightDevice(
            id: "preview-device",
            name: "Living Room Light",
            model: .colorLEDBulb,
            firmwareVersion: "1.0.0",
            ipAddress: "192.168.1.100",
            port: 55443,
            state: DeviceState(
                power: true,
                brightness: 50,
                colorTemperature: 4000,
                color: DeviceColor.white
            ),
            isOnline: true
        )
        
        return DeviceControlView(device: device)
            .environmentObject(ObservableYeelightManager(
                manager: UnifiedYeelightManager(
                    storageManager: UnifiedStorageManager(),
                    networkManager: UnifiedNetworkManager()
                )
            ))
    }
}

// MARK: - Helper Types

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
} 