import Foundation

class DeviceStorage {
    static let shared = DeviceStorage()
    
    private let defaults = UserDefaults.standard
    private let deviceKey = "saved_devices"
    private let roomsKey = "device_rooms"
    private let scenesKey = "saved_scenes"
    private let groupsKey = "device_groups"
    private let syncGroupsKey = "sync_groups"
    private let automationsKey = "saved_automations"
    
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
    
    // MARK: - Device Management
    
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
    
    // MARK: - Room Management
    
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
    
    // MARK: - Scene Management
    
    func saveCustomScene(name: String, scene: YeelightManager.Scene, devices: [String]) {
        var scenes = loadSavedScenes()
        let newScene = ScenePreset(
            name: name,
            icon: scene.icon,
            scene: scene,
            description: "Custom scene",
            tags: ["custom"],
            isCustom: true
        )
        scenes.append(newScene)
        
        if let encoded = try? JSONEncoder().encode(scenes) {
            defaults.set(encoded, forKey: scenesKey)
        }
    }
    
    func loadSavedScenes() -> [ScenePreset] {
        guard let data = defaults.data(forKey: scenesKey),
              let scenes = try? JSONDecoder().decode([ScenePreset].self, from: data)
        else {
            return []
        }
        return scenes
    }
    
    func deleteScene(_ id: UUID) {
        var scenes = loadSavedScenes()
        scenes.removeAll { $0.id == id }
        
        if let encoded = try? JSONEncoder().encode(scenes) {
            defaults.set(encoded, forKey: scenesKey)
        }
    }
    
    // MARK: - Group Management
    
    func saveGroups(_ groups: [DeviceGroupManager.DeviceGroup]) {
        if let encoded = try? JSONEncoder().encode(groups) {
            defaults.set(encoded, forKey: groupsKey)
        }
    }
    
    func loadGroups() -> [DeviceGroupManager.DeviceGroup] {
        guard let data = defaults.data(forKey: groupsKey),
              let groups = try? JSONDecoder().decode([DeviceGroupManager.DeviceGroup].self, from: data)
        else {
            return []
        }
        return groups
    }
    
    func saveSyncGroups(_ groups: [DeviceGroupCoordinator.SyncGroup]) {
        if let encoded = try? JSONEncoder().encode(groups) {
            defaults.set(encoded, forKey: syncGroupsKey)
        }
    }
    
    func loadSyncGroups() -> [DeviceGroupCoordinator.SyncGroup] {
        guard let data = defaults.data(forKey: syncGroupsKey),
              let groups = try? JSONDecoder().decode([DeviceGroupCoordinator.SyncGroup].self, from: data)
        else {
            return []
        }
        return groups
    }
    
    // MARK: - Automation Management
    
    func saveAutomation(_ automation: Automation) {
        var automations = loadAutomations()
        automations.append(automation)
        
        if let encoded = try? JSONEncoder().encode(automations) {
            defaults.set(encoded, forKey: automationsKey)
        }
    }
    
    func loadAutomations() -> [Automation] {
        guard let data = defaults.data(forKey: automationsKey),
              let automations = try? JSONDecoder().decode([Automation].self, from: data)
        else {
            return []
        }
        return automations
    }
    
    func deleteAutomation(_ id: UUID) {
        var automations = loadAutomations()
        automations.removeAll { $0.id == id }
        
        if let encoded = try? JSONEncoder().encode(automations) {
            defaults.set(encoded, forKey: automationsKey)
        }
    }
    
    func updateAutomation(_ automation: Automation) {
        var automations = loadAutomations()
        if let index = automations.firstIndex(where: { $0.id == automation.id }) {
            automations[index] = automation
            
            if let encoded = try? JSONEncoder().encode(automations) {
                defaults.set(encoded, forKey: automationsKey)
            }
        }
    }
} 