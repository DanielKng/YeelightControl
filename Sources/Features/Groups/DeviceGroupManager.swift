import Foundation
import Combine

class DeviceGroupManager: ObservableObject {
    @Published private(set) var groups: [DeviceGroup] = []
    private let storage = DeviceStorage.shared
    
    struct DeviceGroup: Identifiable, Codable {
        let id: UUID
        var name: String
        var icon: String
        var deviceIPs: Set<String>
        var syncMode: SyncMode
        
        enum SyncMode: String, Codable {
            case mirror // All devices mirror the first device
            case alternate // Devices alternate states
            case wave // Effects flow through devices in sequence
            case random // Each device acts independently but synchronized
        }
    }
    
    init() {
        loadGroups()
    }
    
    func createGroup(name: String, icon: String, devices: [YeelightDevice], syncMode: DeviceGroup.SyncMode) {
        let group = DeviceGroup(
            id: UUID(),
            name: name,
            icon: icon,
            deviceIPs: Set(devices.map { $0.ip }),
            syncMode: syncMode
        )
        groups.append(group)
        saveGroups()
    }
    
    func deleteGroup(_ group: DeviceGroup) {
        groups.removeAll { $0.id == group.id }
        saveGroups()
    }
    
    func addDevice(_ device: YeelightDevice, toGroup groupId: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[index].deviceIPs.insert(device.ip)
        saveGroups()
    }
    
    func removeDevice(_ device: YeelightDevice, fromGroup groupId: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }
        groups[index].deviceIPs.remove(device.ip)
        saveGroups()
    }
    
    // Synchronized control methods
    func setGroupPower(_ group: DeviceGroup, on: Bool, using manager: YeelightManager) {
        let devices = getDevicesInGroup(group, from: manager)
        
        switch group.syncMode {
        case .mirror:
            devices.forEach { manager.setPower($0, on: on) }
            
        case .alternate:
            for (index, device) in devices.enumerated() {
                manager.setPower(device, on: index % 2 == 0 ? on : !on)
            }
            
        case .wave:
            for (index, device) in devices.enumerated() {
                let delay = index * 200 // 200ms delay between each device
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                    manager.setPower(device, on: on)
                }
            }
            
        case .random:
            devices.forEach { device in
                let randomDelay = Int.random(in: 0...1000)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(randomDelay)) {
                    manager.setPower(device, on: on)
                }
            }
        }
    }
    
    func applyGroupEffect(_ group: DeviceGroup, effect: GroupEffect, using manager: YeelightManager) {
        let devices = getDevicesInGroup(group, from: manager)
        
        switch effect {
        case .rainbow:
            applyRainbowEffect(to: devices, using: manager)
        case .wave(let color):
            applyWaveEffect(to: devices, color: color, using: manager)
        case .pulse(let colors):
            applyPulseEffect(to: devices, colors: colors, using: manager)
        case .fade(let fromColor, let toColor):
            applyFadeEffect(to: devices, from: fromColor, to: toColor, using: manager)
        }
    }
    
    private func getDevicesInGroup(_ group: DeviceGroup, from manager: YeelightManager) -> [YeelightDevice] {
        return manager.devices.filter { group.deviceIPs.contains($0.ip) }
    }
    
    private func loadGroups() {
        groups = storage.loadGroups()
    }
    
    private func saveGroups() {
        storage.saveGroups(groups)
    }
}

// Group effects
enum GroupEffect {
    case rainbow
    case wave(Color)
    case pulse([Color])
    case fade(from: Color, to: Color)
}

// Effect implementations
extension DeviceGroupManager {
    private func applyRainbowEffect(to devices: [YeelightDevice], using manager: YeelightManager) {
        let totalDevices = devices.count
        for (index, device) in devices.enumerated() {
            let hue = Double(index) / Double(totalDevices) * 360
            manager.setHSV(device, hue: Int(hue), saturation: 100)
        }
    }
    
    private func applyWaveEffect(to devices: [YeelightDevice], color: Color, using manager: YeelightManager) {
        let components = UIColor(color).cgColor.components ?? [1, 1, 1, 1]
        let rgb = (Int(components[0] * 255), Int(components[1] * 255), Int(components[2] * 255))
        
        for (index, device) in devices.enumerated() {
            let delay = index * 200
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                manager.setRGB(device, red: rgb.0, green: rgb.1, blue: rgb.2)
            }
        }
    }
    
    private func applyPulseEffect(to devices: [YeelightDevice], colors: [Color], using manager: YeelightManager) {
        for device in devices {
            var transitions: [YeelightDevice.FlowParams.FlowTransition] = []
            
            for color in colors {
                let components = UIColor(color).cgColor.components ?? [1, 1, 1, 1]
                let rgb = (Int(components[0] * 255) * 65536) +
                         (Int(components[1] * 255) * 256) +
                         Int(components[2] * 255)
                
                transitions.append(.init(
                    duration: 1000,
                    mode: 1,
                    value: rgb,
                    brightness: 100
                ))
            }
            
            manager.startColorFlow(device, params: .init(
                count: 0,
                action: .recover,
                transitions: transitions
            ))
        }
    }
    
    private func applyFadeEffect(to devices: [YeelightDevice], from: Color, to: Color, using manager: YeelightManager) {
        let fromComponents = UIColor(from).cgColor.components ?? [1, 1, 1, 1]
        let toComponents = UIColor(to).cgColor.components ?? [1, 1, 1, 1]
        
        let fromRGB = (Int(fromComponents[0] * 255) * 65536) +
                     (Int(fromComponents[1] * 255) * 256) +
                     Int(fromComponents[2] * 255)
        
        let toRGB = (Int(toComponents[0] * 255) * 65536) +
                   (Int(toComponents[1] * 255) * 256) +
                   Int(toComponents[2] * 255)
        
        for device in devices {
            manager.startColorFlow(device, params: .init(
                count: 1,
                action: .stay,
                transitions: [
                    .init(duration: 3000, mode: 1, value: fromRGB, brightness: 100),
                    .init(duration: 3000, mode: 1, value: toRGB, brightness: 100)
                ]
            ))
        }
    }
} 