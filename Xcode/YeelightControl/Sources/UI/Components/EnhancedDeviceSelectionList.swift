import SwiftUI

struct EnhancedDeviceSelectionList: View {
    @ObservedObject private var manager = YeelightManager.shared
    @Binding var selectedDevices: Set<String>
    
    @State private var searchText = ""
    @State private var filterStatus: FilterStatus = .all
    @State private var groupByRoom = true
    
    enum FilterStatus: String, CaseIterable {
        case all = "All"
        case online = "Online"
        case offline = "Offline"
    }
    
    var body: some View {
        VStack {
            // Search and filter bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search devices", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal)
            
            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(FilterStatus.allCases, id: \.self) { status in
                        FilterPill(
                            title: status.rawValue,
                            isSelected: status == filterStatus,
                            action: { filterStatus = status }
                        )
                    }
                    
                    FilterPill(
                        title: "Group by Room",
                        isSelected: groupByRoom,
                        action: { groupByRoom.toggle() }
                    )
                }
                .padding(.horizontal)
            }
            
            // Device list
            if groupByRoom {
                GroupedDeviceList(
                    devices: filteredDevices,
                    selectedDevices: $selectedDevices
                )
            } else {
                FlatDeviceList(
                    devices: filteredDevices,
                    selectedDevices: $selectedDevices
                )
            }
        }
        .overlay {
            if manager.devices.isEmpty {
                ContentUnavailableView(
                    "No Devices Found",
                    systemImage: "lightbulb.slash",
                    description: Text("Add devices to create automations")
                )
            }
        }
    }
    
    private var filteredDevices: [YeelightDevice] {
        var devices = manager.devices
        
        // Apply status filter
        if filterStatus != .all {
            devices = devices.filter { device in
                switch filterStatus {
                case .online:
                    return device.connectionState == .connected
                case .offline:
                    return device.connectionState != .connected
                case .all:
                    return true
                }
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            devices = devices.filter { device in
                device.name.localizedCaseInsensitiveContains(searchText) ||
                device.ip.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return devices
    }
}

struct GroupedDeviceList: View {
    let devices: [YeelightDevice]
    @Binding var selectedDevices: Set<String>
    @ObservedObject private var roomManager = RoomManager.shared
    
    var body: some View {
        List {
            ForEach(roomManager.rooms) { room in
                let roomDevices = devices.filter { device in
                    room.deviceIPs.contains(device.ip)
                }
                
                if !roomDevices.isEmpty {
                    Section(room.name) {
                        ForEach(roomDevices) { device in
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
            }
            
            // Unassigned devices
            let unassignedDevices = devices.filter { device in
                !roomManager.rooms.contains { room in
                    room.deviceIPs.contains(device.ip)
                }
            }
            
            if !unassignedDevices.isEmpty {
                Section("Unassigned") {
                    ForEach(unassignedDevices) { device in
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
        }
    }
}

struct DeviceSelectionRow: View {
    let device: YeelightDevice
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                .foregroundStyle(device.isOn ? .orange : .secondary)
            
            VStack(alignment: .leading) {
                Text(device.name)
                HStack {
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
            .fill(state == .connected ? .green : .red)
            .frame(width: 8, height: 8)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? .orange : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
} 