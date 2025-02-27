import Foundation

class DeviceStorage {
    static let shared = DeviceStorage()
    
    private let defaults = UserDefaults.standard
    private let deviceKey = "saved_devices"
    private let roomsKey = "device_rooms"
    
    struct SavedDevice: Codable {
        let ip: String
        let port: Int
        let name: String
        let room: String
        var lastKnownState: DeviceState
        
        struct DeviceState: Codable {
            var isOn: Bool
            var brightness: Int
            var colorTemperature: Int
            var colorMode: Int
            var powerMode: Int
        }
    }
    
    func saveDevice(_ device: YeelightDevice, inRoom room: String) {
        var devices = loadDevices()
        let savedDevice = SavedDevice(
            ip: device.ip,
            port: device.port,
            name: device.name,
            room: room,
            lastKnownState: .init(
                isOn: device.isOn,
                brightness: device.brightness,
                colorTemperature: device.colorTemperature,
                colorMode: device.colorMode.rawValue,
                powerMode: device.powerMode.rawValue
            )
        )
        
        devices[device.ip] = savedDevice
        
        if let encoded = try? JSONEncoder().encode(devices) {
            defaults.set(encoded, forKey: deviceKey)
        }
    }
    
    func loadDevices() -> [String: SavedDevice] {
        guard let data = defaults.data(forKey: deviceKey),
              let devices = try? JSONDecoder().decode([String: SavedDevice].self, from: data)
        else {
            return [:]
        }
        return devices
    }
    
    // Room management
    func saveRoom(_ name: String, icon: String) {
        var rooms = loadRooms()
        rooms[name] = icon
        defaults.set(rooms, forKey: roomsKey)
    }
    
    func loadRooms() -> [String: String] {
        defaults.dictionary(forKey: roomsKey) as? [String: String] ?? [
            "Living Room": "sofa.fill",
            "Bedroom": "bed.double.fill",
            "Kitchen": "cooktop.fill"
        ]
    }
} 