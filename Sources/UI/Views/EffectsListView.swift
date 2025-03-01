import SwiftUI
import Core

/// View for displaying and managing light effects
struct EffectsListView: View {
    // MARK: - Environment

    @EnvironmentObject private var effectManager: ObservableEffectManager
    @EnvironmentObject private var yeelightManager: ObservableYeelightManager

    // MARK: - State

    @State private var isCreatingEffect = false
    @State private var selectedEffect: Effect?
    @State private var selectedDeviceIDs: Set<DeviceID> = []

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            deviceSelectionSection

            UnifiedListView(
                title: "Effects",
                items: effectManager.effects,
                emptyStateMessage: "No effects created yet",
                onRefresh: {
                    // Refresh effects if needed
                },
                onDelete: { effect in
                    effectManager.deleteEffect(effect)
                }
            ) { effect in
                EffectRow(
                    effect: effect,
                    onActivate: {
                        let selectedDevices = yeelightManager.devices.filter { selectedDeviceIDs.contains($0.id) }
                        effectManager.startEffect(effect, on: selectedDevices)
                    },
                    onEdit: {
                        selectedEffect = effect
                    }
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isCreatingEffect = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(selectedDeviceIDs.isEmpty)
            }
        }
        .sheet(isPresented: $isCreatingEffect) {
            NavigationView {
                let selectedDevices = yeelightManager.devices.filter { selectedDeviceIDs.contains($0.id) }
                FlowEffectEditor(devices: selectedDevices)
            }
        }
        .sheet(item: $selectedEffect) { effect in
            NavigationView {
                let selectedDevices = yeelightManager.devices.filter { selectedDeviceIDs.contains($0.id) }
                FlowEffectEditor(effect: effect, devices: selectedDevices)
            }
        }
    }

    private var deviceSelectionSection: some View {
        Section {
            if !yeelightManager.devices.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(yeelightManager.devices) { device in
                            Button {
                                toggleDeviceSelection(device.id)
                            } label: {
                                DeviceChip(deviceID: device.id)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 4)
                                    .background(selectedDeviceIDs.contains(device.id) ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemFill))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(selectedDeviceIDs.contains(device.id) ? Color.accentColor : .clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            } else {
                Text("No devices available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    private func toggleDeviceSelection(_ deviceID: DeviceID) {
        if selectedDeviceIDs.contains(deviceID) {
            selectedDeviceIDs.remove(deviceID)
        } else {
            selectedDeviceIDs.insert(deviceID)
        }
    }
}

// MARK: - Supporting Views

private struct EffectRow: View {
    let effect: Effect
    let onActivate: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(effect.name)
                    .font(.headline)
                Text(effect.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                onActivate()
            } label: {
                Image(systemName: "play.fill")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        EffectsListView()
            .environmentObject(ServiceContainer.shared.observableEffectManager)
            .environmentObject(ServiceContainer.shared.observableYeelightManager)
    }
} 