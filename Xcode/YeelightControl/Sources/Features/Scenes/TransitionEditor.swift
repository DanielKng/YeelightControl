import SwiftUI

struct TransitionEditor: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (YeelightDevice.FlowParams.FlowTransition) -> Void
    
    @State private var duration: Double = 1000
    @State private var mode: TransitionMode = .color
    @State private var brightness: Double = 100
    @State private var selectedColor = Color.white
    @State private var colorTemp: Double = 4000
    
    enum TransitionMode: Int {
        case color = 1
        case temperature = 2
        case sleep = 7
        
        var name: String {
            switch self {
            case .color: return "Color"
            case .temperature: return "Temperature"
            case .sleep: return "Sleep"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(Int(duration))ms")
                        }
                        Slider(value: $duration, in: 50...10000)
                    }
                    
                    Picker("Mode", selection: $mode) {
                        Text("Color").tag(TransitionMode.color)
                        Text("Temperature").tag(TransitionMode.temperature)
                        Text("Sleep").tag(TransitionMode.sleep)
                    }
                }
                
                Section("Effect") {
                    switch mode {
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
                    case .sleep:
                        Text("Sleep mode will dim the light gradually")
                            .foregroundStyle(.secondary)
                    }
                    
                    if mode != .sleep {
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
            }
            .navigationTitle("Add Transition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveTransition() }
                }
            }
        }
    }
    
    private func saveTransition() {
        let value: Int
        switch mode {
        case .color:
            let components = UIColor(selectedColor).cgColor.components ?? [1, 1, 1, 1]
            value = (Int(components[0] * 255) * 65536) +
                   (Int(components[1] * 255) * 256) +
                   Int(components[2] * 255)
        case .temperature:
            value = Int(colorTemp)
        case .sleep:
            value = 0
        }
        
        let transition = YeelightDevice.FlowParams.FlowTransition(
            duration: Int(duration),
            mode: mode.rawValue,
            value: value,
            brightness: Int(brightness)
        )
        
        onSave(transition)
        dismiss()
    }
} 