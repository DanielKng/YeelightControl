import SwiftUI
import Core

// MARK: - FilterChip

/// A reusable filter chip component
public struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    public init(
        title: String,
        isSelected: Bool,
        color: Color = .accentColor,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? color : .primary)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? color : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DeviceChip

/// A reusable device chip component
public struct DeviceChip: View {
    let deviceID: DeviceID
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
    
    public init(deviceID: DeviceID) {
        self.deviceID = deviceID
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.orange)
                .frame(width: 8, height: 8)
            
            Text(deviceName)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var deviceName: String {
        if let device = yeelightManager.devices.first(where: { $0.id == deviceID }) {
            return device.name
        } else {
            return "Unknown"
        }
    }
}

// MARK: - ConnectionStatusView

/// A reusable connection status view
public struct ConnectionStatusView: View {
    let isConnected: Bool
    let lastSeen: Date?
    
    public init(isConnected: Bool, lastSeen: Date? = nil) {
        self.isConnected = isConnected
        self.lastSeen = lastSeen
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let lastSeen = lastSeen, !isConnected {
                Text("• Last seen \(timeAgo(lastSeen))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - StatusRow

/// A reusable status row component
public struct StatusRow: View {
    let title: String
    let value: String
    let icon: String
    let status: Status
    
    public enum Status {
        case success, warning, error, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }
    }
    
    public init(title: String, value: String, icon: String, status: Status = .info) {
        self.title = title
        self.value = value
        self.icon = icon
        self.status = status
    }
    
    public var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(status.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - DeviceRow

/// A reusable device row component
public struct DeviceRow: View {
    let device: YeelightDevice
    let action: () -> Void
    
    public init(device: YeelightDevice, action: @escaping () -> Void) {
        self.device = device
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                    
                    ConnectionStatusView(isConnected: device.isConnected)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - StatusSection

/// A reusable status section component
public struct StatusSection<Content: View>: View {
    let title: String
    let content: Content
    
    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - EnhancedDeviceSelectionList

/// A reusable device selection list component
public struct EnhancedDeviceSelectionList: View {
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
    @Binding var selectedDevices: Set<DeviceID>
    
    public init(selectedDevices: Binding<Set<DeviceID>>) {
        self._selectedDevices = selectedDevices
    }
    
    public var body: some View {
        List {
            ForEach(yeelightManager.devices) { device in
                Button(action: {
                    toggleDevice(device.id)
                }) {
                    HStack {
                        Text(device.name)
                        Spacer()
                        if selectedDevices.contains(device.id) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func toggleDevice(_ deviceID: DeviceID) {
        if selectedDevices.contains(deviceID) {
            selectedDevices.remove(deviceID)
        } else {
            selectedDevices.insert(deviceID)
        }
    }
} 