import SwiftUI

// MARK: - Status Indicators
struct StatusIndicator: View {
    let state: YeelightDevice.ConnectionState
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }
    
    private var statusColor: Color {
        switch state {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
}

// MARK: - Color Components
struct ColorPreview: View {
    let color: Color
    let size: CGFloat
    
    init(color: Color, size: CGFloat = 100) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(.white, lineWidth: 2)
            }
    }
}

struct ColorButton: View {
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    init(color: Color, size: CGFloat = 30, action: @escaping () -> Void) {
        self.color = color
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                }
        }
    }
}

// MARK: - Device Components
struct DevicePreviewCard: View {
    let device: YeelightDevice
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            
            Text(device.name)
                .font(.caption)
                .lineLimit(1)
            
            StatusIndicator(state: device.connectionState)
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Color Utilities
extension Color {
    var components: (red: Int, green: Int, blue: Int) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (
            red: Int(red * 255),
            green: Int(green * 255),
            blue: Int(blue * 255)
        )
    }
    
    init(red: Int, green: Int, blue: Int) {
        self.init(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}

// MARK: - Search Components
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void
    
    init(
        text: Binding<String>,
        placeholder: String = "Search",
        onSubmit: @escaping () -> Void
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit(onSubmit)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Audio Visualization
struct AudioLevelMeter: View {
    let amplitude: Float
    let barCount: Int
    let barSpacing: CGFloat
    
    init(
        amplitude: Float,
        barCount: Int = 30,
        barSpacing: CGFloat = 2
    ) {
        self.amplitude = amplitude
        self.barCount = barCount
        self.barSpacing = barSpacing
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: barSpacing) {
                ForEach(0..<barCount) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(
                            width: (geometry.size.width - CGFloat(barCount - 1) * barSpacing) / CGFloat(barCount),
                            height: barHeight(for: index, in: geometry)
                        )
                }
            }
        }
    }
    
    private func barHeight(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        let threshold = Float(index) / Float(barCount)
        let height = amplitude > threshold ?
            CGFloat(amplitude - threshold) * geometry.size.height :
            0
        return max(3, min(height, geometry.size.height))
    }
    
    private func barColor(for index: Int) -> Color {
        let threshold = Float(index) / Float(barCount)
        if amplitude > threshold {
            return .orange
        } else {
            return .secondary.opacity(0.2)
        }
    }
} 