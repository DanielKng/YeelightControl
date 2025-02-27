import SwiftUI

struct SceneCreator: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = Tab.basic
    @State private var showingPreview = false
    
    enum Tab {
        case basic, preset, custom, multiDevice
        
        var name: String {
            switch self {
            case .basic: return "Basic"
            case .preset: return "Presets"
            case .custom: return "Custom"
            case .multiDevice: return "Multi-Device"
            }
        }
        
        var icon: String {
            switch self {
            case .basic: return "lightbulb"
            case .preset: return "theatermasks"
            case .custom: return "wand.and.stars"
            case .multiDevice: return "lightbulb.2"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                UnifiedTabSelector(
                    selection: $selectedTab,
                    tabs: [
                        .init("Basic", icon: "lightbulb", tag: Tab.basic),
                        .init("Presets", icon: "theatermasks", tag: Tab.preset),
                        .init("Custom", icon: "wand.and.stars", tag: Tab.custom),
                        .init("Multi-Device", icon: "lightbulb.2", tag: Tab.multiDevice)
                    ],
                    style: .pills
                )
                .padding(.vertical, 8)
                .background(.bar)
                
                // Content
                TabView(selection: $selectedTab) {
                    CreateSceneView()
                        .tag(Tab.basic)
                    
                    PresetSceneView()
                        .tag(Tab.preset)
                    
                    CustomSceneView()
                        .tag(Tab.custom)
                    
                    MultiDeviceSceneView()
                        .tag(Tab.multiDevice)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Create Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Preview") {
                        showingPreview = true
                    }
                }
            }
        }
    }
}

struct PresetSceneView: View {
    @EnvironmentObject private var yeelightManager: YeelightManager
    @State private var selectedPreset: ScenePreset?
    @State private var selectedDevices: Set<Device> = []
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            // Preset grid
            UnifiedGridView(
                title: "Select Preset",
                items: ScenePreset.presets,
                columns: [GridItem(.adaptive(minimum: 150), spacing: 16)],
                spacing: 16,
                emptyStateMessage: "No presets available"
            ) { preset in
                PresetCard(
                    preset: preset,
                    isSelected: selectedPreset?.id == preset.id,
                    action: { selectedPreset = preset }
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct PresetCard: View {
    let preset: ScenePreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: preset.icon)
                    .font(.title)
                    .foregroundStyle(preset.previewColor)
                
                Text(preset.name)
                    .font(.headline)
                
                Text(preset.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .orange : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CustomSceneView: View {
    @EnvironmentObject private var yeelightManager: YeelightManager
    @State private var selectedDevices: Set<Device> = []
    @State private var flowParams = YeelightDevice.FlowParams()
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            // Flow effect editor
            FlowEffectEditor(params: $flowParams)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct MultiDeviceSceneView: View {
    @EnvironmentObject private var yeelightManager: YeelightManager
    @State private var selectedDevices: Set<Device> = []
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            if selectedDevices.count >= 2 {
                // Multi-device effect editor
                MultiDeviceEffectEditor(devices: Array(selectedDevices))
                    .padding(.horizontal)
            } else {
                ContentUnavailableView(
                    "Select Multiple Devices",
                    systemImage: "lightbulb.2",
                    description: Text("Select at least 2 devices to create a multi-device scene")
                )
            }
        }
        .padding(.vertical)
    }
} 