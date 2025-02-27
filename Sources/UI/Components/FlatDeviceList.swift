import SwiftUI

struct FlatDeviceList: View {
    let devices: [YeelightDevice]
    @Binding var selectedDevices: Set<String>
    @State private var sortOrder = SortOrder.name
    
    enum SortOrder {
        case name, status, room
        
        var description: String {
            switch self {
            case .name: return "Name"
            case .status: return "Status"
            case .room: return "Room"
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                Picker("Sort By", selection: $sortOrder) {
                    Text("Name").tag(SortOrder.name)
                    Text("Status").tag(SortOrder.status)
                    Text("Room").tag(SortOrder.room)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
            }
            
            ForEach(sortedDevices) { device in
                DeviceSelectionRow(
                    device: device,
                    isSelected: selectedDevices.contains(device.ip),
                    onToggle: { isSelected in
                        if isSelected {
                            selectedDevices.insert(device.ip)
                        } else {
                            selectedDevices.remove(device.ip)
                        }
                    }
                )
            }
        }
    }
    
    private var sortedDevices: [YeelightDevice] {
        switch sortOrder {
        case .name:
            return devices.sorted { $0.name < $1.name }
        case .status:
            return devices.sorted { device1, device2 in
                if device1.connectionState == .connected && device2.connectionState != .connected {
                    return true
                }
                if device1.connectionState != .connected && device2.connectionState == .connected {
                    return false
                }
                return device1.name < device2.name
            }
        case .room:
            let roomManager = RoomManager.shared
            return devices.sorted { device1, device2 in
                let room1 = roomManager.rooms.first { $0.deviceIPs.contains(device1.ip) }?.name ?? ""
                let room2 = roomManager.rooms.first { $0.deviceIPs.contains(device2.ip) }?.name ?? ""
                if room1 == room2 {
                    return device1.name < device2.name
                }
                return room1 < room2
            }
        }
    }
}

struct DeviceSelectionRow: View {
    let device: YeelightDevice
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    @ObservedObject private var roomManager = RoomManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                .foregroundStyle(device.isOn ? .orange : .secondary)
            
            VStack(alignment: .leading) {
                Text(device.name)
                HStack {
                    if let room = roomManager.rooms.first(where: { $0.deviceIPs.contains(device.ip) }) {
                        Label(room.name, systemImage: room.icon)
                    }
                    Text(device.ip)
                    StatusIndicator(state: device.connectionState)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: onToggle
            ))
            .labelsHidden()
        }
    }
}

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