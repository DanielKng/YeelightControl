import SwiftUI

struct AutomationEditor: View {
    @ObservedObject var manager: YeelightManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedTrigger: TriggerType = .time
    @State private var selectedHour = 8
    @State private var selectedMinute = 0
    @State private var selectedAction: ActionType = .scene
    @State private var selectedScene: ScenePreset?
    @State private var powerState = true
    @State private var brightness: Double = 100
    
    enum TriggerType {
        case time, sunset, sunrise, deviceConnect
    }
    
    enum ActionType {
        case scene, power, brightness
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Automation Details") {
                    TextField("Name", text: $name)
                    
                    Picker("Trigger", selection: $selectedTrigger) {
                        Text("Time").tag(TriggerType.time)
                        Text("Sunset").tag(TriggerType.sunset)
                        Text("Sunrise").tag(TriggerType.sunrise)
                        Text("Device Connect").tag(TriggerType.deviceConnect)
                    }
                    
                    if selectedTrigger == .time {
                        DatePicker(
                            "Time",
                            selection: Binding(
                                get: {
                                    Calendar.current.date(bySettingHour: selectedHour, minute: selectedMinute, second: 0, of: Date()) ?? Date()
                                },
                                set: { date in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                                    selectedHour = components.hour ?? 8
                                    selectedMinute = components.minute ?? 0
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }
                
                Section("Action") {
                    Picker("Action Type", selection: $selectedAction) {
                        Text("Scene").tag(ActionType.scene)
                        Text("Power").tag(ActionType.power)
                        Text("Brightness").tag(ActionType.brightness)
                    }
                    
                    switch selectedAction {
                    case .scene:
                        NavigationLink("Select Scene") {
                            SceneSelector(selectedScene: $selectedScene)
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
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && (
            selectedAction != .scene || selectedScene != nil
        )
    }
    
    private func saveAutomation() {
        let trigger: Automation.Trigger
        switch selectedTrigger {
        case .time:
            trigger = .time(hour: selectedHour, minute: selectedMinute)
        case .sunset:
            trigger = .sunset
        case .sunrise:
            trigger = .sunrise
        case .deviceConnect:
            trigger = .onDeviceConnect
        }
        
        let action: Automation.Action
        switch selectedAction {
        case .scene:
            action = .scene(selectedScene!)
        case .power:
            action = .power(isOn: powerState)
        case .brightness:
            action = .brightness(level: Int(brightness))
        }
        
        let automation = Automation(
            id: UUID(),
            name: name,
            isEnabled: true,
            trigger: trigger,
            action: action
        )
        
        // Save automation
        DeviceStorage.shared.saveAutomation(automation)
        dismiss()
    }
} 