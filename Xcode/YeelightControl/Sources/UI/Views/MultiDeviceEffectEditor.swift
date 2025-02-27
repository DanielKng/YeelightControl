import SwiftUI

struct MultiDeviceEffectEditor: View {
    let devices: [YeelightDevice]
    @State private var selectedEffect: MultiDeviceEffect = .alternate
    @State private var colors: [Color] = [.red, .blue]
    @State private var transitionDuration: Double = 1000
    @State private var brightness: Double = 100
    @State private var colorTemp: Double = 4000
    @State private var showingColorPicker = false
    @State private var editingColorIndex: Int?
    
    enum MultiDeviceEffect: String, CaseIterable {
        case alternate = "Alternate"
        case wave = "Wave"
        case ripple = "Ripple"
        case random = "Random"
        
        var description: String {
            switch self {
            case .alternate:
                return "Devices alternate between colors"
            case .wave:
                return "Colors flow through devices in sequence"
            case .ripple:
                return "Effect ripples outward from center"
            case .random:
                return "Random color patterns"
            }
        }
        
        var icon: String {
            switch self {
            case .alternate: return "arrow.left.arrow.right"
            case .wave: return "waveform"
            case .ripple: return "circle.circle"
            case .random: return "dice"
            }
        }
    }
    
    var body: some View {
        Form {
            Section("Effect Type") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(MultiDeviceEffect.allCases, id: \.rawValue) { effect in
                            VStack {
                                Image(systemName: effect.icon)
                                    .font(.title2)
                                Text(effect.rawValue)
                                    .font(.caption)
                                Text(effect.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 100)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedEffect == effect ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                            )
                            .onTapGesture {
                                selectedEffect = effect
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .listRowInsets(EdgeInsets())
            }
            
            Section("Colors") {
                ForEach(colors.indices, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(colors[index])
                            .frame(width: 24, height: 24)
                        
                        Text("Color \(index + 1)")
                        
                        Spacer()
                        
                        Button {
                            editingColorIndex = index
                            showingColorPicker = true
                        } label: {
                            Image(systemName: "eyedropper")
                        }
                    }
                }
                .onDelete { indexSet in
                    colors.remove(atOffsets: indexSet)
                }
                
                if colors.count < 5 {
                    Button("Add Color") {
                        colors.append(.white)
                    }
                }
            }
            
            Section("Timing") {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Transition")
                        Spacer()
                        Text("\(Int(transitionDuration))ms")
                    }
                    Slider(value: $transitionDuration, in: 100...5000)
                }
            }
            
            Section("Preview") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Device Order:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(devices) { device in
                                VStack {
                                    Circle()
                                        .stroke(Color.secondary)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text("\(devices.firstIndex(of: device)! + 1)")
                                        )
                                    Text(device.name)
                                        .font(.caption)
                                }
                                .frame(width: 80)
                            }
                        }
                    }
                }
            }
            
            Section {
                Button("Preview Effect") {
                    previewEffect()
                }
            }
        }
        .navigationTitle("Multi-Device Effect")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingColorPicker) {
            if let index = editingColorIndex {
                ColorPickerView(color: $colors[index])
            }
        }
    }
    
    private func previewEffect() {
        let deviceManager = YeelightManager.shared
        
        switch selectedEffect {
        case .alternate:
            for (index, device) in devices.enumerated() {
                let colorIndex = index % colors.count
                let components = UIColor(colors[colorIndex]).cgColor.components ?? [1, 1, 1, 1]
                let scene = YeelightManager.Scene.color(
                    red: Int(components[0] * 255),
                    green: Int(components[1] * 255),
                    blue: Int(components[2] * 255),
                    brightness: Int(brightness)
                )
                deviceManager.setScene(device, scene: scene)
            }
            
        case .wave:
            for (index, device) in devices.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * (transitionDuration / 1000)) {
                    let colorIndex = index % colors.count
                    let components = UIColor(colors[colorIndex]).cgColor.components ?? [1, 1, 1, 1]
                    let scene = YeelightManager.Scene.color(
                        red: Int(components[0] * 255),
                        green: Int(components[1] * 255),
                        blue: Int(components[2] * 255),
                        brightness: Int(brightness)
                    )
                    deviceManager.setScene(device, scene: scene)
                }
            }
            
        case .ripple:
            let center = devices.count / 2
            for (index, device) in devices.enumerated() {
                let distance = abs(index - center)
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(distance) * (transitionDuration / 1000)) {
                    let colorIndex = distance % colors.count
                    let components = UIColor(colors[colorIndex]).cgColor.components ?? [1, 1, 1, 1]
                    let scene = YeelightManager.Scene.color(
                        red: Int(components[0] * 255),
                        green: Int(components[1] * 255),
                        blue: Int(components[2] * 255),
                        brightness: Int(brightness)
                    )
                    deviceManager.setScene(device, scene: scene)
                }
            }
            
        case .random:
            for device in devices {
                let colorIndex = Int.random(in: 0..<colors.count)
                let components = UIColor(colors[colorIndex]).cgColor.components ?? [1, 1, 1, 1]
                let scene = YeelightManager.Scene.color(
                    red: Int(components[0] * 255),
                    green: Int(components[1] * 255),
                    blue: Int(components[2] * 255),
                    brightness: Int(brightness)
                )
                deviceManager.setScene(device, scene: scene)
            }
        }
    }
}

struct ColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var color: Color
    
    var body: some View {
        NavigationStack {
            ColorPicker("Select Color", selection: $color)
                .padding()
                .navigationTitle("Color Picker")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
} 