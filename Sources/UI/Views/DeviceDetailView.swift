import SwiftUI
import Core

struct DeviceDetailView: View {
    @ObservedObject var device: YeelightDevice
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTab = Tab.basic
    @State private var showingNameEdit = false
    @State private var showingAdvancedSettings = false
    @State private var tempName = ""
    
    enum Tab {
        case basic, effects, scenes
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DeviceHeader(device: device)
                .padding()
            
            Picker("View", selection: $selectedTab) {
                Text("Basic").tag(Tab.basic)
                Text("Effects").tag(Tab.effects)
                Text("Scenes").tag(Tab.scenes)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Divider()
                .padding(.top)
            
            ScrollView {
                VStack(spacing: 20) {
                    switch selectedTab {
                    case .basic:
                        DeviceControlView(device: device)
                    case .effects:
                        EffectsListView(device: device)
                    case .scenes:
                        SceneListView(device: device)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(device.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingNameEdit = true }) {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button(action: { showingAdvancedSettings = true }) {
                        Label("Advanced Settings", systemImage: "gear")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Rename Device", isPresented: $showingNameEdit) {
            TextField("Device Name", text: $tempName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                renameDevice()
            }
        } message: {
            Text("Enter a new name for this device")
        }
        .sheet(isPresented: $showingAdvancedSettings) {
            NavigationView {
                DeviceAdvancedSettingsView(device: device)
                    .navigationTitle("Advanced Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingAdvancedSettings = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            tempName = device.name
        }
    }
    
    private func renameDevice() {
        guard !tempName.isEmpty else { return }
        
        Task {
            var updatedDevice = device
            updatedDevice.name = tempName
            try? await yeelightManager.updateDevice(updatedDevice)
        }
    }
}

struct DeviceHeader: View {
    @ObservedObject var device: YeelightDevice
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager
    @State private var isUpdating = false
    @State private var errorMessage: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                ConnectionStatusView(isConnected: device.isConnected, lastSeen: device.lastSeen)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { device.state.power },
                set: { newValue in togglePower(to: newValue) }
            ))
            .labelsHidden()
            .disabled(!device.isConnected || isUpdating)
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
    }
    
    private func togglePower(to newValue: Bool) {
        isUpdating = true
        
        Task {
            do {
                let command = YeelightCommand.setPower(on: newValue)
                try await yeelightManager.send(command, to: device)
            } catch {
                errorMessage = "Failed to toggle power: \(error.localizedDescription)"
            }
            
            isUpdating = false
        }
    }
}

// MARK: - Placeholder Views

struct EffectsListView: View {
    let device: YeelightDevice
    
    var body: some View {
        Text("Effects coming soon")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}

struct SceneListView: View {
    let device: YeelightDevice
    
    var body: some View {
        Text("Scenes coming soon")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}

struct DeviceAdvancedSettingsView: View {
    let device: YeelightDevice
    
    var body: some View {
        List {
            Section(header: Text("Device Information")) {
                LabeledContent("Model", value: device.model.displayName)
                LabeledContent("Firmware", value: device.firmwareVersion)
                LabeledContent("IP Address", value: device.ipAddress)
                LabeledContent("ID", value: device.id)
            }
            
            Section(header: Text("Actions")) {
                Button("Restart Device", role: .destructive) {
                    // Implement restart functionality
                }
                
                Button("Factory Reset", role: .destructive) {
                    // Implement factory reset functionality
                }
            }
        }
    }
}

// MARK: - Preview

struct DeviceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockDevice = YeelightDevice(
            id: "mock-id",
            name: "Living Room Light",
            model: .colorLEDBulb,
            firmwareVersion: "1.0.0",
            ipAddress: "192.168.1.100",
            state: DeviceState(
                power: true,
                brightness: 80,
                colorTemperature: 4000,
                color: DeviceColor(red: 255, green: 255, blue: 255)
            ),
            isOnline: true,
            lastSeen: Date(),
            isConnected: true
        )
        
        let yeelightManager = ObservableYeelightManager(
            manager: UnifiedYeelightManager(
                storageManager: UnifiedStorageManager(),
                networkManager: UnifiedNetworkManager()
            )
        )
        
        return NavigationView {
            DeviceDetailView(device: mockDevice)
                .environmentObject(yeelightManager)
        }
    }
}

// MARK: - Alert Item

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
} 