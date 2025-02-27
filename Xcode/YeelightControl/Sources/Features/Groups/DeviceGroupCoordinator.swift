import Foundation
import Combine

class DeviceGroupCoordinator: ObservableObject {
    static let shared = DeviceGroupCoordinator()
    
    @Published private(set) var syncGroups: [SyncGroup] = []
    private var cancellables = Set<AnyCancellable>()
    
    struct SyncGroup: Identifiable, Codable {
        let id: UUID
        var name: String
        var deviceIPs: Set<String>
        var syncMode: SyncMode
        var masterDevice: String? // IP of the device others should sync with
        
        enum SyncMode: String, Codable {
            case mirror // All devices mirror the master
            case alternate // Devices alternate states
            case sequence // Effects flow through devices in sequence
            case random // Random but synchronized changes
        }
    }
    
    init() {
        setupDeviceMonitoring()
        loadSyncGroups()
    }
    
    private func setupDeviceMonitoring() {
        // Monitor device state changes and sync accordingly
        NotificationCenter.default.publisher(for: .deviceStateChanged)
            .sink { [weak self] notification in
                guard let deviceIP = notification.object as? String else { return }
                self?.handleDeviceStateChange(deviceIP)
            }
            .store(in: &cancellables)
    }
    
    func createSyncGroup(name: String, devices: [YeelightDevice], mode: SyncGroup.SyncMode) {
        let group = SyncGroup(
            id: UUID(),
            name: name,
            deviceIPs: Set(devices.map { $0.ip }),
            syncMode: mode,
            masterDevice: devices.first?.ip
        )
        syncGroups.append(group)
        saveSyncGroups()
    }
    
    func updateSyncGroup(_ group: SyncGroup) {
        guard let index = syncGroups.firstIndex(where: { $0.id == group.id }) else { return }
        syncGroups[index] = group
        saveSyncGroups()
    }
    
    private func handleDeviceStateChange(_ deviceIP: String) {
        guard let device = YeelightManager.shared.devices.first(where: { $0.ip == deviceIP }) else { return }
        
        // Find groups containing this device
        for group in syncGroups {
            guard group.deviceIPs.contains(deviceIP) else { continue }
            
            // If this is the master device, sync others
            if group.masterDevice == deviceIP {
                syncDevicesInGroup(group, withState: device)
            }
        }
    }
    
    private func syncDevicesInGroup(_ group: SyncGroup, withState masterDevice: YeelightDevice) {
        let manager = YeelightManager.shared
        
        for deviceIP in group.deviceIPs where deviceIP != masterDevice.ip {
            guard let device = manager.devices.first(where: { $0.ip == deviceIP }) else { continue }
            
            switch group.syncMode {
            case .mirror:
                syncDeviceState(device, withMaster: masterDevice)
            case .alternate:
                manager.setPower(device, on: !masterDevice.isOn)
            case .sequence:
                // Implement sequence logic
                break
            case .random:
                // Implement random sync logic
                break
            }
        }
    }
    
    private func syncDeviceState(_ device: YeelightDevice, withMaster master: YeelightDevice) {
        let manager = YeelightManager.shared
        
        // Sync power state
        manager.setPower(device, on: master.isOn)
        
        // Sync brightness
        manager.setBrightness(device, brightness: master.brightness)
        
        // Sync color/temperature based on mode
        if master.colorMode == .color {
            manager.setRGB(
                device,
                red: master.color.red,
                green: master.color.green,
                blue: master.color.blue
            )
        } else {
            manager.setColorTemperature(device, temperature: master.colorTemperature)
        }
    }
    
    private func loadSyncGroups() {
        syncGroups = DeviceStorage.shared.loadSyncGroups()
    }
    
    private func saveSyncGroups() {
        DeviceStorage.shared.saveSyncGroups(syncGroups)
    }
}

// Notification for device state changes
extension Notification.Name {
    static let deviceStateChanged = Notification.Name("deviceStateChanged")
} 