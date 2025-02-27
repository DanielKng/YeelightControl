import SwiftUI

struct ScenesView: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    
    @State private var showingSceneCreator = false
    @State private var selectedScene: ScenePreset?
    
    let presets: [ScenePreset] = [
        .init(name: "Movie Night", icon: "film.fill", scene: .colorTemperature(temperature: 2700, brightness: 50)),
        .init(name: "Reading", icon: "book.fill", scene: .colorTemperature(temperature: 4000, brightness: 80)),
        .init(name: "Party", icon: "party.popper.fill", scene: .colorFlow(params: .partyMode)),
        .init(name: "Relaxing", icon: "leaf.fill", scene: .colorTemperature(temperature: 3000, brightness: 30)),
        .init(name: "Focus", icon: "lightbulb.fill", scene: .colorTemperature(temperature: 5500, brightness: 100)),
        .init(name: "Night Light", icon: "moon.fill", scene: .colorTemperature(temperature: 2000, brightness: 5))
    ]
    
    let moodScenes: [ScenePreset] = [
        ScenePreset(name: "Purple Dream", icon: "cloud.moon.fill", 
                    scene: .color(red: 128, green: 0, blue: 128, brightness: 80)),
        ScenePreset(name: "Warm Night", icon: "moon.stars.fill", 
                    scene: .color(red: 255, green: 147, blue: 41, brightness: 30)),
        ScenePreset(name: "Ocean Breeze", icon: "water.waves", 
                    scene: .color(red: 0, green: 105, blue: 148, brightness: 70)),
        ScenePreset(name: "Sunset Glow", icon: "sunset.fill", 
                    scene: .color(red: 255, green: 102, blue: 0, brightness: 50))
    ]
    
    let dynamicScenes: [ScenePreset] = [
        ScenePreset(name: "Candlelight", icon: "flame.fill", 
                    scene: .colorFlow(params: .candlelight)),
        ScenePreset(name: "Party Mode", icon: "party.popper.fill", 
                    scene: .colorFlow(params: .partyMode)),
        ScenePreset(name: "Purple Pulse", icon: "waveform.path.ecg", 
                    scene: .colorFlow(params: .pulse)),
        ScenePreset(name: "Sunset", icon: "sunset.fill", 
                    scene: .colorFlow(params: .sunset))
    ]
    
    let multiLightScenes: [ScenePreset] = [
        ScenePreset(name: "Hollywood", icon: "film.stack.fill", 
                    scene: .multiLight(.hollywood)),
        ScenePreset(name: "Night Club", icon: "speaker.wave.3.fill", 
                    scene: .multiLight(.nightClub)),
        ScenePreset(name: "Fireplace", icon: "flame.fill", 
                    scene: .multiLight(.fireplace)),
        ScenePreset(name: "Rainbow", icon: "rainbow.fill", 
                    scene: .multiLight(.rainbow))
    ]
    
    let stripEffectScenes: [ScenePreset] = [
        ScenePreset(name: "Color Wave", icon: "wave.3.right", 
                    scene: .stripEffect(.colorWave)),
        ScenePreset(name: "Rainbow", icon: "rainbow", 
                    scene: .stripEffect(.rainbowWave)),
        ScenePreset(name: "Chase Lights", icon: "bolt.horizontal", 
                    scene: .stripEffect(.chaseLights)),
        ScenePreset(name: "Matrix", icon: "square.stack.3d.down.right", 
                    scene: .stripEffect(.matrix)),
        ScenePreset(name: "Fire Wall", icon: "flame.fill", 
                    scene: .stripEffect(.fire))
    ]
    
    let atmosphereScenes: [ScenePreset] = [
        ScenePreset(name: "Ocean Waves", icon: "water.waves", 
                    scene: .colorFlow(params: .oceanWave)),
        ScenePreset(name: "Aurora", icon: "sparkles", 
                    scene: .colorFlow(params: .aurora)),
        ScenePreset(name: "Thunderstorm", icon: "cloud.bolt.fill", 
                    scene: .colorFlow(params: .thunderstorm)),
        ScenePreset(name: "Christmas", icon: "gift.fill", 
                    scene: .colorFlow(params: .christmasLights))
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Scene grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150), spacing: 16)
            ], spacing: 16) {
                ForEach(presets) { preset in
                    SceneButton(
                        preset: preset,
                        isSelected: selectedScene?.id == preset.id,
                        action: {
                            selectedScene = preset
                            manager.setScene(device, scene: preset.scene)
                        }
                    )
                }
            }
            
            Divider()
            
            // Auto-off timer
            AutoOffTimer(device: device, manager: manager)
            
            // Create custom scene button
            Button(action: { showingSceneCreator = true }) {
                Label("Create Custom Scene", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical)
        .sheet(isPresented: $showingSceneCreator) {
            SceneCreator(device: device, manager: manager)
        }
    }
}

struct ScenePreset: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let scene: YeelightManager.Scene
}

struct SceneButton: View {
    let preset: ScenePreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: preset.icon)
                    .font(.system(size: 24))
                Text(preset.name)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AutoOffTimer: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    
    @State private var isEnabled = false
    @State private var minutes: Double = 30
    
    let timePresets = [15, 30, 45, 60, 90, 120]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Auto-Off Timer", isOn: $isEnabled)
                .onChange(of: isEnabled) { newValue in
                    if newValue {
                        manager.setScene(device, scene: .autoDelayOff(
                            brightness: device.brightness,
                            minutes: Int(minutes)
                        ))
                    }
                }
            
            if isEnabled {
                VStack(spacing: 8) {
                    HStack {
                        Text("Turn off after")
                        Spacer()
                        Text("\(Int(minutes)) minutes")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: $minutes, in: 1...120) { changed in
                        if changed && isEnabled {
                            manager.setScene(device, scene: .autoDelayOff(
                                brightness: device.brightness,
                                minutes: Int(minutes)
                            ))
                        }
                    }
                    
                    // Quick time presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(timePresets, id: \.self) { preset in
                                Button("\(preset)m") {
                                    minutes = Double(preset)
                                    if isEnabled {
                                        manager.setScene(device, scene: .autoDelayOff(
                                            brightness: device.brightness,
                                            minutes: preset
                                        ))
                                    }
                                }
                                .buttonStyle(.bordered)
                                .tint(minutes == Double(preset) ? .accentColor : .secondary)
                            }
                        }
                    }
                }
                .padding(.leading)
            }
        }
    }
} 