import SwiftUI

struct SceneEditorView: View {
    @ObservedObject var manager: YeelightManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var sceneName = ""
    @State private var selectedDevices: Set<String> = []
    @State private var sceneType: SceneType = .color
    @State private var brightness: Double = 100
    @State private var selectedColor = Color.white
    @State private var colorTemp: Double = 4000
    @State private var transitionDuration: Double = 500
    @State private var flowParams = YeelightDevice.FlowParams()
    
    enum SceneType {
        case color, temperature, flow, multiDevice
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Scene Details") {
                    TextField("Scene Name", text: $sceneName)
                    
                    Picker("Type", selection: $sceneType) {
                        Text("Color").tag(SceneType.color)
                        Text("Temperature").tag(SceneType.temperature)
                        Text("Flow Effect").tag(SceneType.flow)
                        if manager.devices.count > 1 {
                            Text("Multi-Device").tag(SceneType.multiDevice)
                        }
                    }
                }
                
                Section("Devices") {
                    ForEach(manager.devices) { device in
                        HStack {
                            Text(device.name)
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { selectedDevices.contains(device.ip) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedDevices.insert(device.ip)
                                    } else {
                                        selectedDevices.remove(device.ip)
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                    }
                }
                
                Section("Settings") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Brightness")
                            Spacer()
                            Text("\(Int(brightness))%")
                        }
                        Slider(value: $brightness, in: 1...100)
                    }
                    
                    switch sceneType {
                    case .color:
                        ColorPicker("Color", selection: $selectedColor)
                    case .temperature:
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Temperature")
                                Spacer()
                                Text("\(Int(colorTemp))K")
                            }
                            Slider(value: $colorTemp, in: 1700...6500)
                        }
                    case .flow:
                        NavigationLink("Configure Flow Effect") {
                            FlowEffectEditor(params: $flowParams)
                        }
                    case .multiDevice:
                        NavigationLink("Configure Multi-Device Effect") {
                            MultiDeviceEffectEditor(devices: selectedDevices.compactMap { ip in
                                manager.devices.first { $0.ip == ip }
                            })
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Transition")
                            Spacer()
                            Text("\(Int(transitionDuration))ms")
                        }
                        Slider(value: $transitionDuration, in: 30...5000)
                    }
                }
                
                Section {
                    Button("Preview") {
                        previewScene()
                    }
                    .disabled(selectedDevices.isEmpty)
                }
            }
            .navigationTitle("Create Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveScene() }
                        .disabled(sceneName.isEmpty || selectedDevices.isEmpty)
                }
            }
        }
    }
    
    private func previewScene() {
        let scene = createScene()
        for deviceIP in selectedDevices {
            if let device = manager.devices.first(where: { $0.ip == deviceIP }) {
                manager.setScene(device, scene: scene)
            }
        }
    }
    
    private func saveScene() {
        let scene = createScene()
        // Save to custom scenes
        DeviceStorage.shared.saveCustomScene(
            name: sceneName,
            scene: scene,
            devices: Array(selectedDevices)
        )
        dismiss()
    }
    
    private func createScene() -> YeelightManager.Scene {
        switch sceneType {
        case .color:
            let components = UIColor(selectedColor).cgColor.components ?? [1, 1, 1, 1]
            return .color(
                red: Int(components[0] * 255),
                green: Int(components[1] * 255),
                blue: Int(components[2] * 255),
                brightness: Int(brightness)
            )
            
        case .temperature:
            return .colorTemperature(
                temperature: Int(colorTemp),
                brightness: Int(brightness)
            )
            
        case .flow:
            return .colorFlow(params: flowParams)
            
        case .multiDevice:
            // Create a coordinated multi-device scene
            return .multiLight(.custom(flowParams))
        }
    }
}

struct FlowEffectEditor: View {
    @Binding var params: YeelightDevice.FlowParams
    @State private var showingTransitionEditor = false
    
    var body: some View {
        List {
            Section {
                Picker("Repeat", selection: Binding(
                    get: { params.count == 0 },
                    set: { params.count = $0 ? 0 : 1 }
                )) {
                    Text("Once").tag(false)
                    Text("Infinite").tag(true)
                }
                
                Picker("End Action", selection: $params.action) {
                    Text("Restore").tag(YeelightDevice.FlowParams.FlowAction.recover)
                    Text("Keep").tag(YeelightDevice.FlowParams.FlowAction.stay)
                    Text("Turn Off").tag(YeelightDevice.FlowParams.FlowAction.turnOff)
                }
            }
            
            Section("Transitions") {
                ForEach(params.transitions.indices, id: \.self) { index in
                    TransitionRow(transition: $params.transitions[index])
                }
                .onDelete { params.transitions.remove(atOffsets: $0) }
                
                Button("Add Transition") {
                    showingTransitionEditor = true
                }
            }
        }
        .navigationTitle("Flow Effect")
        .sheet(isPresented: $showingTransitionEditor) {
            TransitionEditor { transition in
                params.transitions.append(transition)
            }
        }
    }
} 