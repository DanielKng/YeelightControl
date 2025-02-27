import SwiftUI

struct CreateSceneView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var yeelightManager: YeelightManager
    
    @State private var sceneName = ""
    @State private var sceneDescription = ""
    @State private var selectedIcon = "theatermasks.fill"
    @State private var selectedDevices: Set<Device> = []
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let icons = [
        "theatermasks.fill",
        "bed.double.fill",
        "house.fill",
        "tv.fill",
        "sofa.fill",
        "party.popper.fill",
        "moon.stars.fill",
        "sunset.fill",
        "sparkles",
        "wand.and.stars"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Scene details
                VStack(spacing: 12) {
                    UnifiedTextField(
                        text: $sceneName,
                        placeholder: "Scene Name",
                        icon: "theatermasks.fill",
                        clearButton: true
                    )
                    
                    UnifiedTextField(
                        text: $sceneDescription,
                        placeholder: "Scene Description (Optional)",
                        icon: "text.alignleft",
                        clearButton: true
                    )
                }
                .padding(.horizontal)
                
                // Icon selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title)
                                    .foregroundColor(selectedIcon == icon ? .accentColor : .secondary)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == icon ? .accentColor.opacity(0.2) : .clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
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
            }
            .navigationTitle("Create Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createScene()
                    }
                    .disabled(sceneName.isEmpty || selectedDevices.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createScene() {
        do {
            try yeelightManager.createScene(
                name: sceneName,
                description: sceneDescription.isEmpty ? nil : sceneDescription,
                icon: selectedIcon,
                devices: Array(selectedDevices)
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct DeviceSelectionRow: View {
    let device: Device
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(device.isOn ? .yellow : .gray)
            
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                Text(device.ipAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    CreateSceneView()
        .environmentObject(YeelightManager.shared)
} 