import SwiftUI

struct DeviceSetupView: View {
    @ObservedObject var manager: YeelightManager
    @ObservedObject var roomManager: RoomManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var deviceName = ""
    @State private var selectedRoom: UUID?
    @State private var setupStep = SetupStep.naming
    @State private var isTestingConnection = false
    
    enum SetupStep {
        case naming
        case roomSelection
        case complete
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                StepIndicator(currentStep: setupStep)
                    .padding(.top)
                
                // Main content
                VStack(spacing: 20) {
                    // Step content
                    switch setupStep {
                    case .naming:
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Name Your Device")
                                .font(.headline)
                            
                            TextField("Device Name", text: $deviceName)
                                .textFieldStyle(.roundedBorder)
                                .padding(.bottom)
                            
                            Text("Choose a descriptive name for your Yeelight device. This will help you identify it in your home.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                    case .roomSelection:
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select a Room")
                                .font(.headline)
                            
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                                    ForEach(roomManager.rooms) { room in
                                        RoomSelectionCard(
                                            room: room,
                                            isSelected: selectedRoom == room.id,
                                            onSelect: { selectedRoom = room.id }
                                        )
                                    }
                                    
                                    // Add new room option
                                    RoomSelectionCard(
                                        room: Room(name: "Add New", icon: "plus.circle"),
                                        isSelected: false,
                                        onSelect: { /* Show room creation UI */ }
                                    )
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                        
                    case .complete:
                        VStack(spacing: 24) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Setup Complete!")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Your device has been added successfully and is ready to use.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxHeight: .infinity)
                    }
                    
                    Spacer()
                    
                    // Connection test indicator
                    if isTestingConnection {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Testing connection...")
                        }
                        .padding()
                    }
                    
                    // Navigation buttons
                    HStack {
                        if setupStep != .naming {
                            Button("Back") {
                                moveBack()
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        if setupStep == .complete {
                            Button("Done") {
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Next") {
                                moveForward()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!canMoveForward)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Device Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(setupStep != .complete)
    }
    
    private var canMoveForward: Bool {
        switch setupStep {
        case .naming:
            return !deviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .roomSelection:
            return true // Optional selection
        case .complete:
            return true
        }
    }
    
    private func moveForward() {
        switch setupStep {
        case .naming:
            setupStep = .roomSelection
        case .roomSelection:
            // Test connection and save device
            isTestingConnection = true
            
            // Simulate connection test
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isTestingConnection = false
                saveDeviceSetup()
                setupStep = .complete
            }
        case .complete:
            dismiss()
        }
    }
    
    private func moveBack() {
        switch setupStep {
        case .naming:
            break // Already at first step
        case .roomSelection:
            setupStep = .naming
        case .complete:
            setupStep = .roomSelection
        }
    }
    
    private func saveDeviceSetup() {
        // In a real app, this would save the device to the manager
        let device = YeelightDevice(name: deviceName, ipAddress: "192.168.1.100")
        manager.addDevice(device)
        
        if let roomID = selectedRoom {
            roomManager.addDeviceToRoom(device.id, roomID: roomID)
        }
    }
}

struct StepIndicator: View {
    let currentStep: DeviceSetupView.SetupStep
    
    var body: some View {
        HStack {
            ForEach(0..<3) { index in
                Circle()
                    .fill(stepColor(for: index))
                    .frame(width: 12, height: 12)
                
                if index < 2 {
                    Rectangle()
                        .fill(stepColor(for: index, isConnector: true))
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, 40)
    }
    
    private func stepColor(for index: Int, isConnector: Bool = false) -> Color {
        let stepValue = stepValue(for: currentStep)
        
        if isConnector {
            return index < stepValue ? .accentColor : Color.gray.opacity(0.3)
        } else {
            return index <= stepValue ? .accentColor : Color.gray.opacity(0.3)
        }
    }
    
    private func stepValue(for step: DeviceSetupView.SetupStep) -> Int {
        switch step {
        case .naming: return 0
        case .roomSelection: return 1
        case .complete: return 2
        }
    }
}

struct RoomSelectionCard: View {
    let room: Room
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                
                Image(systemName: room.icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
            
            Text(room.name)
                .font(.caption)
                .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .onTapGesture {
            onSelect()
        }
    }
} 