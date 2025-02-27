import Foundation
import Combine

protocol RoomManaging {
    func createRoom(_ room: Room) async throws
    func updateRoom(_ room: Room) async throws
    func deleteRoom(_ id: String) async throws
    func getRoom(_ id: String) async throws -> Room
    func getAllRooms() async throws -> [Room]
    func addDevice(_ deviceId: String, to roomId: String) async throws
    func removeDevice(_ deviceId: String, from roomId: String) async throws
    func getDevicesInRoom(_ roomId: String) async throws -> [Device]
    var roomsPublisher: AnyPublisher<[Room], Never> { get }
}

struct Room: Codable, Identifiable {
    let id: String
    var name: String
    var icon: String?
    var deviceIds: [String]
    var floor: Int?
    var position: RoomPosition?
    var createdAt: Date
    var updatedAt: Date
}

struct RoomPosition: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

final class RoomManager: RoomManaging {
    private let services: ServiceContainer
    private let storage: StorageManaging
    private let deviceManager: DeviceManaging
    private let roomsSubject = CurrentValueSubject<[Room], Never>([])
    private var subscriptions = Set<AnyCancellable>()
    
    init(services: ServiceContainer) {
        self.services = services
        self.storage = services.storageManager
        self.deviceManager = services.deviceManager
        
        setupSubscriptions()
        loadRooms()
    }
    
    var roomsPublisher: AnyPublisher<[Room], Never> {
        roomsSubject.eraseToAnyPublisher()
    }
    
    func createRoom(_ room: Room) async throws {
        var rooms = roomsSubject.value
        
        // Validate room
        try await validateRoom(room)
        
        rooms.append(room)
        try await saveRooms(rooms)
        roomsSubject.send(rooms)
    }
    
    func updateRoom(_ room: Room) async throws {
        var rooms = roomsSubject.value
        guard let index = rooms.firstIndex(where: { $0.id == room.id }) else {
            throw RoomError.notFound
        }
        
        // Validate room
        try await validateRoom(room)
        
        rooms[index] = room
        try await saveRooms(rooms)
        roomsSubject.send(rooms)
    }
    
    func deleteRoom(_ id: String) async throws {
        var rooms = roomsSubject.value
        guard let index = rooms.firstIndex(where: { $0.id == id }) else {
            throw RoomError.notFound
        }
        
        // Check if room has devices
        let room = rooms[index]
        if !room.deviceIds.isEmpty {
            throw RoomError.roomNotEmpty
        }
        
        rooms.remove(at: index)
        try await saveRooms(rooms)
        roomsSubject.send(rooms)
    }
    
    func getRoom(_ id: String) async throws -> Room {
        guard let room = roomsSubject.value.first(where: { $0.id == id }) else {
            throw RoomError.notFound
        }
        return room
    }
    
    func getAllRooms() async throws -> [Room] {
        return roomsSubject.value
    }
    
    func addDevice(_ deviceId: String, to roomId: String) async throws {
        // Verify device exists
        guard let _ = try? await deviceManager.getDevice(deviceId) else {
            throw RoomError.deviceNotFound
        }
        
        var rooms = roomsSubject.value
        guard let index = rooms.firstIndex(where: { $0.id == roomId }) else {
            throw RoomError.notFound
        }
        
        // Check if device is already in another room
        if let existingRoom = rooms.first(where: { $0.deviceIds.contains(deviceId) }) {
            throw RoomError.deviceAlreadyInRoom(existingRoom.id)
        }
        
        rooms[index].deviceIds.append(deviceId)
        try await saveRooms(rooms)
        roomsSubject.send(rooms)
    }
    
    func removeDevice(_ deviceId: String, from roomId: String) async throws {
        var rooms = roomsSubject.value
        guard let index = rooms.firstIndex(where: { $0.id == roomId }) else {
            throw RoomError.notFound
        }
        
        guard let deviceIndex = rooms[index].deviceIds.firstIndex(of: deviceId) else {
            throw RoomError.deviceNotInRoom
        }
        
        rooms[index].deviceIds.remove(at: deviceIndex)
        try await saveRooms(rooms)
        roomsSubject.send(rooms)
    }
    
    func getDevicesInRoom(_ roomId: String) async throws -> [Device] {
        let room = try await getRoom(roomId)
        var devices: [Device] = []
        
        for deviceId in room.deviceIds {
            if let device = try? await deviceManager.getDevice(deviceId) {
                devices.append(device)
            }
        }
        
        return devices
    }
    
    private func setupSubscriptions() {
        deviceManager.deviceStatePublisher
            .sink { [weak self] updates in
                Task {
                    await self?.handleDeviceStateUpdates(updates)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func loadRooms() {
        Task {
            do {
                let rooms: [Room] = try await storage.load(.rooms)
                roomsSubject.send(rooms)
            } catch {
                print("Failed to load rooms: \(error)")
                roomsSubject.send([])
            }
        }
    }
    
    private func saveRooms(_ rooms: [Room]) async throws {
        try await storage.save(rooms, for: .rooms)
    }
    
    private func validateRoom(_ room: Room) async throws {
        // Check for duplicate names
        let rooms = roomsSubject.value
        if let existingRoom = rooms.first(where: { $0.name == room.name && $0.id != room.id }) {
            throw RoomError.duplicateName
        }
        
        // Validate devices exist
        for deviceId in room.deviceIds {
            guard let _ = try? await deviceManager.getDevice(deviceId) else {
                throw RoomError.deviceNotFound
            }
        }
        
        // Validate position if present
        if let position = room.position {
            if position.width <= 0 || position.height <= 0 {
                throw RoomError.invalidPosition
            }
        }
    }
    
    private func handleDeviceStateUpdates(_ updates: [DeviceStateUpdate]) async {
        // Handle device state changes that might affect rooms
        // For example, update room status based on device states
    }
}

enum RoomError: LocalizedError {
    case notFound
    case deviceNotFound
    case deviceNotInRoom
    case deviceAlreadyInRoom(String)
    case roomNotEmpty
    case duplicateName
    case invalidPosition
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "Room not found"
        case .deviceNotFound: return "Device not found"
        case .deviceNotInRoom: return "Device is not in this room"
        case .deviceAlreadyInRoom(let roomId): return "Device is already in room \(roomId)"
        case .roomNotEmpty: return "Cannot delete room with devices"
        case .duplicateName: return "Room name already exists"
        case .invalidPosition: return "Invalid room position"
        }
    }
} 