import SwiftUI
import Core

/// Observable wrapper for UnifiedRoomManager
@MainActor
public class ObservableRoomManager: ObservableObject {
    private let manager: UnifiedRoomManager
    @Published public private(set) var rooms: [Room] = []
    
    public init(manager: UnifiedRoomManager) {
        self.manager = manager
        setupSubscriptions()
        Task {
            await updateRooms()
        }
    }
    
    private func setupSubscriptions() {
        // Subscribe to room updates from the manager
        // This would be implemented in a real application
    }
    
    private func updateRooms() async {
        do {
            let managerRooms = try await manager.getAllRooms()
            self.rooms = managerRooms
        } catch {
            print("Error fetching rooms: \(error)")
            self.rooms = []
        }
    }
    
    public func addRoom(_ room: Room) async {
        do {
            try await manager.createRoom(room)
            await updateRooms()
        } catch {
            print("Error adding room: \(error)")
        }
    }
    
    public func removeRoom(_ room: Room) async {
        do {
            try await manager.deleteRoom(room.id)
            await updateRooms()
        } catch {
            print("Error removing room: \(error)")
        }
    }
    
    public func updateRoom(_ room: Room) async {
        do {
            try await manager.updateRoom(room)
            await updateRooms()
        } catch {
            print("Error updating room: \(error)")
        }
    }
    
    public func getRoom(withId id: String) -> Room? {
        return rooms.first { $0.id == id }
    }
    
    public func addDeviceToRoom(_ deviceId: String, roomId: String) async {
        do {
            try await manager.addDevice(deviceId, to: roomId)
            await updateRooms()
        } catch {
            print("Error adding device to room: \(error)")
        }
    }
    
    public func removeDeviceFromRoom(_ deviceId: String, roomId: String) async {
        do {
            try await manager.removeDevice(deviceId, from: roomId)
            await updateRooms()
        } catch {
            print("Error removing device from room: \(error)")
        }
    }
} 