import SwiftUI

struct GroupManagementView: View {
    @ObservedObject var groupManager: DeviceGroupManager
    @ObservedObject var deviceManager: YeelightManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCreateGroup = false
    @State private var selectedGroup: DeviceGroup?
    
    var body: some View {
        NavigationStack {
            UnifiedListView(
                title: "Device Groups",
                items: groupManager.groups,
                emptyStateMessage: "No device groups created yet",
                onDelete: { group in
                    Task {
                        try await groupManager.deleteGroup(group.id)
                    }
                }
            ) { group in
                GroupRow(group: group, deviceManager: deviceManager, groupManager: groupManager)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedGroup = group
                    }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGroup = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                GroupEditorView(groupManager: groupManager, deviceManager: deviceManager)
            }
            .sheet(item: $selectedGroup) { group in
                GroupEditorView(groupManager: groupManager, deviceManager: deviceManager, group: group)
            }
        }
    }
}

struct GroupRow: View {
    let group: DeviceGroup
    let deviceManager: YeelightManager
    let groupManager: DeviceGroupManager
    
    @State private var isExpanded = false
    @State private var showingEffects = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Device list
                ForEach(deviceManager.devices.filter { group.deviceIPs.contains($0.ip) }) { device in
                    Circle()
                        .fill(device.isOn ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                }
                
                // Quick actions
                Spacer()
                
                Button {
                    Task { try await groupManager.turnOnAll(group.id) }
                } label: {
                    Label("All On", systemImage: "lightbulb.fill")
                        .labelStyle(.iconOnly)
                }
                
                Button {
                    Task { try await groupManager.turnOffAll(group.id) }
                } label: {
                    Label("All Off", systemImage: "lightbulb.slash")
                        .labelStyle(.iconOnly)
                }
                
                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(deviceManager.devices.filter { group.deviceIPs.contains($0.ip) }) { device in
                        Text(device.name)
                            .font(.caption)
                    }
                }
                .padding(.leading)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut, value: isExpanded)
    }
} 