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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach([Tab.basic, .preset, .custom, .multiDevice], id: \.name) { tab in
                            TabButton(
                                title: tab.name,
                                icon: tab.icon,
                                isSelected: selectedTab == tab,
                                action: { selectedTab = tab }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
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

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 80)
            .padding(.vertical, 8)
            .background(isSelected ? .orange.opacity(0.2) : .clear)
            .foregroundStyle(isSelected ? .orange : .primary)
            .cornerRadius(8)
        }
    }
}

struct PresetSceneView: View {
    @StateObject private var deviceManager = YeelightManager.shared
    @State private var selectedPreset: ScenePreset?
    @State private var selectedDevices: Set<String> = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Device selection
                Section {
                    Text("Select Devices")
                        .font(.headline)
                    EnhancedDeviceSelectionList(selectedDevices: $selectedDevices)
                }
                
                // Preset grid
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 16)
                ], spacing: 16) {
                    ForEach(ScenePreset.presets) { preset in
                        PresetCard(
                            preset: preset,
                            isSelected: selectedPreset?.id == preset.id,
                            action: { selectedPreset = preset }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
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
    @StateObject private var deviceManager = YeelightManager.shared
    @State private var selectedDevices: Set<String> = []
    @State private var flowParams = YeelightDevice.FlowParams()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Device selection
                Section {
                    Text("Select Devices")
                        .font(.headline)
                    EnhancedDeviceSelectionList(selectedDevices: $selectedDevices)
                }
                
                // Flow effect editor
                FlowEffectEditor(params: $flowParams)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct MultiDeviceSceneView: View {
    @StateObject private var deviceManager = YeelightManager.shared
    @State private var selectedDevices: Set<String> = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Device selection
                Section {
                    Text("Select Devices")
                        .font(.headline)
                    EnhancedDeviceSelectionList(selectedDevices: $selectedDevices)
                }
                
                if selectedDevices.count >= 2 {
                    // Multi-device effect editor
                    MultiDeviceEffectEditor(devices: selectedDevices.compactMap { ip in
                        deviceManager.devices.first { $0.ip == ip }
                    })
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
} 