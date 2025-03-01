import SwiftUI
import Core

struct LightsView: View {
    @ObservedObject var deviceManager: UnifiedDeviceManager
    @EnvironmentObject private var yeelightManager: UnifiedYeelightManager
    @State private var searchText = ""
    @State private var showingAddDevice = false
    @State private var selectedDevice: YeelightDevice?
    @State private var isRefreshing = false
    
    var body: some View {
        List {
            if deviceManager.isDiscovering {
                HStack {
                    ProgressView()
                        .padding(.trailing, 8)
                    Text("Searching for devices...")
                }
            }
            
            ForEach(filteredDevices) { device in
                DeviceRow(device: device)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDevice = device
                    }
            }
        }
        .navigationTitle("Lights")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddDevice = true
                }) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: refreshDevices) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(deviceManager.isDiscovering)
            }
        }
        .searchable(text: $searchText, prompt: "Search devices")
        .refreshable {
            await refreshDevicesAsync()
        }
        .sheet(isPresented: $showingAddDevice) {
            AddDeviceView(deviceManager: deviceManager)
                .environmentObject(yeelightManager)
        }
        .sheet(item: $selectedDevice) { device in
            DeviceDetailView(device: device)
                .environmentObject(yeelightManager)
        }
        .overlay {
            if yeelightManager.devices.isEmpty && !deviceManager.isDiscovering {
                ContentUnavailableView(
                    "No Devices Found",
                    systemImage: "lightbulb.slash",
                    description: Text("Add a device using the + button or pull down to refresh")
                )
            }
        }
    }
    
    private var filteredDevices: [YeelightDevice] {
        if searchText.isEmpty {
            return yeelightManager.devices
        } else {
            return yeelightManager.devices.filter { device in
                device.name.localizedCaseInsensitiveContains(searchText) ||
                device.id.localizedCaseInsensitiveContains(searchText) ||
                device.ipAddress.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func refreshDevices() {
        Task {
            try? await yeelightManager.discover()
        }
    }
    
    private func refreshDevicesAsync() async {
        isRefreshing = true
        try? await yeelightManager.discover()
        // Wait for discovery to complete or timeout
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        isRefreshing = false
    }
}

// MARK: - Supporting Views

struct DeviceRow: View {
    @ObservedObject var device: YeelightDevice
    @EnvironmentObject private var yeelightManager: UnifiedYeelightManager
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(device.isPoweredOn ? .yellow : .gray)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                
                Text(device.model)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(device.isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(device.isConnected ? .green : .red)
                
                Text(device.ipAddress)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                togglePower()
            }) {
                Image(systemName: device.isPoweredOn ? "power" : "power")
                    .foregroundColor(device.isPoweredOn ? .green : .gray)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private func togglePower() {
        Task {
            var updatedDevice = device
            updatedDevice.isPoweredOn.toggle()
            try? await yeelightManager.updateDevice(updatedDevice)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        LightsView(deviceManager: ServiceContainer.shared.deviceManager)
            .environmentObject(ServiceContainer.shared.yeelightManager)
    }
} 