import SwiftUI

struct BasicControls: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    
    @State private var brightness: Double
    @State private var colorTemp: Double
    
    init(device: YeelightDevice, manager: YeelightManager) {
        self.device = device
        self.manager = manager
        _brightness = State(initialValue: Double(device.brightness))
        _colorTemp = State(initialValue: Double(device.colorTemperature))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Brightness control
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Brightness", systemImage: "sun.max.fill")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(brightness))%")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $brightness, in: 1...100) { changed in
                    if changed {
                        manager.setBrightness(device, brightness: Int(brightness))
                    }
                }
            }
            
            // Color temperature control
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Color Temperature", systemImage: "thermometer.sun.fill")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(colorTemp))K")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $colorTemp, in: 1700...6500) { changed in
                    if changed {
                        manager.setColorTemperature(device, temperature: Int(colorTemp))
                    }
                }
                
                HStack {
                    Text("Warm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Cool")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Power mode selector
            VStack(alignment: .leading, spacing: 8) {
                Label("Power Mode", systemImage: "bolt.fill")
                    .foregroundStyle(.secondary)
                
                Picker("Power Mode", selection: Binding(
                    get: { device.powerMode },
                    set: { newMode in
                        device.powerMode = newMode
                        // Reapply current power state with new mode
                        manager.setPower(device, on: device.isOn)
                    }
                )) {
                    Text("Normal").tag(YeelightDevice.PowerMode.normal)
                    Text("CT").tag(YeelightDevice.PowerMode.ct)
                    Text("RGB").tag(YeelightDevice.PowerMode.rgb)
                    Text("HSV").tag(YeelightDevice.PowerMode.hsv)
                    Text("Color Flow").tag(YeelightDevice.PowerMode.colorFlow)
                    Text("Night Light").tag(YeelightDevice.PowerMode.nightLight)
                }
                .pickerStyle(.menu)
            }
        }
        .padding(.vertical)
    }
} 