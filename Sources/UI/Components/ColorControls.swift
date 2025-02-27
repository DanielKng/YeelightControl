import SwiftUI

struct ColorControls: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    
    @State private var colorMode: ColorMode = .rgb
    @State private var selectedColor = Color.white
    @State private var hue: Double = 0
    @State private var saturation: Double = 0
    
    enum ColorMode {
        case rgb, hsv
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Color mode selector
            Picker("Color Mode", selection: $colorMode) {
                Text("RGB").tag(ColorMode.rgb)
                Text("HSV").tag(ColorMode.hsv)
            }
            .pickerStyle(.segmented)
            
            if colorMode == .rgb {
                // RGB Color Picker
                VStack(alignment: .leading, spacing: 8) {
                    Label("Color", systemImage: "paintpalette.fill")
                        .foregroundStyle(.secondary)
                    
                    ColorPicker("Select Color", selection: $selectedColor)
                        .labelsHidden()
                        .onChange(of: selectedColor) { newValue in
                            let components = UIColor(newValue).cgColor.components ?? [1, 1, 1, 1]
                            manager.setRGB(
                                device,
                                red: Int(components[0] * 255),
                                green: Int(components[1] * 255),
                                blue: Int(components[2] * 255)
                            )
                        }
                }
            } else {
                // HSV Controls
                VStack(spacing: 16) {
                    // Hue control
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Hue", systemImage: "circle.fill")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(hue))°")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $hue, in: 0...359) { changed in
                            if changed {
                                manager.setHSV(device, hue: Int(hue), saturation: Int(saturation))
                            }
                        }
                    }
                    
                    // Saturation control
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Saturation", systemImage: "drop.fill")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(saturation))%")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $saturation, in: 0...100) { changed in
                            if changed {
                                manager.setHSV(device, hue: Int(hue), saturation: Int(saturation))
                            }
                        }
                    }
                }
            }
            
            // Quick color presets
            ColorPresets(device: device, manager: manager)
        }
        .padding(.vertical)
    }
}

struct ColorPresets: View {
    let device: YeelightDevice
    let manager: YeelightManager
    
    let presets: [(name: String, color: Color)] = [
        ("Warm White", .init(red: 1, green: 0.9, blue: 0.7)),
        ("Cool White", .init(red: 0.95, green: 0.95, blue: 1)),
        ("Red", .red),
        ("Green", .green),
        ("Blue", .blue),
        ("Purple", .purple),
        ("Orange", .orange),
        ("Pink", .pink)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Quick Colors", systemImage: "circle.grid.3x3.fill")
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 60), spacing: 12)
            ], spacing: 12) {
                ForEach(presets, id: \.name) { preset in
                    Button {
                        applyPreset(preset.color)
                    } label: {
                        Circle()
                            .fill(preset.color)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Color.secondary.opacity(0.2)))
                    }
                }
            }
        }
    }
    
    private func applyPreset(_ color: Color) {
        let components = UIColor(color).cgColor.components ?? [1, 1, 1, 1]
        manager.setRGB(
            device,
            red: Int(components[0] * 255),
            green: Int(components[1] * 255),
            blue: Int(components[2] * 255)
        )
    }
} 