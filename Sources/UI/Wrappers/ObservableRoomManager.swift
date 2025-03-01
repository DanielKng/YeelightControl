import SwiftUI
import Core

/// Observable wrapper for UnifiedRoomManager
@MainActor
public class ObservableRoomManager: ObservableObject {
    private let manager: UnifiedRoomManager
    @Published public private(set) var rooms: [Room] = []
    
    public init(manager: UnifiedRoomManager) {
        self.manager = manager
        Task {
            await updateRooms()
        }
    }
    
    private func updateRooms() async {
        // In a real implementation, this would get the rooms from the manager
        // For now, we'll just use sample rooms
        self.rooms = [
            Room(name: "Living Room", deviceIds: ["device1", "device2"], icon: "sofa"),
            Room(name: "Bedroom", deviceIds: ["device3"], icon: "bed.double"),
            Room(name: "Kitchen", deviceIds: ["device4", "device5"], icon: "refrigerator"),
            Room(name: "Office", deviceIds: ["device6"], icon: "desktopcomputer")
        ]
    }
    
    public func addRoom(_ room: Room) async {
        // In a real implementation, this would add the room to the manager
        await updateRooms()
    }
    
    public func removeRoom(_ room: Room) async {
        // In a real implementation, this would remove the room from the manager
        await updateRooms()
    }
    
    public func updateRoom(_ room: Room) async {
        // In a real implementation, this would update the room in the manager
        await updateRooms()
    }
    
    public func getRoom(withId id: String) -> Room? {
        return rooms.first { $0.id == id }
    }
    
    public func addDeviceToRoom(_ deviceId: String, roomId: String) async {
        // In a real implementation, this would add the device to the room
        await updateRooms()
    }
    
    public func removeDeviceFromRoom(_ deviceId: String, roomId: String) async {
        // In a real implementation, this would remove the device from the room
        await updateRooms()
    }
} 