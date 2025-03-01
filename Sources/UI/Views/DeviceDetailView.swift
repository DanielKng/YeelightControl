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
                        BasicControlsView(device: device)
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
        .sheet(isPresented: $showingNameEdit) {
            RenameDeviceView(device: device)
        }
        .sheet(isPresented: $showingAdvancedSettings) {
            AdvancedSettingsView(device: device)
        }
    }
}

struct DeviceHeader: View {
    @ObservedObject var device: YeelightDevice
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color.black : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24))
                    .foregroundColor(device.isOn ? device.color : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                
                ConnectionStatusView(isConnected: device.isConnected, lastSeen: device.lastSeen)
                    .font(.caption)
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
} 