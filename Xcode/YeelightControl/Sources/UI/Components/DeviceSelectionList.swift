import SwiftUI

struct DeviceSelectionList: View {
    @ObservedObject private var manager = YeelightManager.shared
    @Binding var selectedDevices: Set<String>
    
    var body: some View {
        ForEach(manager.devices) { device in
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
        
        if manager.devices.isEmpty {
            ContentUnavailableView(
                "No Devices Found",
                systemImage: "lightbulb.slash",
                description: Text("Add devices to create automations")
            )
        }
    }
}

// Preview for device selection
struct DeviceSelectionList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            Form {
                DeviceSelectionList(selectedDevices: .constant([]))
            }
        }
    }
} 