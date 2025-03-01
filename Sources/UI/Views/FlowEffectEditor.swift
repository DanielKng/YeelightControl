import SwiftUI

struct FlowEffectEditor: View {
    @Binding var params: YeelightDevice.FlowParams
    @State private var selectedPreset: FlowPreset?
    @State private var showingColorPicker = false
    @State private var editingColorIndex: Int?
    
    enum FlowPreset: String, CaseIterable {
        case candlelight = "Candlelight"
        case sunrise = "Sunrise"
        case sunset = "Sunset"
        case romance = "Romance"
        case nightMode = "Night Mode"
        case movie = "Movie"
        case party = "Party"
        
        var params: YeelightDevice.FlowParams {
            switch self {
            case .candlelight:
                return YeelightDevice.FlowParams(
                    count: 0,
                    action: .recover,
                    transitions: [
                        YeelightDevice.FlowTransition(
                            duration: 800,
                            mode: .temperature(2700),
                            brightness: 80,
                            brightness2: 50
                        ),
                        YeelightDevice.FlowTransition(
                            duration: 800,
                            mode: .temperature(2700),
                            brightness: 60,
                            brightness2: 80
                        )
                    ]
                )
            case .sunrise:
                return YeelightDevice.FlowParams(
                    count: 1,
                    action: .recover,
                    transitions: [
                        YeelightDevice.FlowTransition(
                            duration: 3000,
                            mode: .temperature(2000),
                            brightness: 1,
                            brightness2: 0
                        ),
                        YeelightDevice.FlowTransition(
                            duration: 5000,
                            mode: .temperature(2000),
                            brightness: 50,
                            brightness2: 0
                        ),
                        YeelightDevice.FlowTransition(
                            duration: 7000,
                            mode: .temperature(3500),
                            brightness: 100,
                            brightness2: 0
                        )
                    ]
                )
            case .sunset:
                return YeelightDevice.FlowParams(
                    count: 1,
                    action: .recover,
                    transitions: [
                        YeelightDevice.FlowTransition(
                            duration: 5000,
                            mode: .temperature(3500),
                            brightness: 100,
                            brightness2: 0
                        ),
                        YeelightDevice.FlowTransition(
                            duration: 5000,
                            mode: .temperature(2000),
                            brightness: 50,
                            brightness2: 0
                        ),
                        YeelightDevice.FlowTransition(
                            duration: 3000,
                            mode: .temperature(2000),
                            brightness: 1,
                            brightness2: 0
                        )
                    ]
                )
            case .romance, .nightMode, .movie, .party:
                // Simplified for brevity
                return YeelightDevice.FlowParams(
                    count: 0,
                    action: .recover,
                    transitions: [
                        YeelightDevice.FlowTransition(
                            duration: 1000,
                            mode: .rgb(Color.red),
                            brightness: 80,
                            brightness2: 0
                        ),
                        YeelightDevice.FlowTransition(
                            duration: 1000,
                            mode: .rgb(Color.blue),
                            brightness: 80,
                            brightness2: 0
                        )
                    ]
                )
            }
        }
        
        var description: String {
            switch self {
            case .candlelight:
                return "Simulates the warm, flickering light of a candle"
            case .sunrise:
                return "Gradually brightens from warm to cool light"
            case .sunset:
                return "Gradually dims from cool to warm light"
            case .romance:
                return "Soft, warm lighting with gentle color transitions"
            case .nightMode:
                return "Very dim, warm light for nighttime use"
            case .movie:
                return "Dynamic lighting that responds to on-screen content"
            case .party:
                return "Vibrant, changing colors for a festive atmosphere"
            }
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Presets")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(FlowPreset.allCases, id: \.self) { preset in
                            VStack {
                                Circle()
                                    .fill(preset == selectedPreset ? Color.accentColor : Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: iconForPreset(preset))
                                            .foregroundColor(preset == selectedPreset ? .white : .gray)
                                    )
                                
                                Text(preset.rawValue)
                                    .font(.caption)
                                    .foregroundColor(preset == selectedPreset ? .primary : .secondary)
                            }
                            .onTapGesture {
                                selectPreset(preset)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section(header: Text("Parameters")) {
                ForEach(Array(params.dictionary.sorted(by: { $0.0 < $1.0 })), id: \.key) { item in
                    if item.0 == "count" {
                        Stepper("Repeat: \(item.1 as? Int == 0 ? "Forever" : "\(item.1)")") {
                            var newParams = params
                            newParams.count = min(params.count + 1, 10)
                            params = newParams
                        } onDecrement: {
                            var newParams = params
                            newParams.count = max(params.count - 1, 0)
                            params = newParams
                        }
                    } else if item.0 == "action" {
                        Picker("After completion", selection: Binding(
                            get: { params.action },
                            set: { newValue in
                                var newParams = params
                                newParams.action = newValue
                                params = newParams
                            }
                        )) {
                            Text("Recover").tag(YeelightDevice.FlowAction.recover)
                            Text("Stay").tag(YeelightDevice.FlowAction.stay)
                            Text("Turn Off").tag(YeelightDevice.FlowAction.turnOff)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            
            Section(header: Text("Color Transitions")) {
                ForEach(Array(params.transitions.enumerated()), id: \.offset) { index, transition in
                    TransitionRow(transition: Binding(
                        get: { transition },
                        set: { newValue in
                            var newParams = params
                            newParams.transitions[index] = newValue
                            params = newParams
                        }
                    ))
                    .onTapGesture {
                        editingColorIndex = index
                        showingColorPicker = true
                    }
                }
                
                Button(action: addTransition) {
                    Label("Add Transition", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Color Flow Effect")
        .sheet(isPresented: $showingColorPicker) {
            if let index = editingColorIndex {
                ColorPickerSheet(
                    transition: Binding(
                        get: { params.transitions[index] },
                        set: { newValue in
                            var newParams = params
                            newParams.transitions[index] = newValue
                            params = newParams
                        }
                    )
                )
            }
        }
    }
    
    private func iconForPreset(_ preset: FlowPreset) -> String {
        switch preset {
        case .candlelight: return "flame"
        case .sunrise: return "sunrise"
        case .sunset: return "sunset"
        case .romance: return "heart"
        case .nightMode: return "moon.stars"
        case .movie: return "film"
        case .party: return "sparkles"
        }
    }
    
    private func selectPreset(_ preset: FlowPreset) {
        selectedPreset = preset
        params = preset.params
    }
    
    private func addTransition() {
        var newParams = params
        newParams.transitions.append(
            YeelightDevice.FlowTransition(
                duration: 1000,
                mode: .rgb(Color.white),
                brightness: 100,
                brightness2: 0
            )
        )
        params = newParams
    }
}

struct TransitionRow: View {
    @Binding var transition: YeelightDevice.FlowTransition
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack {
                HStack {
                    Text("Duration")
                    Spacer()
                    Text("\(Int(transition.duration)) ms")
                }
                
                Slider(
                    value: Binding(
                        get: { Double(transition.duration) },
                        set: { transition.duration = Int($0) }
                    ),
                    in: 50...10000,
                    step: 50
                )
                
                Picker("Mode", selection: Binding(
                    get: { modeIndex },
                    set: { newValue in
                        switch newValue {
                        case 0:
                            transition.mode = .rgb(Color.white)
                        case 1:
                            transition.mode = .temperature(4000)
                        default:
                            break
                        }
                    }
                )) {
                    Text("Color").tag(0)
                    Text("Temperature").tag(1)
                }
                .pickerStyle(.segmented)
                
                HStack {
                    Text("Brightness")
                    Spacer()
                    Text("\(Int(transition.brightness))%")
                }
                
                Slider(
                    value: Binding(
                        get: { Double(transition.brightness) },
                        set: { transition.brightness = Int($0) }
                    ),
                    in: 1...100,
                    step: 1
                )
            }
            .padding(.vertical, 8)
        } label: {
            HStack {
                switch transition.mode {
                case .rgb(let color):
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                    Text("Color")
                case .temperature(let temp):
                    Circle()
                        .fill(colorForTemperature(temp))
                        .frame(width: 24, height: 24)
                    Text("Temperature: \(temp)K")
                }
                
                Spacer()
                
                Text("\(Int(transition.duration)) ms")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var modeIndex: Int {
        switch transition.mode {
        case .rgb: return 0
        case .temperature: return 1
        }
    }
    
    private func colorForTemperature(_ temp: Int) -> Color {
        if temp <= 2700 {
            return Color.orange
        } else if temp <= 4000 {
            return Color.yellow
        } else {
            return Color.white
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
        case rgb
        case temperature
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Transition Type")) {
                    Picker("Mode", selection: $mode) {
                        Text("Color").tag(ColorMode.rgb)
                        Text("Temperature").tag(ColorMode.temperature)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: mode) { newValue in
                        switch newValue {
                        case .rgb:
                            switch transition.mode {
                            case .rgb(let color):
                                selectedColor = color
                            case .temperature:
                                selectedColor = .white
                            }
                        case .temperature:
                            switch transition.mode {
                            case .rgb:
                                temperature = 4000
                            case .temperature(let temp):
                                temperature = Double(temp)
                            }
                        }
                    }
                }
                
                Section(header: Text("Duration")) {
                    VStack {
                        Slider(value: $duration, in: 50...10000, step: 50)
                        HStack {
                            Text("50ms")
                            Spacer()
                            Text("\(Int(duration))ms")
                            Spacer()
                            Text("10s")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Brightness")) {
                    VStack {
                        Slider(value: $brightness, in: 1...100, step: 1)
                        Text("\(Int(brightness))%")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                
                switch mode {
                case .rgb:
                    Section(header: Text("Color")) {
                        ColorPicker("Select Color", selection: $selectedColor)
                    }
                case .temperature:
                    Section(header: Text("Color Temperature")) {
                        VStack {
                            Slider(value: $temperature, in: 1700...6500, step: 100)
                            HStack {
                                Text("Warm")
                                Spacer()
                                Text("\(Int(temperature))K")
                                Spacer()
                                Text("Cool")
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Edit Transition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateTransition()
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Initialize values from current transition
                duration = Double(transition.duration)
                brightness = Double(transition.brightness)
                
                switch transition.mode {
                case .rgb(let color):
                    mode = .rgb
                    selectedColor = color
                case .temperature(let temp):
                    mode = .temperature
                    temperature = Double(temp)
                }
            }
        }
    }
    
    private func updateTransition() {
        transition.duration = Int(duration)
        transition.brightness = Int(brightness)
        
        switch mode {
        case .rgb:
            transition.mode = .rgb(selectedColor)
        case .temperature:
            transition.mode = .temperature(Int(temperature))
        }
    }
} 