import SwiftUI

struct DeviceRow: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack {
                Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                    .imageScale(.large)
                    .foregroundStyle(device.isOn ? .yellow : .secondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Light")
                        .font(.headline)
                    Text(device.ip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                BrightnessIndicator(brightness: device.brightness)
                    .frame(width: 24, height: 24)
            }
            .contentShape(Rectangle())
        }
        .sheet(isPresented: $showingDetail) {
            DeviceDetailView(device: device, manager: manager)
        }
    }
}

struct BrightnessIndicator: View {
    let brightness: Int
    
    var body: some View {
        Circle()
            .trim(from: 0, to: Double(brightness) / 100)
            .stroke(
                Color.accentColor.opacity(0.3),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
    }
} 