import SwiftUI

struct DeviceSetupView: View {
    @ObservedObject var manager: YeelightManager
    @ObservedObject var roomManager: RoomManager
    @Environment(\.dismiss) private var dismiss
    
    let device: YeelightDevice
    @State private var deviceName = ""
    @State private var selectedRoom: UUID?
    @State private var setupStep = SetupStep.naming
    @State private var isTestingConnection = false
    
    enum SetupStep {
        case naming, room, testing, complete
    }
    
    var body: some View {
        NavigationStack {
            UnifiedSettingsView(
                title: "Device Setup",
                sections: [
                    SettingsSection(
                        header: "Device Information",
                        items: [
                            SettingsItem(
                                title: "Device Name",
                                subtitle: "Enter a name for your device",
                                icon: "textbox",
                                type: .custom(AnyView(
                                    TextField("Device Name", text: $deviceName)
                                        .textFieldStyle(.roundedBorder)
                                ))
                            ),
                            SettingsItem(
                                title: "IP Address",
                                icon: "network",
                                type: .value(device.ip)
                            )
                        ]
                    ),
                    SettingsSection(
                        header: "Room Assignment",
                        items: roomManager.rooms.map { room in
                            SettingsItem(
                                title: room.name,
                                icon: room.icon,
                                type: .toggle(isOn: Binding(
                                    get: { selectedRoom == room.id },
                                    set: { if $0 { selectedRoom = room.id } }
                                ))
                            )
                        }
                    ),
                    SettingsSection(
                        header: "Connection Test",
                        items: [
                            SettingsItem(
                                title: "Test Connection",
                                subtitle: "Verify device connectivity",
                                icon: "antenna.radiowaves.left.and.right",
                                type: .button {
                                    isTestingConnection = true
                                    Task {
                                        try? await manager.testConnection(device)
                                        isTestingConnection = false
                                        setupStep = .complete
                                    }
                                }
                            )
                        ]
                    )
                ],
                footer: "Make sure your device is connected to the same network as your phone."
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if setupStep == .complete {
                        Button("Done") {
                            saveDeviceSetup()
                            dismiss()
                        }
                        .disabled(deviceName.isEmpty)
                    }
                }
            }
            .overlay {
                if isTestingConnection {
                    ProgressView("Testing connection...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
    }
    
    private var canMoveForward: Bool {
        switch setupStep {
        case .naming:
            return !deviceName.isEmpty
        case .room:
            return selectedRoom != nil
        case .testing:
            return !isTestingConnection
        case .complete:
            return true
        }
    }
    
    private func moveForward() {
        switch setupStep {
        case .naming:
            setupStep = .room
        case .room:
            setupStep = .testing
        case .testing:
            setupStep = .complete
        case .complete:
            break
        }
    }
    
    private func moveBack() {
        switch setupStep {
        case .naming:
            break
        case .room:
            setupStep = .naming
        case .testing:
            setupStep = .room
        case .complete:
            setupStep = .testing
        }
    }
    
    private func saveDeviceSetup() {
        device.name = deviceName
        if let roomID = selectedRoom {
            roomManager.addDevice(device.ip, toRoom: roomID)
        }
        manager.saveDeviceState(device, inRoom: selectedRoom?.uuidString ?? "")
    }
}

struct StepIndicator: View {
    let currentStep: DeviceSetupView.SetupStep
    
    var body: some View {
        HStack(spacing: 40) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index <= stepIndex ? .orange : .gray.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    private var stepIndex: Int {
        switch currentStep {
        case .naming: return 0
        case .room: return 1
        case .testing: return 2
        case .complete: return 3
        }
    }
}

// Add the step views (NamingStep, RoomSelectionStep, etc.) here... 