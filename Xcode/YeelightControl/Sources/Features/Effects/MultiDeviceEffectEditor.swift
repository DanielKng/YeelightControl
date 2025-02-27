import SwiftUI

struct MultiDeviceEffectEditor: View {
    let devices: [YeelightDevice]
    @State private var effectType: EffectType = .wave
    @State private var speed: Double = 1000
    @State private var colorScheme: ColorScheme = .rainbow
    @State private var customColors: [Color] = [.red, .blue]
    
    enum EffectType {
        case wave, chase, alternate, sync
        
        var name: String {
            switch self {
            case .wave: return "Wave"
            case .chase: return "Chase"
            case .alternate: return "Alternate"
            case .sync: return "Synchronized"
            }
        }
    }
    
    enum ColorScheme {
        case rainbow, custom, temperature
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Effect Type", selection: $effectType) {
                    Text("Wave").tag(EffectType.wave)
                    Text("Chase").tag(EffectType.chase)
                    Text("Alternate").tag(EffectType.alternate)
                    Text("Synchronized").tag(EffectType.sync)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Speed")
                        Spacer()
                        Text("\(Int(speed))ms")
                    }
                    Slider(value: $speed, in: 100...5000)
                }
            }
            
            Section("Colors") {
                Picker("Color Scheme", selection: $colorScheme) {
                    Text("Rainbow").tag(ColorScheme.rainbow)
                    Text("Custom").tag(ColorScheme.custom)
                    Text("Temperature").tag(ColorScheme.temperature)
                }
                
                if colorScheme == .custom {
                    ForEach(customColors.indices, id: \.self) { index in
                        ColorPicker("Color \(index + 1)", selection: $customColors[index])
                    }
                    .onDelete { customColors.remove(atOffsets: $0) }
                    
                    if customColors.count < 5 {
                        Button("Add Color") {
                            customColors.append(.white)
                        }
                    }
                }
            }
            
            Section("Preview") {
                VStack(spacing: 16) {
                    ForEach(devices) { device in
                        DeviceEffectPreview(device: device)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Multi-Device Effect")
    }
}

struct DeviceEffectPreview: View {
    let device: YeelightDevice
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.title)
                .foregroundStyle(.yellow)
            
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                Text(device.ip)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Preview indicator
            Circle()
                .fill(.orange)
                .frame(width: 12, height: 12)
        }
    }
} 