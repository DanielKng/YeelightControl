import SwiftUI

struct ColorFlowView: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    
    @State private var selectedPreset: FlowPreset = .candlelight
    @State private var duration: Double = 1000
    @State private var isCustomizing = false
    
    enum FlowPreset: String, CaseIterable {
        case candlelight = "Candlelight"
        case colorCycle = "Color Cycle"
        case police = "Police Lights"
        case disco = "Disco"
        case pulse = "Pulse"
        case custom = "Custom"
        
        var transitions: [YeelightDevice.FlowParams.FlowTransition] {
            switch self {
            case .candlelight:
                return [
                    .init(duration: 800, mode: 2, value: 2700, brightness: 50),
                    .init(duration: 800, mode: 2, value: 3000, brightness: 30)
                ]
            case .colorCycle:
                return [
                    .init(duration: 1500, mode: 1, value: 0xFF0000, brightness: 100),
                    .init(duration: 1500, mode: 1, value: 0x00FF00, brightness: 100),
                    .init(duration: 1500, mode: 1, value: 0x0000FF, brightness: 100)
                ]
            // Add other presets...
            default:
                return []
            }
        }
    }
    
    var body: some View {
        List {
            Section("Preset Effects") {
                Picker("Effect", selection: $selectedPreset) {
                    ForEach(FlowPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                
                if selectedPreset != .custom {
                    Button(device.flowing ? "Stop Effect" : "Start Effect") {
                        toggleEffect()
                    }
                }
            }
            
            Section {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text("\(Int(duration))ms")
                }
                Slider(value: $duration, in: 500...5000, step: 100)
            }
            
            if selectedPreset == .custom {
                Section("Custom Effect") {
                    Button("Customize Transitions") {
                        isCustomizing = true
                    }
                }
            }
        }
        .sheet(isPresented: $isCustomizing) {
            CustomFlowEditor(device: device, manager: manager)
        }
    }
    
    private func toggleEffect() {
        if device.flowing {
            manager.stopColorFlow(device)
        } else {
            let params = YeelightDevice.FlowParams(
                count: 0,
                action: .recover,
                transitions: selectedPreset.transitions
            )
            manager.startColorFlow(device, params: params)
        }
    }
}

struct CustomFlowEditor: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var transitions: [YeelightDevice.FlowParams.FlowTransition] = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(transitions.indices, id: \.self) { index in
                    TransitionRow(transition: $transitions[index])
                }
                .onDelete(perform: deleteTransitions)
                
                Button("Add Transition") {
                    transitions.append(.init(
                        duration: 1000,
                        mode: 1,
                        value: 0xFF0000,
                        brightness: 100
                    ))
                }
            }
            .navigationTitle("Custom Flow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveFlow()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func deleteTransitions(at offsets: IndexSet) {
        transitions.remove(atOffsets: offsets)
    }
    
    private func saveFlow() {
        let params = YeelightDevice.FlowParams(
            count: 0,
            action: .recover,
            transitions: transitions
        )
        manager.startColorFlow(device, params: params)
    }
} 