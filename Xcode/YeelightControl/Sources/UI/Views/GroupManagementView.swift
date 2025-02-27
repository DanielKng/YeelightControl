import SwiftUI

struct GroupManagementView: View {
    @ObservedObject var groupManager: DeviceGroupManager
    @ObservedObject var deviceManager: YeelightManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCreateGroup = false
    @State private var selectedGroup: DeviceGroup?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupManager.groups) { group in
                    GroupRow(
                        group: group,
                        deviceManager: deviceManager,
                        groupManager: groupManager
                    )
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        groupManager.deleteGroup(groupManager.groups[index])
                    }
                }
            }
            .navigationTitle("Device Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGroup = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView(
                    groupManager: groupManager,
                    deviceManager: deviceManager
                )
            }
        }
    }
}

struct GroupRow: View {
    let group: DeviceGroupManager.DeviceGroup
    let deviceManager: YeelightManager
    let groupManager: DeviceGroupManager
    
    @State private var isExpanded = false
    @State private var showingEffects = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 16) {
                // Device list
                ForEach(deviceManager.devices.filter { group.deviceIPs.contains($0.ip) }) { device in
                    DeviceRow(device: device)
                }
                
                // Quick actions
                HStack {
                    Button(action: { toggleGroup(on: true) }) {
                        Label("All On", systemImage: "lightbulb.fill")
                    }
                    
                    Spacer()
                    
                    Button(action: { toggleGroup(on: false) }) {
                        Label("All Off", systemImage: "lightbulb.slash")
                    }
                    
                    Spacer()
                    
                    Button(action: { showingEffects = true }) {
                        Label("Effects", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical)
        } label: {
            HStack {
                Image(systemName: group.icon)
                    .foregroundStyle(.orange)
                Text(group.name)
                Spacer()
                Text("\(group.deviceIPs.count) devices")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .sheet(isPresented: $showingEffects) {
            GroupEffectsView(
                group: group,
                deviceManager: deviceManager,
                groupManager: groupManager
            )
        }
    }
    
    private func toggleGroup(on: Bool) {
        groupManager.setGroupPower(group, on: on, using: deviceManager)
    }
} 