import SwiftUI

struct EffectsView: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    
    @State private var selectedEffect = Effect.colorFlow
    @State private var musicModeEnabled = false
    
    enum Effect {
        case colorFlow, music
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Picker("Effect Type", selection: $selectedEffect) {
                Text("Color Flow").tag(Effect.colorFlow)
                Text("Music Mode").tag(Effect.music)
            }
            .pickerStyle(.segmented)
            
            if selectedEffect == .colorFlow {
                ColorFlowView(device: device, manager: manager)
            } else {
                MusicModeView(device: device, manager: manager)
            }
        }
        .padding(.vertical)
    }
}

struct MusicModeView: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    
    @State private var isEnabled = false
    @State private var sensitivity: Double = 50
    @State private var colorStyle = ColorStyle.rainbow
    
    enum ColorStyle {
        case rainbow, mono, pulse
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Toggle("Enable Music Mode", isOn: $isEnabled)
                .onChange(of: isEnabled) { newValue in
                    manager.setMusicMode(device, enabled: newValue)
                }
            
            if isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Sensitivity", systemImage: "waveform")
                        .foregroundStyle(.secondary)
                    
                    Slider(value: $sensitivity, in: 0...100) { changed in
                        if changed {
                            // Update sensitivity
                        }
                    }
                }
                
                Picker("Color Style", selection: $colorStyle) {
                    Text("Rainbow").tag(ColorStyle.rainbow)
                    Text("Monochrome").tag(ColorStyle.mono)
                    Text("Pulse").tag(ColorStyle.pulse)
                }
                .pickerStyle(.segmented)
                
                // Visualization preview
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                    
                    Circle()
                        .trim(from: 0, to: sensitivity / 100)
                        .stroke(
                            colorStyle == .rainbow ? Color.blue : Color.purple,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 100, height: 100)
                .padding()
            }
            
            if isEnabled {
                Text("Music mode uses your device's microphone to sync light effects with ambient sound")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
} 