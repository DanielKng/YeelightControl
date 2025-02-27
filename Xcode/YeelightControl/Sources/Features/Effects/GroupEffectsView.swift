import SwiftUI

enum GroupEffect {
    case rainbow
    case wave(Color)
    case pulse([Color])
    case fade(from: Color, to: Color)
}

struct GroupEffectsView: View {
    let group: DeviceGroupManager.DeviceGroup
    let deviceManager: YeelightManager
    let groupManager: DeviceGroupManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedEffect = Effect.rainbow
    @State private var waveColor = Color.blue
    @State private var pulseColors: [Color] = [.red, .blue]
    @State private var fadeFromColor = Color.blue
    @State private var fadeToColor = Color.purple
    @State private var isPreviewActive = false
    
    enum Effect {
        case rainbow, wave, pulse, fade
        
        var name: String {
            switch self {
            case .rainbow: return "Rainbow"
            case .wave: return "Wave"
            case .pulse: return "Pulse"
            case .fade: return "Fade"
            }
        }
        
        var icon: String {
            switch self {
            case .rainbow: return "rainbow"
            case .wave: return "wave.3.right"
            case .pulse: return "waveform.path.ecg"
            case .fade: return "square.2.stack.3d"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Effect Type", selection: $selectedEffect) {
                        ForEach([Effect.rainbow, .wave, .pulse, .fade], id: \.name) { effect in
                            Label(effect.name, systemImage: effect.icon)
                                .tag(effect)
                        }
                    }
                }
                
                switch selectedEffect {
                case .rainbow:
                    EmptyView()
                    
                case .wave:
                    Section("Wave Settings") {
                        ColorPicker("Wave Color", selection: $waveColor)
                    }
                    
                case .pulse:
                    Section("Pulse Settings") {
                        ForEach(pulseColors.indices, id: \.self) { index in
                            ColorPicker("Color \(index + 1)", selection: $pulseColors[index])
                        }
                        .onDelete { pulseColors.remove(atOffsets: $0) }
                        
                        if pulseColors.count < 5 {
                            Button("Add Color") {
                                pulseColors.append(.white)
                            }
                        }
                    }
                    
                case .fade:
                    Section("Fade Settings") {
                        ColorPicker("From Color", selection: $fadeFromColor)
                        ColorPicker("To Color", selection: $fadeToColor)
                    }
                }
                
                Section {
                    Button(action: applyEffect) {
                        HStack {
                            Text("Apply Effect")
                            Spacer()
                            if isPreviewActive {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isPreviewActive)
                }
            }
            .navigationTitle("Group Effects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func applyEffect() {
        isPreviewActive = true
        
        let effect: GroupEffect
        switch selectedEffect {
        case .rainbow:
            effect = .rainbow
        case .wave:
            effect = .wave(waveColor)
        case .pulse:
            effect = .pulse(pulseColors)
        case .fade:
            effect = .fade(from: fadeFromColor, to: fadeToColor)
        }
        
        groupManager.applyGroupEffect(group, effect: effect, using: deviceManager)
        
        // Disable preview after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isPreviewActive = false
        }
    }
} 