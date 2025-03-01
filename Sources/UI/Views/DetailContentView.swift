import SwiftUI

// This file contains the detailed content view for the Yeelight Control app

struct DetailContentView: View {
    @StateObject private var yeelightManager = YeelightManager()
    @State private var isDiscovering = false
    @State private var showingHelp = false
    @State private var showingError: Error?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if yeelightManager.devices.isEmpty {
                    EmptyStateView(isDiscovering: $isDiscovering)
                        .environmentObject(yeelightManager)
                } else {
                    List {
                        Section {
                            ForEach(yeelightManager.devices) { device in
                                DeviceRow(device: device)
                            }
                        } header: {
                            HStack {
                                Text("Devices")
                                Spacer()
                                if isDiscovering {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await startDiscovery()
                    }
                }
            }
            .navigationTitle("Yeelight Control")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingHelp = true }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isDiscovering {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        
                        Menu {
                            Button(action: { Task { await startDiscovery() } }) {
                                Label("Discover Devices", systemImage: "magnifyingglass")
                            }
                            
                            Button(action: { clearDevices() }) {
                                Label("Clear All Devices", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .alert("Error", isPresented: .constant(showingError != nil), presenting: showingError) { _ in
                Button("OK") { showingError = nil }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
        .task {
            await startDiscovery()
        }
    }
    
    private func startDiscovery() async {
        isDiscovering = true
        do {
            try await yeelightManager.discoverDevices()
        } catch {
            showingError = error
        }
        isDiscovering = false
    }
    
    private func clearDevices() {
        yeelightManager.clearDevices()
    }
}

struct DetailContentView_Previews: PreviewProvider {
    static var previews: some View {
        DetailContentView()
    }
}

struct EmptyStateView: View {
    @Binding var isDiscovering: Bool
    @EnvironmentObject var yeelightManager: YeelightManager
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "lightbulb.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Devices Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Make sure your Yeelight devices are on the same network and have LAN Control enabled.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: {
                Task {
                    await yeelightManager.discoverDevices()
                }
            }) {
                HStack {
                    Text("Discover Devices")
                    if isDiscovering {
                        ProgressView()
                    }
                }
                .frame(minWidth: 200)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isDiscovering)
            
            Spacer()
        }
    }
}

struct DeviceRow: View {
    @ObservedObject var device: YeelightDevice
    
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack {
                ZStack {
                    Circle()
                        .fill(device.isOn ? device.color.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                        .foregroundColor(device.isOn ? device.color : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { device.isOn },
                    set: { newValue in
                        device.setPower(on: newValue)
                    }
                ))
                .labelsHidden()
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            NavigationStack {
                DeviceDetailView(device: device)
            }
        }
    }
    
    private var statusColor: Color {
        switch device.connectionState {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .red
        }
    }
    
    private var statusText: String {
        switch device.connectionState {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        }
    }
}

struct DeviceDetailView: View {
    @ObservedObject var device: YeelightDevice
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var brightness: Double
    @State private var color = Color.white
    
    init(device: YeelightDevice) {
        self.device = device
        _brightness = State(initialValue: Double(device.brightness))
        _color = State(initialValue: device.color)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Device icon
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color.black : Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 50))
                        .foregroundColor(device.isOn ? color : .gray)
                }
                .padding(.top, 20)
                
                // Power toggle
                Button(action: {
                    device.setPower(on: !device.isOn)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text(device.isOn ? "Turn Off" : "Turn On")
                    }
                    .frame(minWidth: 200)
                    .padding()
                    .background(device.isOn ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                // Brightness slider
                VStack(alignment: .leading, spacing: 10) {
                    Text("Brightness: \(Int(brightness))%")
                        .font(.headline)
                    
                    Slider(value: $brightness, in: 1...100) { changed in
                        if changed {
                            device.setBrightness(Int(brightness))
                        }
                    }
                }
                .padding(.horizontal)
                
                // Color picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Color")
                        .font(.headline)
                    
                    ColorPicker("Select Color", selection: $color)
                        .labelsHidden()
                        .onChange(of: color) { newColor in
                            device.setColor(newColor)
                        }
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle(device.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
} 