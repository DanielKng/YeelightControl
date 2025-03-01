import SwiftUI
import Core

struct ContentView: View {
    // MARK: - Environment
    
    @EnvironmentObject private var deviceManager: DeviceManagerObject
    @EnvironmentObject private var effectManager: EffectManagerObject
    @EnvironmentObject private var sceneManager: SceneManagerObject
    @EnvironmentObject private var configurationManager: ConfigurationManagerObject
    
    // MARK: - State
    
    @State private var selectedTab = 0
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Devices Tab
            NavigationView {
                DevicesView()
                    .navigationTitle("Devices")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                Task {
                                    await deviceManager.startDiscovery()
                                }
                            }) {
                                Label("Discover", systemImage: "magnifyingglass")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Devices", systemImage: "lightbulb")
            }
            .tag(0)
            
            // Effects Tab
            NavigationView {
                EffectsView()
                    .navigationTitle("Effects")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                // Add new effect
                            }) {
                                Label("Add", systemImage: "plus")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Effects", systemImage: "wand.and.stars")
            }
            .tag(1)
            
            // Scenes Tab
            NavigationView {
                ScenesView()
                    .navigationTitle("Scenes")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                // Add new scene
                            }) {
                                Label("Add", systemImage: "plus")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Scenes", systemImage: "theatermasks")
            }
            .tag(2)
            
            // Settings Tab
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
    }
}

// MARK: - Devices View

struct DevicesView: View {
    @EnvironmentObject private var deviceManager: DeviceManagerObject
    
    var body: some View {
        List {
            Section {
                if deviceManager.isDiscovering {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Discovering devices...")
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section {
                if deviceManager.devices.isEmpty {
                    Text("No devices found")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(deviceManager.devices) { device in
                        DeviceRow(device: device)
                    }
                }
            } header: {
                Text("Available Devices")
            }
        }
    }
}

struct DeviceRow: View {
    let device: Device
    @EnvironmentObject private var deviceManager: DeviceManagerObject
    @State private var isPowered: Bool
    
    init(device: Device) {
        self.device = device
        self._isPowered = State(initialValue: device.state.power)
    }
    
    var body: some View {
        NavigationLink {
            DeviceDetailView(device: device)
        } label: {
            HStack {
                Image(systemName: device.type.iconName)
                    .foregroundColor(isPowered ? device.state.color : .gray)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text(device.name)
                        .font(.headline)
                    Text(device.ipAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isPowered)
                    .labelsHidden()
                    .onChange(of: isPowered) { newValue in
                        var newState = device.state
                        newState.power = newValue
                        
                        Task {
                            await deviceManager.updateDeviceState(device, newState: newState)
                        }
                    }
            }
        }
    }
}

struct DeviceDetailView: View {
    let device: Device
    @EnvironmentObject private var deviceManager: DeviceManagerObject
    @State private var deviceState: DeviceState
    @State private var selectedColor: Color
    @State private var brightness: Double
    @State private var temperature: Double
    
    init(device: Device) {
        self.device = device
        self._deviceState = State(initialValue: device.state)
        self._selectedColor = State(initialValue: device.state.color)
        self._brightness = State(initialValue: Double(device.state.brightness))
        self._temperature = State(initialValue: Double(device.state.colorTemperature))
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Power", isOn: $deviceState.power)
                    .onChange(of: deviceState.power) { _ in
                        updateDeviceState()
                    }
            }
            
            Section {
                ColorPicker("Color", selection: $selectedColor)
                    .onChange(of: selectedColor) { _ in
                        deviceState.color = selectedColor
                        updateDeviceState()
                    }
            } header: {
                Text("Color")
            }
            
            Section {
                VStack {
                    HStack {
                        Text("Brightness: \(Int(brightness))%")
                        Spacer()
                    }
                    Slider(value: $brightness, in: 1...100, step: 1)
                        .onChange(of: brightness) { _ in
                            deviceState.brightness = Int(brightness)
                            updateDeviceState()
                        }
                }
            } header: {
                Text("Brightness")
            }
            
            Section {
                VStack {
                    HStack {
                        Text("Color Temperature: \(Int(temperature))K")
                        Spacer()
                    }
                    Slider(value: $temperature, in: 1700...6500, step: 100)
                        .onChange(of: temperature) { _ in
                            deviceState.colorTemperature = Int(temperature)
                            updateDeviceState()
                        }
                }
            } header: {
                Text("Color Temperature")
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text("Device Information")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    InfoRow(label: "Model", value: device.model)
                    InfoRow(label: "IP Address", value: device.ipAddress)
                    InfoRow(label: "Port", value: "\(device.port)")
                    InfoRow(label: "Firmware", value: device.firmwareVersion)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Information")
            }
        }
        .navigationTitle(device.name)
    }
    
    private func updateDeviceState() {
        Task {
            await deviceManager.updateDeviceState(device, newState: deviceState)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Effects View

struct EffectsView: View {
    @EnvironmentObject private var effectManager: EffectManagerObject
    
    var body: some View {
        List {
            if effectManager.effects.isEmpty {
                Text("No effects created yet")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(effectManager.effects) { effect in
                    NavigationLink {
                        EffectDetailView(effect: effect)
                    } label: {
                        HStack {
                            Image(systemName: effect.type.iconName)
                                .foregroundColor(.accentColor)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading) {
                                Text(effect.name)
                                    .font(.headline)
                                Text(effect.type.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct EffectDetailView: View {
    let effect: Effect
    @EnvironmentObject private var effectManager: EffectManagerObject
    @EnvironmentObject private var deviceManager: DeviceManagerObject
    @State private var isActive = false
    
    var body: some View {
        Form {
            Section {
                Button(action: {
                    isActive.toggle()
                    Task {
                        if isActive {
                            await effectManager.startEffect(effect)
                        } else {
                            await effectManager.stopEffect(effect)
                        }
                    }
                }) {
                    HStack {
                        Text(isActive ? "Stop Effect" : "Start Effect")
                        Spacer()
                        Image(systemName: isActive ? "stop.fill" : "play.fill")
                    }
                }
                .foregroundColor(isActive ? .red : .green)
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text("Effect Type: \(effect.type.displayName)")
                    Text("Duration: \(effect.parameters.duration) seconds")
                    
                    if !effect.parameters.colors.isEmpty {
                        HStack {
                            Text("Colors:")
                            Spacer()
                            ForEach(effect.parameters.colors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                    
                    Text("Brightness: \(effect.parameters.brightness)%")
                    Text("Temperature: \(effect.parameters.temperature)K")
                    Text("Speed: \(effect.parameters.speed)")
                    Text("Repeat: \(effect.parameters.repeat ? "Yes" : "No")")
                }
                .padding(.vertical, 8)
            } header: {
                Text("Parameters")
            }
            
            Section {
                if deviceManager.devices.isEmpty {
                    Text("No devices available")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(deviceManager.devices) { device in
                        Button(action: {
                            Task {
                                await effectManager.applyEffect(effect, to: [device.id])
                            }
                        }) {
                            HStack {
                                Image(systemName: device.type.iconName)
                                    .foregroundColor(device.state.power ? device.state.color : .gray)
                                Text(device.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Apply to Device")
            }
        }
        .navigationTitle(effect.name)
    }
}

// MARK: - Scenes View

struct ScenesView: View {
    @EnvironmentObject private var sceneManager: SceneManagerObject
    
    var body: some View {
        List {
            if sceneManager.scenes.isEmpty {
                Text("No scenes created yet")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(sceneManager.scenes) { scene in
                    NavigationLink {
                        SceneDetailView(scene: scene)
                    } label: {
                        HStack {
                            Image(systemName: scene.isActive ? "theatermasks.fill" : "theatermasks")
                                .foregroundColor(.accentColor)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading) {
                                Text(scene.name)
                                    .font(.headline)
                                Text("\(scene.deviceIds.count) devices")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if scene.isActive {
                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.2))
                                    )
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SceneDetailView: View {
    let scene: Scene
    @EnvironmentObject private var sceneManager: SceneManagerObject
    @EnvironmentObject private var deviceManager: DeviceManagerObject
    @EnvironmentObject private var effectManager: EffectManagerObject
    
    var body: some View {
        Form {
            Section {
                Button(action: {
                    Task {
                        if scene.isActive {
                            await sceneManager.deactivateScene(scene)
                        } else {
                            await sceneManager.activateScene(scene)
                        }
                    }
                }) {
                    HStack {
                        Text(scene.isActive ? "Deactivate Scene" : "Activate Scene")
                        Spacer()
                        Image(systemName: scene.isActive ? "stop.fill" : "play.fill")
                    }
                }
                .foregroundColor(scene.isActive ? .red : .green)
            }
            
            Section {
                ForEach(scene.deviceIds, id: \.self) { deviceId in
                    if let device = deviceManager.devices.first(where: { $0.id == deviceId }) {
                        HStack {
                            Image(systemName: device.type.iconName)
                                .foregroundColor(device.state.power ? device.state.color : .gray)
                                .font(.title3)
                                .frame(width: 30, height: 30)
                            
                            Text(device.name)
                        }
                    } else {
                        Text("Unknown device")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Devices")
            }
            
            if let effectId = scene.effectId, let effect = effectManager.effects.first(where: { $0.id == effectId }) {
                Section {
                    HStack {
                        Image(systemName: effect.type.iconName)
                            .foregroundColor(.accentColor)
                            .font(.title3)
                            .frame(width: 30, height: 30)
                        
                        VStack(alignment: .leading) {
                            Text(effect.name)
                                .font(.headline)
                            Text(effect.type.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Effect")
                }
            }
            
            if let schedule = scene.schedule {
                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Type:")
                            Spacer()
                            Text(schedule.type.rawValue)
                        }
                        
                        HStack {
                            Text("Time:")
                            Spacer()
                            Text(schedule.time)
                        }
                        
                        if !schedule.days.isEmpty {
                            HStack {
                                Text("Days:")
                                Spacer()
                                Text(schedule.days.map { $0.rawValue }.joined(separator: ", "))
                            }
                        }
                        
                        HStack {
                            Text("Enabled:")
                            Spacer()
                            Text(schedule.isEnabled ? "Yes" : "No")
                        }
                    }
                } header: {
                    Text("Schedule")
                }
            }
        }
        .navigationTitle(scene.name)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject private var configurationManager: ConfigurationManagerObject
    
    var body: some View {
        Form {
            Section {
                Toggle("Dark Mode", isOn: $configurationManager.configuration.useDarkMode)
                Toggle("Show Effects", isOn: $configurationManager.configuration.showEffects)
                Toggle("Show Scenes", isOn: $configurationManager.configuration.showScenes)
            } header: {
                Text("Appearance")
            }
            
            Section {
                Stepper("Discovery Timeout: \(configurationManager.configuration.discoveryTimeout) seconds", 
                        value: $configurationManager.configuration.discoveryTimeout, 
                        in: 1...30,
                        step: 1)
                
                Toggle("Auto-Connect", isOn: $configurationManager.configuration.autoConnect)
            } header: {
                Text("Device Discovery")
            }
            
            Section {
                Button("Reset All Settings") {
                    Task {
                        await configurationManager.resetConfiguration()
                    }
                }
                .foregroundColor(.red)
            } header: {
                Text("Reset")
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text("YeelightControl")
                        .font(.headline)
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } header: {
                Text("About")
            }
        }
    }
}

// MARK: - Extensions

extension DeviceType {
    var iconName: String {
        switch self {
        case .bulb:
            return "lightbulb"
        case .strip:
            return "light.strip"
        case .ceiling:
            return "light.recessed"
        case .lamp:
            return "lamp.desk"
        case .ambient:
            return "light.cylindrical"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

extension EffectType {
    var iconName: String {
        switch self {
        case .colorFlow:
            return "rainbow"
        case .pulse:
            return "waveform"
        case .strobe:
            return "bolt.fill"
        case .candle:
            return "flame"
        case .music:
            return "music.note"
        case .sunrise:
            return "sunrise"
        case .sunset:
            return "sunset"
        case .nightLight:
            return "moon.stars"
        case .movie:
            return "film"
        case .gaming:
            return "gamecontroller"
        case .reading:
            return "book"
        case .party:
            return "party.popper"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 