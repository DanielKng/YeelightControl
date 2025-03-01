import SwiftUI

struct ColorFlowView: View {
    enum FlowPreset: String, CaseIterable, Identifiable {
        case candlelight, sunrise, party, pulse, strobe, custom
        var id: String { rawValue }
    }
    
    @ObservedObject var device: YeelightDevice
    
    @State private var selectedPreset: FlowPreset = .candlelight
    @State private var duration: Double = 1000
    @State private var isCustomizing = false
    
    var body: some View {
        VStack {
            NavigationView {
                Form {
                    Section(
                        header: Text("Preset Effects"),
                        footer: Text(selectedPreset.description)
                    ) {
                        Picker("Effect Type", selection: $selectedPreset) { preset in
                            ForEach(FlowPreset.allCases) { preset in
                                Text(preset.rawValue.capitalized)
                                    .tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if selectedPreset != .custom {
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text("\(Int(duration))s")
                            }
                            
                            Slider(
                                value: $duration,
                                in: 30...3600,
                                step: 30
                            ) {
                                Text("Duration")
                            } minimumValueLabel: {
                                Text("30s")
                            } maximumValueLabel: {
                                Text("1h")
                            }
                        }
                    }
                    
                    Section {
                        Button(device.flowing ? "Stop Effect" : "Start Effect") {
                            toggleEffect()
                        }
                        
                        Button("Customize Transitions") {
                            isCustomizing = true
                        }
                    }
                }
                .navigationTitle("Color Flow")
                .sheet(isPresented: $isCustomizing) {
                    FlowCustomizationView(device: device)
                }
            }
        }
    }
    
    private func toggleEffect() {
        if device.flowing {
            device.stopColorFlow()
            return
        }
        
        switch selectedPreset {
        case .candlelight:
            device.startCandlelightEffect(duration: duration)
        case .sunrise:
            device.startSunriseEffect(duration: duration)
        case .party:
            device.startPartyEffect(duration: duration)
        case .pulse:
            device.startPulseEffect(duration: duration)
        case .strobe:
            device.startStrobeEffect(duration: duration)
        case .custom:
            // Use custom transitions
            break
        }
    }
}

extension ColorFlowView.FlowPreset {
    var description: String {
        switch self {
        case .candlelight:
            return "Warm flickering light effect"
        case .sunrise:
            return "Gradually brightening warm to cool light"
        case .party:
            return "Colorful party lighting effect"
        case .pulse:
            return "Smooth pulsing light effect"
        case .strobe:
            return "Quick flashing light effect"
        case .custom:
            return "Create your own custom effect"
        }
    }
}

struct FlowCustomizationView: View {
    @ObservedObject var device: YeelightDevice
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var transitions: [YeelightDevice.FlowParams.FlowTransition] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    List {
                        ForEach(transitions.indices, id: \.self) { index in
                            TransitionRow(transition: transitions[index])
                        }
                        .onDelete { indexSet in
                            transitions.remove(atOffsets: indexSet)
                        }
                    }
                    .listStyle(.plain)
                    
                    Button {
                        // Add new transition
                        let newTransition = YeelightDevice.FlowParams.FlowTransition(
                            duration: 1000,
                            mode: .color,
                            value: 0xFF0000,
                            brightness: 100
                        )
                        transitions.append(newTransition)
                    } label: {
                        Label("Add Transition", systemImage: "plus")
                    }
                }
                
                Section {
                    Button("Apply Custom Flow") {
                        applyCustomFlow()
                        dismiss()
                    }
                    .disabled(transitions.isEmpty)
                }
            }
            .navigationTitle("Custom Flow")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
    
    private func applyCustomFlow() {
        // Apply custom flow with transitions
        device.startColorFlow(
            count: 0, // Infinite
            action: .stay,
            transitions: transitions
        )
    }
} 