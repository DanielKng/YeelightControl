import SwiftUI
import Core

struct DeviceDiscoveryView: View {
    // MARK: - Properties
    
    @EnvironmentObject var deviceManager: ObservableDeviceManager
    @EnvironmentObject var yeelightManager: ObservableYeelightManager
    
    @State private var isDiscovering = false
    @State private var discoveredDevices: [YeelightDevice] = []
    @State private var selectedDevice: YeelightDevice?
    @State private var showAddDeviceSheet = false
    @State private var errorMessage: String?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Discover Devices")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: toggleDiscovery) {
                    Image(systemName: isDiscovering ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(isDiscovering ? .red : .green)
                }
            }
            .padding(.horizontal)
            
            // Discovery status
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(isDiscovering ? .blue : .gray)
                    .font(.title2)
                
                Text(isDiscovering ? "Searching for devices..." : "Discovery stopped")
                    .foregroundColor(isDiscovering ? .primary : .secondary)
                
                Spacer()
                
                if isDiscovering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            
            // Device list
            List {
                ForEach(discoveredDevices) { device in
                    DeviceDiscoveryRow(device: device)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDevice = device
                            showAddDeviceSheet = true
                        }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .overlay(
                Group {
                    if discoveredDevices.isEmpty {
                        VStack {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text(isDiscovering ? "Searching for devices..." : "No devices found")
                                .foregroundColor(.secondary)
                                .padding(.top)
                            
                            if !isDiscovering {
                                Button("Start Discovery") {
                                    startDiscovery()
                                }
                                .padding(.top)
                            }
                        }
                    }
                }
            )
            
            // Instructions
            VStack(alignment: .leading, spacing: 10) {
                Text("Instructions")
                    .font(.headline)
                
                Text("1. Make sure your Yeelight devices are on the same network")
                Text("2. Enable LAN Control in the Yeelight app settings")
                Text("3. Tap the button above to start discovery")
                Text("4. Tap on a device to add it to your account")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .padding()
        .sheet(isPresented: $showAddDeviceSheet) {
            if let device = selectedDevice {
                AddDeviceSheet(device: device, onAdd: { name in
                    addDevice(device, withName: name)
                })
            }
        }
        .alert(item: Binding<AlertItem?>(
            get: { errorMessage.map { AlertItem(message: $0) } },
            set: { errorMessage = $0?.message }
        )) { alert in
            Alert(
                title: Text("Error"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            startDiscovery()
        }
        .onDisappear {
            stopDiscovery()
        }
    }
    
    // MARK: - Actions
    
    private func toggleDiscovery() {
        if isDiscovering {
            stopDiscovery()
        } else {
            startDiscovery()
        }
    }
    
    private func startDiscovery() {
        isDiscovering = true
        
        Task {
            do {
                discoveredDevices = try await yeelightManager.discover()
            } catch {
                errorMessage = "Discovery failed: \(error.localizedDescription)"
            }
            
            // Auto-stop discovery after 30 seconds
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            if isDiscovering {
                isDiscovering = false
            }
        }
    }
    
    private func stopDiscovery() {
        isDiscovering = false
    }
    
    private func addDevice(_ device: YeelightDevice, withName name: String) {
        Task {
            do {
                // Update the device name
                var updatedDevice = device
                updatedDevice.name = name
                
                // Add to Yeelight manager
                try await yeelightManager.updateDevice(updatedDevice)
                
                // Connect to the device
                try await yeelightManager.connect(to: updatedDevice)
                
                // Add to device manager as a generic device
                let genericDevice = Device.from(yeelightDevice: updatedDevice)
                await deviceManager.addDevice(genericDevice)
                
                // Refresh the discovered devices list
                if isDiscovering {
                    discoveredDevices = try await yeelightManager.discover()
                }
            } catch {
                errorMessage = "Failed to add device: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - DeviceDiscoveryRow

struct DeviceDiscoveryRow: View {
    let device: YeelightDevice
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                
                Text(device.model.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(device.ipAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Online status indicator
            Circle()
                .fill(device.isOnline ? Color.green : Color.red)
                .frame(width: 12, height: 12)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AddDeviceSheet

struct AddDeviceSheet: View {
    let device: YeelightDevice
    let onAdd: (String) -> Void
    
    @State private var deviceName: String
    @Environment(\.presentationMode) var presentationMode
    
    init(device: YeelightDevice, onAdd: @escaping (String) -> Void) {
        self.device = device
        self.onAdd = onAdd
        _deviceName = State(initialValue: device.name)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Device Information")) {
                    HStack {
                        Text("Model")
                        Spacer()
                        Text(device.model.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("IP Address")
                        Spacer()
                        Text(device.ipAddress)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Firmware")
                        Spacer()
                        Text(device.firmwareVersion)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Device Name")) {
                    TextField("Enter device name", text: $deviceName)
                }
                
                Section {
                    Button("Add Device") {
                        onAdd(deviceName)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Add Device")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Preview

struct DeviceDiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        let yeelightManager = ObservableYeelightManager(
            manager: UnifiedYeelightManager(
                storageManager: UnifiedStorageManager(),
                networkManager: UnifiedNetworkManager()
            )
        )
        
        let deviceManager = ObservableDeviceManager(
            manager: UnifiedDeviceManager()
        )
        
        return DeviceDiscoveryView()
            .environmentObject(yeelightManager)
            .environmentObject(deviceManager)
    }
}

// MARK: - Alert Item

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
} 