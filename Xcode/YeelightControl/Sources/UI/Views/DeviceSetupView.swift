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
            VStack(spacing: 20) {
                // Progress indicator
                StepIndicator(currentStep: setupStep)
                    .padding(.top)
                
                ScrollView {
                    VStack(spacing: 30) {
                        switch setupStep {
                        case .naming:
                            NamingStep(deviceName: $deviceName, device: device)
                        case .room:
                            RoomSelectionStep(
                                selectedRoom: $selectedRoom,
                                rooms: roomManager.rooms
                            )
                        case .testing:
                            TestingStep(
                                device: device,
                                manager: manager,
                                isTestingConnection: $isTestingConnection
                            )
                        case .complete:
                            CompleteStep(deviceName: deviceName)
                        }
                    }
                    .padding()
                }
                
                // Navigation buttons
                if setupStep != .complete {
                    HStack {
                        Button("Back") {
                            withAnimation {
                                moveBack()
                            }
                        }
                        .disabled(setupStep == .naming)
                        
                        Spacer()
                        
                        Button(setupStep == .testing ? "Complete" : "Next") {
                            withAnimation {
                                moveForward()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canMoveForward)
                    }
                    .padding()
                } else {
                    Button("Done") {
                        saveDeviceSetup()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Setup New Device")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
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