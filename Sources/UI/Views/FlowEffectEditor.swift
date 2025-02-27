import SwiftUI

struct FlowEffectEditor: View {
    @Binding var params: YeelightDevice.FlowParams
    @State private var selectedPreset: FlowPreset?
    @State private var showingColorPicker = false
    @State private var editingColorIndex: Int?
    
    enum FlowPreset: String, CaseIterable {
        case candlelight = "Candlelight"
        case sunrise = "Sunrise"
        case disco = "Disco"
        case pulse = "Pulse"
        case strobe = "Strobe"
        
        var params: YeelightDevice.FlowParams {
            switch self {
            case .candlelight:
                return YeelightDevice.FlowParams(
                    count: 0,
                    action: .recover,
                    transitions: [
                        .init(duration: 800, mode: .color(red: 255, green: 147, blue: 41)),
                        .init(duration: 800, mode: .color(red: 255, green: 137, blue: 31))
                    ]
                )
            case .sunrise:
                return YeelightDevice.FlowParams(
                    count: 1,
                    action: .stay,
                    transitions: [
                        .init(duration: 3000, mode: .temperature(temp: 1700, brightness: 1)),
                        .init(duration: 3000, mode: .temperature(temp: 2500, brightness: 50)),
                        .init(duration: 3000, mode: .temperature(temp: 5000, brightness: 100))
                    ]
                )
            case .disco:
                return YeelightDevice.FlowParams(
                    count: 0,
                    action: .recover,
                    transitions: [
                        .init(duration: 500, mode: .color(red: 255, green: 0, blue: 0)),
                        .init(duration: 500, mode: .color(red: 0, green: 255, blue: 0)),
                        .init(duration: 500, mode: .color(red: 0, green: 0, blue: 255))
                    ]
                )
            case .pulse:
                return YeelightDevice.FlowParams(
                    count: 0,
                    action: .recover,
                    transitions: [
                        .init(duration: 1000, mode: .brightness(level: 100)),
                        .init(duration: 1000, mode: .brightness(level: 1))
                    ]
                )
            case .strobe:
                return YeelightDevice.FlowParams(
                    count: 0,
                    action: .recover,
                    transitions: [
                        .init(duration: 50, mode: .brightness(level: 100)),
                        .init(duration: 50, mode: .brightness(level: 1))
                    ]
                )
            }
        }
        
        var description: String {
            switch self {
            case .candlelight:
                return "A warm, flickering light"
            case .sunrise:
                return "A gradual transition from night to day"
            case .disco:
                return "A colorful light show"
            case .pulse:
                return "A pulsating light"
            case .strobe:
                return "A flashing light"
            }
        }
    }
    
    var body: some View {
        UnifiedDetailView(
            title: "Flow Effect",
            mainContent: {
                VStack(spacing: 16) {
                    // Presets
                    UnifiedListView(
                        title: "Presets",
                        items: FlowPreset.allCases,
                        emptyStateMessage: ""
                    ) { preset in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.rawValue)
                                    .font(.headline)
                                Text(preset.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if preset == selectedPreset {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPreset = preset
                            params = preset.params
                        }
                    }
                    
                    // Flow Settings
                    UnifiedListView(
                        title: "Flow Settings",
                        items: [
                            ("Repeat Count", "count"),
                            ("End Action", "action")
                        ],
                        emptyStateMessage: ""
                    ) { item in
                        if item.1 == "count" {
                            Picker("Repeat Count", selection: $params.count) {
                                Text("Forever").tag(0)
                                ForEach(1...10, id: \.self) { count in
                                    Text("\(count) times").tag(count)
                                }
                            }
                        } else {
                            Picker("End Action", selection: $params.action) {
                                Text("Recover").tag(YeelightDevice.FlowAction.recover)
                                Text("Stay").tag(YeelightDevice.FlowAction.stay)
                                Text("Turn Off").tag(YeelightDevice.FlowAction.off)
                            }
                        }
                    }
                    
                    // Transitions
                    UnifiedListView(
                        title: "Transitions",
                        items: params.transitions.indices,
                        emptyStateMessage: "No transitions added",
                        onDelete: { indexSet in
                            params.transitions.remove(atOffsets: indexSet)
                        },
                        onMove: { from, to in
                            params.transitions.move(fromOffsets: from, toOffset: to)
                        }
                    ) { index in
                        TransitionRow(
                            transition: $params.transitions[index],
                            onTap: {
                                editingColorIndex = index
                                showingColorPicker = true
                            }
                        )
                    }
                    
                    Button("Add Transition") {
                        params.transitions.append(.init(duration: 1000, mode: .brightness(level: 100)))
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                }
            }
        )
        .sheet(isPresented: $showingColorPicker) {
            if let index = editingColorIndex {
                ColorPickerSheet(transition: $params.transitions[index])
            }
        }
    }
}

struct TransitionRow: View {
    @Binding var transition: YeelightDevice.FlowTransition
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transition.mode.description)
                    .font(.subheadline)
                Text("\(Int(transition.duration))ms")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            switch transition.mode {
            case .color(let red, let green, let blue):
                Circle()
                    .fill(Color(red: Double(red)/255, green: Double(green)/255, blue: Double(blue)/255))
                    .frame(width: 24, height: 24)
                    .onTapGesture(perform: onTap)
            case .temperature(let temp, _):
                Circle()
                    .fill(temp > 4000 ? Color.blue : Color.orange)
                    .frame(width: 24, height: 24)
                    .onTapGesture(perform: onTap)
            case .brightness:
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
            }
        }
    }
}

struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var transition: YeelightDevice.FlowTransition
    @State private var selectedColor = Color.white
    @State private var duration: Double = 1000
    @State private var temperature: Double = 4000
    @State private var brightness: Double = 100
    @State private var mode: ColorMode = .rgb
    
    enum ColorMode {
        case rgb, temperature, brightness
    }
    
    var body: some View {
        NavigationStack {
            UnifiedDetailView(
                title: "Edit Transition",
                mainContent: {
                    VStack(spacing: 16) {
                        // Mode Selection
                        Picker("Mode", selection: $mode) {
                            Text("RGB").tag(ColorMode.rgb)
                            Text("Temperature").tag(ColorMode.temperature)
                            Text("Brightness").tag(ColorMode.brightness)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Color Settings
                        UnifiedListView(
                            title: "Color Settings",
                            items: [()] as [()] ,
                            emptyStateMessage: ""
                        ) { _ in
                            switch mode {
                            case .rgb:
                                ColorPicker("Color", selection: $selectedColor)
                            case .temperature:
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Temperature")
                                        Spacer()
                                        Text("\(Int(temperature))K")
                                    }
                                    Slider(value: $temperature, in: 1700...6500)
                                }
                            case .brightness:
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Brightness")
                                        Spacer()
                                        Text("\(Int(brightness))%")
                                    }
                                    Slider(value: $brightness, in: 1...100)
                                }
                            }
                        }
                        
                        // Duration
                        UnifiedListView(
                            title: "Duration",
                            items: [()] as [()] ,
                            emptyStateMessage: ""
                        ) { _ in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("Duration")
                                    Spacer()
                                    Text("\(Int(duration))ms")
                                }
                                Slider(value: $duration, in: 50...5000)
                            }
                        }
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        updateTransition()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func updateTransition() {
        transition.duration = duration
        
        switch mode {
        case .rgb:
            let components = UIColor(selectedColor).cgColor.components ?? [1, 1, 1, 1]
            transition.mode = .color(
                red: Int(components[0] * 255),
                green: Int(components[1] * 255),
                blue: Int(components[2] * 255)
            )
        case .temperature:
            transition.mode = .temperature(temp: Int(temperature), brightness: Int(brightness))
        case .brightness:
            transition.mode = .brightness(level: Int(brightness))
        }
    }
} 