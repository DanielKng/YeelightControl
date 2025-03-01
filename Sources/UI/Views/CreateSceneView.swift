import SwiftUI
import Core

struct CreateSceneView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sceneManager: SceneManager
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
    
    @State private var sceneName = ""
    @State private var selectedDevices: Set<DeviceID> = []
    @State private var deviceSettings: [DeviceID: DeviceSettings] = [:]
    @State private var showingDeviceSelector = false
    @State private var currentEditingDevice: DeviceID?
    @State private var selectedPreset: ScenePreset?
    
    private var availableDevices: [YeelightDevice] {
        yeelightManager.devices
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Scene Details")) {
                    TextField("Scene Name", text: $sceneName)
                }
                
                Section(header: Text("Devices")) {
                    Button(action: {
                        showingDeviceSelector = true
                    }) {
                        Label("Add Devices", systemImage: "plus")
                    }
                    
                    if selectedDevices.isEmpty {
                        Text("No devices selected")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(Array(selectedDevices), id: \.self) { deviceID in
                            if let device = availableDevices.first(where: { $0.id == deviceID }) {
                                DeviceSettingRow(
                                    device: device,
                                    settings: deviceSettings[deviceID] ?? DeviceSettings.default,
                                    onTap: {
                                        currentEditingDevice = deviceID
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveScene()
                    }
                    .disabled(sceneName.isEmpty || selectedDevices.isEmpty)
                }
            }
            .sheet(isPresented: $showingDeviceSelector) {
                DeviceSelectorView(
                    availableDevices: availableDevices,
                    selectedDevices: $selectedDevices
                )
            }
            .sheet(item: $currentEditingDevice) { deviceID in
                if let device = availableDevices.first(where: { $0.id == deviceID }) {
                    DeviceSettingsEditor(
                        device: device,
                        settings: deviceSettings[deviceID] ?? DeviceSettings.default,
                        onSave: { newSettings in
                            deviceSettings[deviceID] = newSettings
                            currentEditingDevice = nil
                        },
                        onCancel: {
                            currentEditingDevice = nil
                        }
                    )
                }
            }
        }
    }
    
    private func saveScene() {
        let deviceConfigs = selectedDevices.compactMap { deviceID -> DeviceConfig? in
            guard let device = availableDevices.first(where: { $0.id == deviceID }),
                  let settings = deviceSettings[deviceID] else {
                return nil
            }
            
            return DeviceConfig(
                deviceID: deviceID,
                name: device.name,
                settings: settings
            )
        }
        
        let newScene = Scene(
            id: UUID().uuidString,
            name: sceneName,
            devices: deviceConfigs,
            createdAt: Date()
        )
        
        sceneManager.addScene(newScene)
        dismiss()
    }
}

struct DeviceSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    let availableDevices: [YeelightDevice]
    @Binding var selectedDevices: Set<DeviceID>
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(availableDevices) { device in
                    Button(action: {
                        toggleDevice(device.id)
                    }) {
                        HStack {
                            Text(device.name)
                            Spacer()
                            if selectedDevices.contains(device.id) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleDevice(_ deviceID: DeviceID) {
        if selectedDevices.contains(deviceID) {
            selectedDevices.remove(deviceID)
        } else {
            selectedDevices.insert(deviceID)
        }
    }
}

struct DeviceSettingRow: View {
    let device: YeelightDevice
    let settings: DeviceSettings
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(device.name)
                        .font(.headline)
                    
                    Text(settingsSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let color = settings.color {
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                } else if let temp = settings.colorTemperature {
                    // Show color temperature indicator
                    Circle()
                        .fill(colorForTemperature(temp))
                        .frame(width: 24, height: 24)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var settingsSummary: String {
        var summary = [String]()
        
        if settings.isOn {
            summary.append("On")
        } else {
            summary.append("Off")
        }
        
        summary.append("Brightness: \(Int(settings.brightness))%")
        
        if settings.mode == .temperature, let temp = settings.colorTemperature {
            summary.append("\(Int(temp))K")
        }
        
        return summary.joined(separator: " • ")
    }
    
    private func colorForTemperature(_ temp: Double) -> Color {
        // Simple mapping from color temperature to RGB
        // This is a simplified version, not physically accurate
        let normalizedTemp = (temp - 1700) / (6500 - 1700)
        return Color(
            red: 1.0,
            green: normalizedTemp * 0.8 + 0.2,
            blue: normalizedTemp
        )
    }
}

struct DeviceSettingsEditor: View {
    @Environment(\.dismiss) private var dismiss
    let device: YeelightDevice
    @State private var settings: DeviceSettings
    let onSave: (DeviceSettings) -> Void
    let onCancel: () -> Void
    
    init(device: YeelightDevice, settings: DeviceSettings, onSave: @escaping (DeviceSettings) -> Void, onCancel: @escaping () -> Void) {
        self.device = device
        self._settings = State(initialValue: settings)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Power")) {
                    Toggle("Power", isOn: $settings.isOn)
                }
                
                Section(header: Text("Brightness")) {
                    VStack {
                        Slider(value: $settings.brightness, in: 0...100, step: 1)
                        Text("\(Int(settings.brightness))%")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                
                Section(header: Text("Mode")) {
                    Picker("Light Mode", selection: $settings.mode) {
                        Text("Color").tag(DeviceSettings.DeviceMode.color)
                        Text("Temperature").tag(DeviceSettings.DeviceMode.temperature)
                    }
                    .pickerStyle(.segmented)
                }
                
                if settings.mode == .color {
                    Section(header: Text("Color")) {
                        ColorPicker("Light Color", selection: Binding(
                            get: { settings.color ?? .white },
                            set: { settings.color = $0 }
                        ))
                    }
                } else if settings.mode == .temperature && device.supportsColorTemperature {
                    Section(header: Text("Color Temperature")) {
                        VStack {
                            Slider(
                                value: Binding(
                                    get: { settings.colorTemperature ?? 4000 },
                                    set: { settings.colorTemperature = $0 }
                                ),
                                in: 1700...6500,
                                step: 100
                            )
                            HStack {
                                Text("Warm")
                                Spacer()
                                Text("\(Int(settings.colorTemperature ?? 4000))K")
                                Spacer()
                                Text("Cool")
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Edit Device Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(settings)
                    }
                }
            }
        }
    }
}

#Preview {
    CreateSceneView()
        .environmentObject(SceneManager.shared)
        .environmentObject(ObservableYeelightManager(manager: ServiceContainer.shared.yeelightManager))
} 