import SwiftUI

struct NamingStep: View {
    @Binding var deviceName: String
    let device: YeelightDevice
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Name your device")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Give your Yeelight a name to easily identify it")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            TextField("Device Name", text: $deviceName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            Text("IP Address: \(device.ip)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct RoomSelectionStep: View {
    @Binding var selectedRoom: UUID?
    let rooms: [RoomManager.Room]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Select a Room")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose which room this device belongs to")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 150), spacing: 16)
            ], spacing: 16) {
                ForEach(rooms) { room in
                    RoomSelectionCard(
                        room: room,
                        isSelected: room.id == selectedRoom,
                        action: { selectedRoom = room.id }
                    )
                }
            }
        }
        .padding()
    }
}

struct RoomSelectionCard: View {
    let room: RoomManager.Room
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: room.icon)
                    .font(.title)
                    .foregroundStyle(isSelected ? .white : .orange)
                
                Text(room.name)
                    .font(.headline)
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Text("\(room.deviceIPs.count) devices")
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? .orange : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct TestingStep: View {
    let device: YeelightDevice
    let manager: YeelightManager
    @Binding var isTestingConnection: Bool
    @State private var testBrightness: Double = 100
    @State private var testColor = Color.white
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Test Your Device")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Make sure everything is working correctly")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                Toggle("Power", isOn: Binding(
                    get: { device.isOn },
                    set: { newValue in
                        manager.setPower(device, on: newValue)
                    }
                ))
                
                VStack(alignment: .leading) {
                    Text("Brightness")
                    Slider(value: $testBrightness, in: 1...100) { changed in
                        if changed {
                            manager.setBrightness(device, brightness: Int(testBrightness))
                        }
                    }
                }
                
                ColorPicker("Color", selection: $testColor)
                    .onChange(of: testColor) { newColor in
                        let components = UIColor(testColor).cgColor.components ?? [1, 1, 1, 1]
                        manager.setRGB(
                            device,
                            red: Int(components[0] * 255),
                            green: Int(components[1] * 255),
                            blue: Int(components[2] * 255)
                        )
                    }
                
                Button("Flash Test") {
                    isTestingConnection = true
                    manager.startColorFlow(device, params: .init(
                        count: 1,
                        action: .recover,
                        transitions: [
                            .init(duration: 500, mode: 1, value: 0xFFFFFF, brightness: 100),
                            .init(duration: 500, mode: 1, value: 0x000000, brightness: 1),
                            .init(duration: 500, mode: 1, value: 0xFFFFFF, brightness: 100)
                        ]
                    ))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isTestingConnection = false
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
    }
}

struct CompleteStep: View {
    let deviceName: String
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Setup Complete!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("\(deviceName) has been successfully set up and is ready to use")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
} 