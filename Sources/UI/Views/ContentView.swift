import SwiftUI

struct ContentView: View {
    @StateObject private var yeelightManager = YeelightManager()
    @State private var isDiscovering = false
    @State private var showingHelp = false
    @State private var showingError: Error?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if yeelightManager.devices.isEmpty {
                    EmptyStateView(isDiscovering: $isDiscovering) {
                        startDiscovery()
                    }
                } else {
                    List {
                        Section {
                            ForEach(yeelightManager.devices) { device in
                                DeviceRow(device: device, manager: yeelightManager)
                            }
                        } header: {
                            Text("Connected Devices")
                        } footer: {
                            Text("Tap a device to access detailed controls")
                        }
                        
                        Section {
                            Button(action: startDiscovery) {
                                HStack {
                                    Text("Search for More Devices")
                                    Spacer()
                                    if isDiscovering {
                                        ProgressView()
                                    }
                                }
                            }
                            .disabled(isDiscovering)
                        }
                    }
                }
                
                if isDiscovering {
                    ProgressView("Discovering devices...")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("My Lights")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: startDiscovery) {
                            Label("Discover Devices", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        .disabled(isDiscovering)
                        
                        Button(action: { showingHelp = true }) {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                        
                        if !yeelightManager.devices.isEmpty {
                            Button(role: .destructive, action: clearDevices) {
                                Label("Clear All Devices", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .alert("Error", isPresented: .constant(showingError != nil)) {
                Button("OK") { showingError = nil }
            } message: {
                Text(showingError?.localizedDescription ?? "")
            }
        }
        .environmentObject(yeelightManager)
    }
    
    private func startDiscovery() {
        isDiscovering = true
        yeelightManager.startDiscovery()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            isDiscovering = false
        }
    }
    
    private func clearDevices() {
        yeelightManager.clearDevices()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct EmptyStateView: View {
    @Binding var isDiscovering: Bool
    let onDiscover: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Lights Found")
                .font(.title2)
                .bold()
            
            Text("Tap discover to find your Yeelight devices on the network")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onDiscover) {
                Text("Discover Devices")
                    .bold()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isDiscovering)
        }
    }
}

struct DeviceCard: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: device.isOn ? "lightbulb.fill" : "lightbulb")
                        .font(.title2)
                        .foregroundStyle(device.isOn ? .yellow : .secondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { device.isOn },
                        set: { newValue in
                            device.isOn = newValue
                            manager.sendCommand(
                                to: device,
                                method: "set_power",
                                params: [newValue ? "on" : "off", "smooth", 500]
                            )
                        }
                    ))
                    .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Light")
                        .font(.headline)
                    Text(device.ip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            DeviceDetailView(device: device, manager: manager)
        }
    }
}

struct DeviceDetailView: View {
    @ObservedObject var device: YeelightDevice
    let manager: YeelightManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var brightness: Double
    @State private var color = Color.white
    
    init(device: YeelightDevice, manager: YeelightManager) {
        self.device = device
        self.manager = manager
        self._brightness = State(initialValue: Double(device.brightness))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("Power", systemImage: "power")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { device.isOn },
                            set: { newValue in
                                device.isOn = newValue
                                manager.sendCommand(
                                    to: device,
                                    method: "set_power",
                                    params: [newValue ? "on" : "off", "smooth", 500]
                                )
                            }
                        ))
                        .labelsHidden()
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Brightness", systemImage: "sun.max")
                            Spacer()
                            Text("\(Int(brightness))%")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $brightness, in: 1...100) { changed in
                            if changed {
                                device.brightness = Int(brightness)
                                manager.sendCommand(
                                    to: device,
                                    method: "set_bright",
                                    params: [Int(brightness), "smooth", 500]
                                )
                            }
                        }
                    }
                }
                
                Section {
                    ColorPicker("Color", selection: $color)
                        .onChange(of: color) { newValue in
                            let components = UIColor(newValue).cgColor.components ?? [1, 1, 1, 1]
                            let rgb = YeelightDevice.RGB(
                                red: Int(components[0] * 255),
                                green: Int(components[1] * 255),
                                blue: Int(components[2] * 255)
                            )
                            device.color = rgb
                            manager.sendCommand(
                                to: device,
                                method: "set_rgb",
                                params: [rgb.rgbValue, "smooth", 500]
                            )
                        }
                }
                
                Section {
                    HStack {
                        Text("IP Address")
                        Spacer()
                        Text(device.ip)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Port")
                        Spacer()
                        Text("\(device.port)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Light Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to Use")
                            .font(.headline)
                        Text("1. Make sure your Yeelight devices are connected to the same network as this device")
                        Text("2. Tap 'Discover Devices' to find your lights")
                        Text("3. Tap any light to access detailed controls")
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Troubleshooting")
                            .font(.headline)
                        Text("• Ensure LAN Control is enabled in the Yeelight app")
                        Text("• Check that your devices are powered on and connected to WiFi")
                        Text("• Try restarting your lights if they're not responding")
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 