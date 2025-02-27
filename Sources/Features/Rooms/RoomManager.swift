import SwiftUI

class RoomManager: ObservableObject {
    @Published private(set) var rooms: [Room] = []
    private let storage = DeviceStorage.shared
    
    struct Room: Identifiable, Codable {
        let id: UUID
        var name: String
        var icon: String
        var deviceIPs: Set<String>
        var sortOrder: Int
        
        init(id: UUID = UUID(), name: String, icon: String, deviceIPs: Set<String> = [], sortOrder: Int) {
            self.id = id
            self.name = name
            self.icon = icon
            self.deviceIPs = deviceIPs
            self.sortOrder = sortOrder
        }
    }
    
    init() {
        loadRooms()
    }
    
    func loadRooms() {
        rooms = storage.loadRooms()
        if rooms.isEmpty {
            // Create default rooms
            rooms = [
                Room(name: "Living Room", icon: "sofa.fill", sortOrder: 0),
                Room(name: "Bedroom", icon: "bed.double.fill", sortOrder: 1),
                Room(name: "Kitchen", icon: "cooktop.fill", sortOrder: 2)
            ]
            saveRooms()
        }
    }
    
    func addRoom(_ name: String, icon: String) {
        let room = Room(
            name: name,
            icon: icon,
            sortOrder: rooms.count
        )
        rooms.append(room)
        saveRooms()
    }
    
    func deleteRoom(_ room: Room) {
        rooms.removeAll { $0.id == room.id }
        saveRooms()
    }
    
    func moveRoom(from source: IndexSet, to destination: Int) {
        rooms.move(fromOffsets: source, toOffset: destination)
        // Update sort order
        for (index, var room) in rooms.enumerated() {
            room.sortOrder = index
        }
        saveRooms()
    }
    
    func addDevice(_ deviceIP: String, toRoom roomID: UUID) {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else { return }
        rooms[index].deviceIPs.insert(deviceIP)
        saveRooms()
    }
    
    func removeDevice(_ deviceIP: String, fromRoom roomID: UUID) {
        guard let index = rooms.firstIndex(where: { $0.id == roomID }) else { return }
        rooms[index].deviceIPs.remove(deviceIP)
        saveRooms()
    }
    
    private func saveRooms() {
        storage.saveRooms(rooms)
    }
} 