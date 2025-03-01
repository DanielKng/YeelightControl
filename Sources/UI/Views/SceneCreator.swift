import SwiftUI

struct SceneCreator: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = Tab.basic
    @State private var showingPreview = false
    
    enum Tab {
        case basic, custom, multiDevice
        
        var name: String {
            switch self {
            case .basic:
                return "Preset"
            case .custom:
                return "Custom"
            case .multiDevice:
                return "Multi-Device"
            }
        }
        
        var icon: String {
            switch self {
            case .basic:
                return "theatermasks"
            case .custom:
                return "slider.horizontal.3"
            case .multiDevice:
                return "lightbulb.2"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                HStack(spacing: 0) {
                    ForEach([Tab.basic, .custom, .multiDevice], id: \.name) { tab in
                        Button(action: { selectedTab = tab }) {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 20))
                                
                                Text(tab.name)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
                            .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                        }
                        .buttonStyle(.plain)
                        
                        if tab != .multiDevice {
                            Divider()
                                .frame(height: 30)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                
                Divider()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    PresetSceneView()
                        .tag(Tab.basic)
                    
                    CustomSceneView()
                        .tag(Tab.custom)
                    
                    MultiDeviceSceneView()
                        .tag(Tab.multiDevice)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
            .navigationTitle("Create Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Preview") { showingPreview = true }
                }
            }
            .sheet(isPresented: $showingPreview) {
                ScenePreview()
            }
        }
    }
}

struct PresetSceneView: View {
    @EnvironmentObject private var yeelightManager: YeelightManager
    @State private var selectedPreset: ScenePreset?
    @State private var selectedDevices: Set<Device> = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Device selection
                Section(header: Text("Select Devices").font(.headline)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(yeelightManager.devices) { device in
                                Button(action: {
                                    if selectedDevices.contains(device) {
                                        selectedDevices.remove(device)
                                    } else {
                                        selectedDevices.insert(device)
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.secondary.opacity(0.2))
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: "lightbulb.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(device.isOn ? .yellow : .gray)
                                            
                                            if selectedDevices.contains(device) {
                                                Circle()
                                                    .fill(Color.accentColor)
                                                    .frame(width: 24, height: 24)
                                                    .overlay(
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundColor(.white)
                                                    )
                                                    .position(x: 50, y: 10)
                                            }
                                        }
                                        
                                        Text(device.name)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 80)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Preset selection
                Section(header: Text("Select Preset").font(.headline)) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        ForEach(ScenePreset.presets) { preset in
                            PresetCard(preset: preset, isSelected: selectedPreset == preset)
                                .onTapGesture {
                                    selectedPreset = preset
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct PresetCard: View {
    let preset: ScenePreset
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Color preview
            RoundedRectangle(cornerRadius: 12)
                .fill(preset.color)
                .frame(height: 100)
                .overlay(
                    Image(systemName: preset.icon)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                )
            
            // Title
            Text(preset.name)
                .font(.headline)
            
            // Description
            Text(preset.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

struct CustomSceneView: View {
    @EnvironmentObject private var yeelightManager: YeelightManager
    @State private var selectedDevices: Set<Device> = []
    @State private var flowParams = YeelightDevice.FlowParams()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Device selection
                Section(header: Text("Select Devices").font(.headline)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(yeelightManager.devices) { device in
                                Button(action: {
                                    if selectedDevices.contains(device) {
                                        selectedDevices.remove(device)
                                    } else {
                                        selectedDevices.insert(device)
                                    }
                                }) {
                                    // Device chip (same as in PresetSceneView)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Flow effect editor
                FlowEffectEditor(params: $flowParams)
            }
            .padding(.vertical)
        }
    }
}

struct MultiDeviceSceneView: View {
    @EnvironmentObject private var yeelightManager: YeelightManager
    @State private var selectedDevices: Set<Device> = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Device selection
                Section(header: Text("Select Devices").font(.headline)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(yeelightManager.devices) { device in
                                Button(action: {
                                    if selectedDevices.contains(device) {
                                        selectedDevices.remove(device)
                                    } else {
                                        selectedDevices.insert(device)
                                    }
                                }) {
                                    // Device chip (same as in PresetSceneView)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                if selectedDevices.count >= 2 {
                    // Multi-device configuration options
                    Text("Configure multi-device scene")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Additional configuration options would go here
                } else {
                    Text("Select at least 2 devices to create a multi-device scene")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
} 