import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var groupManager: DeviceGroupManager
    @ObservedObject var deviceManager: YeelightManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var groupName = ""
    @State private var selectedIcon = "lightbulb.fill"
    @State private var selectedDevices: Set<String> = []
    @State private var syncMode: DeviceGroupManager.DeviceGroup.SyncMode = .mirror
    
    let icons = [
        "lightbulb.fill",
        "lightbulb.2.fill",
        "lamp.desk.fill",
        "lamp.floor.fill",
        "light.recessed",
        "light.strip.2",
        "sparkles",
        "wand.and.stars",
        "party.popper.fill",
        "theatermasks.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Group Details") {
                    TextField("Group Name", text: $groupName)
                    
                    Picker("Sync Mode", selection: $syncMode) {
                        Text("Mirror").tag(DeviceGroupManager.DeviceGroup.SyncMode.mirror)
                        Text("Alternate").tag(DeviceGroupManager.DeviceGroup.SyncMode.alternate)
                        Text("Wave").tag(DeviceGroupManager.DeviceGroup.SyncMode.wave)
                        Text("Random").tag(DeviceGroupManager.DeviceGroup.SyncMode.random)
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 20) {
                        ForEach(icons, id: \.self) { icon in
                            IconButton(
                                icon: icon,
                                isSelected: selectedIcon == icon,
                                action: { selectedIcon = icon }
                            )
                        }
                    }
                    .padding(.vertical)
                }
                
                Section("Devices") {
                    ForEach(deviceManager.devices) { device in
                        HStack {
                            Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                                .foregroundStyle(device.isOn ? .orange : .secondary)
                            
                            VStack(alignment: .leading) {
                                Text(device.name)
                                Text(device.ip)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { selectedDevices.contains(device.ip) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedDevices.insert(device.ip)
                                    } else {
                                        selectedDevices.remove(device.ip)
                                    }
                                }
                            ))
                            .labelsHidden()
                        }
                    }
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGroup()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !groupName.isEmpty && selectedDevices.count >= 2
    }
    
    private func createGroup() {
        let devices = deviceManager.devices.filter { selectedDevices.contains($0.ip) }
        groupManager.createGroup(
            name: groupName,
            icon: selectedIcon,
            devices: devices,
            syncMode: syncMode
        )
    }
} 