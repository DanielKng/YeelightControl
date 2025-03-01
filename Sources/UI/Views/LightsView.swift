import SwiftUI
import Core

struct LightsView: View {
    @EnvironmentObject private var deviceManager: ObservableDeviceManager
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
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
                DeviceRow(device: device) {
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
            AddDeviceView()
        }
        .sheet(item: $selectedDevice) { device in
            DeviceDetailView(device: device)
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

// MARK: - Preview

#Preview {
    NavigationView {
        LightsView()
            .environmentObject(ServiceContainer.shared.observableDeviceManager)
            .environmentObject(ServiceContainer.shared.observableYeelightManager)
    }
} 