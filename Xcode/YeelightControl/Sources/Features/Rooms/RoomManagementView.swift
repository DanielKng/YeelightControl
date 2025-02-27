import SwiftUI

struct RoomManagementView: View {
    @ObservedObject var roomManager: RoomManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddRoom = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(roomManager.rooms) { room in
                    RoomRow(room: room)
                }
                .onMove { roomManager.moveRoom(from: $0, to: $1) }
                .onDelete { indexSet in
                    for index in indexSet {
                        roomManager.deleteRoom(roomManager.rooms[index])
                    }
                }
            }
            .navigationTitle("Manage Rooms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddRoom = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingAddRoom) {
                AddRoomView(roomManager: roomManager)
            }
        }
    }
}

struct RoomRow: View {
    let room: RoomManager.Room
    
    var body: some View {
        HStack {
            Image(systemName: room.icon)
                .foregroundStyle(.orange)
                .frame(width: 30)
            
            Text(room.name)
            
            Spacer()
            
            Text("\(room.deviceIPs.count) devices")
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}

struct AddRoomView: View {
    @ObservedObject var roomManager: RoomManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var roomName = ""
    @State private var selectedIcon = "lightbulb.fill"
    
    let icons = [
        "lightbulb.fill",
        "sofa.fill",
        "bed.double.fill",
        "cooktop.fill",
        "tv.fill",
        "desk.fill",
        "shower.fill",
        "house.fill",
        "building.fill",
        "door.left.hand.closed"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Room Name", text: $roomName)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 20) {
                        ForEach(icons, id: \.self) { icon in
                            IconButton(
                                icon: icon,
                                isSelected: selectedIcon == icon,
                                action: { selectedIcon = icon }
                            )
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        roomManager.addRoom(roomName, icon: selectedIcon)
                        dismiss()
                    }
                    .disabled(roomName.isEmpty)
                }
            }
        }
    }
}

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 60, height: 60)
                .background(isSelected ? .orange.opacity(0.2) : .clear)
                .foregroundStyle(isSelected ? .orange : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? .orange : .clear, lineWidth: 2)
                )
        }
    }
} 