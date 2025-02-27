import SwiftUI

struct DeviceCard: View {
    @ObservedObject var device: YeelightDevice
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    var body: some View {
        VStack(spacing: 16) {
            // Device icon
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 40))
                .foregroundStyle(device.isOn ? .orange : .gray)
                .accessibilityHidden(true)
            
            // Device name and status
            VStack(spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(device.isOn ? "On" : "Off")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(device.name), currently \(device.isOn ? "on" : "off")")
            
            // Brightness slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Brightness")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Slider(
                    value: Binding(
                        get: { Double(device.brightness) },
                        set: { device.brightness = Int($0) }
                    ),
                    in: 1...100,
                    step: 1
                )
                .accessibilityValue("\(device.brightness) percent")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment:
                        device.brightness = min(device.brightness + 5, 100)
                    case .decrement:
                        device.brightness = max(device.brightness - 5, 1)
                    @unknown default:
                        break
                    }
                }
            }
        }
        .padding()
        .background(
            reduceTransparency ? 
                Color(.systemBackground) :
                Color(.systemBackground).opacity(0.8)
        )
        .cornerRadius(12)
        .shadow(radius: 5)
        .animation(
            reduceMotion ? nil : .easeInOut,
            value: device.isOn
        )
        .accessibilityAction(named: "Toggle Light") {
            device.isOn.toggle()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Light Control")
        .accessibilityHint("Adjust brightness using slider. Double tap to toggle light.")
    }
} 