import SwiftUI

struct CreateSceneView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var sceneManager: SceneManager
    
    @State private var sceneName = ""
    @State private var selectedDevices: Set<DeviceID> = []
    @State private var deviceSettings: [DeviceID: DeviceSettings] = [:]
    @State private var showingDeviceSelector = false
    @State private var currentEditingDevice: DeviceID?
    
    private var availableDevices: [YeelightDevice] {
        DeviceManager.shared.devices
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
                
                Circle()
                    .fill(settings.color)
                    .frame(width: 24, height: 24)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var settingsSummary: String {
        var summary = [String]()
        
        if settings.power {
            summary.append("On")
        } else {
            summary.append("Off")
        }
        
        summary.append("Brightness: \(Int(settings.brightness * 100))%")
        
        return summary.joined(separator: " • ")
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
                    Toggle("Power", isOn: $settings.power)
                }
                
                Section(header: Text("Brightness")) {
                    VStack {
                        Slider(value: $settings.brightness, in: 0...1, step: 0.01)
                        Text("\(Int(settings.brightness * 100))%")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                
                Section(header: Text("Color")) {
                    ColorPicker("Light Color", selection: $settings.color)
                }
                
                if device.supportsColorTemperature {
                    Section(header: Text("Color Temperature")) {
                        VStack {
                            Slider(
                                value: $settings.colorTemperature,
                                in: Double(device.colorTempRange.lowerBound)...Double(device.colorTempRange.upperBound),
                                step: 100
                            )
                            HStack {
                                Text("Warm")
                                Spacer()
                                Text("\(Int(settings.colorTemperature))K")
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
.environmentObject(YeelightManager.shared)
} 