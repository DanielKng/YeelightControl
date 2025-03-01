import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var yeelightManager: YeelightManager

    @State private var groupName = ""
    @State private var selectedDevices: Set<Device> = []
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Group name input
                UnifiedTextField(
                    text: $groupName,
                    placeholder: "Group Name",
                    icon: "tag",
                    clearButton: true
                )
                .padding(.horizontal)

                // Device selection
                UnifiedListView(
                    title: "Select Devices",
                    items: Array(yeelightManager.devices),
                    emptyStateMessage: "No devices found"
                ) { device in
                    DeviceSelectionRow(
                        device: device,
                        isSelected: selectedDevices.contains(device)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedDevices.contains(device) {
                            selectedDevices.remove(device)
                        } else {
                            selectedDevices.insert(device)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(groupName.isEmpty || selectedDevices.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createGroup() {
        do {
            try yeelightManager.createGroup(name: groupName, devices: Array(selectedDevices))
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct DeviceSelectionRow: View {
    let device: Device
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(device.isOn ? .yellow : .gray)

            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                Text(device.ipAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CreateGroupView()
        .environmentObject(YeelightManager.shared)
} 