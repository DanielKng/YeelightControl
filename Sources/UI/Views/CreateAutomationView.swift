import SwiftUI
import CoreLocation

struct CreateAutomationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var deviceManager = YeelightManager.shared
    
    @State private var name = ""
    @State private var selectedTrigger: TriggerType = .time
    @State private var selectedTime = Date()
    @State private var selectedLocation: Automation.Location?
    @State private var selectedDevices: Set<String> = []
    @State private var selectedAction: ActionType = .scene
    @State private var selectedScene: ScenePreset?
    @State private var powerState = true
    @State private var brightness: Double = 100
    @State private var showingSceneSelector = false
    @State private var showingLocationPicker = false
    
    enum TriggerType {
        case time, sunset, sunrise, location
        
        var name: String {
            switch self {
            case .time: return "Time"
            case .sunset: return "Sunset"
            case .sunrise: return "Sunrise"
            case .location: return "Location"
            }
        }
        
        var icon: String {
            switch self {
            case .time: return "clock"
            case .sunset: return "sunset"
            case .sunrise: return "sunrise"
            case .location: return "location"
            }
        }
    }
    
    enum ActionType {
        case scene, power, brightness
        
        var name: String {
            switch self {
            case .scene: return "Scene"
            case .power: return "Power"
            case .brightness: return "Brightness"
            }
        }
        
        var icon: String {
            switch self {
            case .scene: return "theatermasks"
            case .power: return "power"
            case .brightness: return "sun.max"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Automation Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Trigger", selection: $selectedTrigger) {
                        ForEach([TriggerType.time, .sunset, .sunrise, .location], id: \.name) { trigger in
                            Label(trigger.name, systemImage: trigger.icon)
                                .tag(trigger)
                        }
                    }
                    
                    switch selectedTrigger {
                    case .time:
                        DatePicker(
                            "Time",
                            selection: $selectedTime,
                            displayedComponents: [.hourAndMinute]
                        )
                    case .location:
                        Button(action: { showingLocationPicker = true }) {
                            HStack {
                                Text("Location")
                                Spacer()
                                if let location = selectedLocation {
                                    Text(location.name)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Select Location")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    default:
                        EmptyView()
                    }
                }
                
                Section("Devices") {
                    EnhancedDeviceSelectionList(selectedDevices: $selectedDevices)
                }
                
                Section("Action") {
                    Picker("Action Type", selection: $selectedAction) {
                        ForEach([ActionType.scene, .power, .brightness], id: \.name) { action in
                            Label(action.name, systemImage: action.icon)
                                .tag(action)
                        }
                    }
                    
                    switch selectedAction {
                    case .scene:
                        Button(action: { showingSceneSelector = true }) {
                            HStack {
                                Text("Scene")
                                Spacer()
                                if let scene = selectedScene {
                                    Text(scene.name)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Select Scene")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    case .power:
                        Toggle("Power State", isOn: $powerState)
                    case .brightness:
                        VStack {
                            Text("Brightness: \(Int(brightness))%")
                            Slider(value: $brightness, in: 1...100)
                        }
                    }
                }
            }
            .navigationTitle("New Automation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAutomation() }
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingSceneSelector) {
                SceneSelector(selectedScene: $selectedScene)
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPicker(selectedLocation: $selectedLocation)
            }
        }
    }
    
    private var isValid: Bool {
        guard !name.isEmpty && !selectedDevices.isEmpty else { return false }
        
        switch selectedTrigger {
        case .location:
            guard selectedLocation != nil else { return false }
        default:
            break
        }
        
        switch selectedAction {
        case .scene:
            return selectedScene != nil
        default:
            return true
        }
    }
    
    private func saveAutomation() {
        let trigger: Automation.Trigger
        switch selectedTrigger {
        case .time:
            trigger = .time(selectedTime)
        case .sunset:
            trigger = .sunset
        case .sunrise:
            trigger = .sunrise
        case .location:
            trigger = .location(selectedLocation!)
        }
        
        let action: Automation.Action
        switch selectedAction {
        case .scene:
            action = .setScene(deviceIPs: Array(selectedDevices), scene: selectedScene!.scene)
        case .power:
            action = .setPower(deviceIPs: Array(selectedDevices), on: powerState)
        case .brightness:
            action = .setBrightness(deviceIPs: Array(selectedDevices), level: Int(brightness))
        }
        
        let automation = Automation(
            name: name,
            isEnabled: true,
            trigger: trigger,
            action: action
        )
        
        DeviceStorage.shared.saveAutomation(automation)
        dismiss()
    }
}

struct LocationPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: Automation.Location?
    @State private var locationName = ""
    @State private var radius: Double = 100
    @State private var coordinate = CLLocationCoordinate2D()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Location Name", text: $locationName)
                    
                    VStack(alignment: .leading) {
                        Text("Radius: \(Int(radius))m")
                        Slider(value: $radius, in: 50...500)
                    }
                    
                    // Map view would go here
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 200)
                        .overlay {
                            Text("Map View")
                        }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        selectedLocation = Automation.Location(
                            coordinate: coordinate,
                            radius: radius,
                            name: locationName
                        )
                        dismiss()
                    }
                    .disabled(locationName.isEmpty)
                }
            }
        }
    }
} 