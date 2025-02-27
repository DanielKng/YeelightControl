import SwiftUI

struct DeviceDetailView: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = Tab.basic
    @State private var showingNameEdit = false
    @State private var showingAdvancedSettings = false
    @State private var tempName = ""
    
    enum Tab {
        case basic, color, effects, scenes
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with device status
                    DeviceHeader(device: device, manager: manager)
                    
                    // Tab selector
                    Picker("Mode", selection: $selectedTab) {
                        Text("Basic").tag(Tab.basic)
                        Text("Color").tag(Tab.color)
                        Text("Effects").tag(Tab.effects)
                        Text("Scenes").tag(Tab.scenes)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Content based on selected tab
                    Group {
                        switch selectedTab {
                        case .basic:
                            BasicControls(device: device, manager: manager)
                        case .color:
                            ColorControls(device: device, manager: manager)
                        case .effects:
                            EffectsView(device: device, manager: manager)
                        case .scenes:
                            ScenesView(device: device, manager: manager)
                        }
                    }
                    .padding(.horizontal)
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
                        
                        Button(role: .destructive, action: {
                            manager.clearDevices()
                            dismiss()
                        }) {
                            Label("Forget Device", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Rename Device", isPresented: $showingNameEdit) {
                TextField("Device Name", text: $tempName)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    manager.setName(device, name: tempName)
                }
            }
            .sheet(isPresented: $showingAdvancedSettings) {
                AdvancedSettingsView(device: device, manager: manager)
            }
        }
    }
}

// MARK: - Supporting Views
struct DeviceHeader: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                .font(.system(size: 60))
                .foregroundStyle(device.isOn ? .yellow : .secondary)
            
            HStack {
                ConnectionStatusView(state: device.connectionState)
                
                Spacer()
                
                Toggle("Power", isOn: Binding(
                    get: { device.isOn },
                    set: { newValue in
                        manager.setPower(device, on: newValue)
                    }
                ))
                .labelsHidden()
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct ConnectionStatusView: View {
    let state: YeelightDevice.ConnectionState
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
    
    private var statusText: String {
        switch state {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error(let message): return "Error: \(message)"
        }
    }
} 