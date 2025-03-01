import SwiftUI
import Core

@main
struct YeelightControlApp: App {
    // MARK: - Properties
    
    private let serviceContainer = UnifiedServiceContainer.shared
    
    @StateObject private var deviceManager: DeviceManagerObject
    @StateObject private var effectManager: EffectManagerObject
    @StateObject private var sceneManager: SceneManagerObject
    @StateObject private var configurationManager: ConfigurationManagerObject
    
    // MARK: - Initialization
    
    init() {
        let deviceManager = DeviceManagerObject(manager: serviceContainer.deviceManager)
        let effectManager = EffectManagerObject(manager: serviceContainer.effectManager)
        let sceneManager = SceneManagerObject(manager: serviceContainer.sceneManager)
        let configurationManager = ConfigurationManagerObject(manager: serviceContainer.configurationManager)
        
        _deviceManager = StateObject(wrappedValue: deviceManager)
        _effectManager = StateObject(wrappedValue: effectManager)
        _sceneManager = StateObject(wrappedValue: sceneManager)
        _configurationManager = StateObject(wrappedValue: configurationManager)
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deviceManager)
                .environmentObject(effectManager)
                .environmentObject(sceneManager)
                .environmentObject(configurationManager)
                .task {
                    // Start device discovery when app launches
                    await deviceManager.startDiscovery()
                }
        }
    }
}

// MARK: - Observable Wrappers for Actor-based Managers

class DeviceManagerObject: ObservableObject {
    private let manager: any DeviceManaging
    private var cancellables = Set<AnyCancellable>()
    
    @Published var devices: [Device] = []
    @Published var isDiscovering: Bool = false
    
    init(manager: any DeviceManaging) {
        self.manager = manager
        
        // Subscribe to device updates
        manager.deviceUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshDevices()
                }
            }
            .store(in: &cancellables)
        
        // Initial load
        Task {
            await refreshDevices()
            await refreshDiscoveryState()
        }
    }
    
    func getDevice(byId id: String) async -> Device? {
        await manager.getDevice(byId: id)
    }
    
    func startDiscovery() async {
        await manager.startDiscovery()
        await refreshDiscoveryState()
    }
    
    func stopDiscovery() async {
        await manager.stopDiscovery()
        await refreshDiscoveryState()
    }
    
    func addDevice(_ device: Device) async {
        await manager.addDevice(device)
        await refreshDevices()
    }
    
    func updateDevice(_ device: Device) async {
        await manager.updateDevice(device)
        await refreshDevices()
    }
    
    func removeDevice(_ device: Device) async {
        await manager.removeDevice(device)
        await refreshDevices()
    }
    
    func updateDeviceState(_ device: Device, newState: DeviceState) async {
        try? await manager.updateDeviceState(device, newState: newState)
        await refreshDevices()
    }
    
    private func refreshDevices() async {
        let updatedDevices = await manager.getAllDevices()
        await MainActor.run {
            self.devices = updatedDevices
        }
    }
    
    private func refreshDiscoveryState() async {
        if let manager = manager as? UnifiedDeviceManager {
            let isDiscovering = await manager.isDiscovering
            await MainActor.run {
                self.isDiscovering = isDiscovering
            }
        }
    }
}

class EffectManagerObject: ObservableObject {
    private let manager: any EffectManaging
    private var cancellables = Set<AnyCancellable>()
    
    @Published var effects: [Effect] = []
    
    init(manager: any EffectManaging) {
        self.manager = manager
        
        // Subscribe to effect updates
        manager.effectUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshEffects()
                }
            }
            .store(in: &cancellables)
        
        // Initial load
        Task {
            await refreshEffects()
        }
    }
    
    func getEffect(withId id: String) async -> Effect? {
        await manager.getEffect(withId: id)
    }
    
    func createEffect(name: String, type: EffectType, parameters: EffectParameters) async -> Effect {
        let effect = await manager.createEffect(name: name, type: type, parameters: parameters)
        await refreshEffects()
        return effect
    }
    
    func updateEffect(_ effect: Effect) async -> Effect {
        let updatedEffect = await manager.updateEffect(effect)
        await refreshEffects()
        return updatedEffect
    }
    
    func deleteEffect(_ effect: Effect) async {
        await manager.deleteEffect(effect)
        await refreshEffects()
    }
    
    func startEffect(_ effect: Effect) async {
        await manager.startEffect(effect)
        await refreshEffects()
    }
    
    func stopEffect(_ effect: Effect) async {
        await manager.stopEffect(effect)
        await refreshEffects()
    }
    
    func applyEffect(_ effect: Effect, to deviceIds: [String]) async {
        await manager.applyEffect(effect, to: deviceIds)
    }
    
    private func refreshEffects() async {
        let updatedEffects = await manager.getAllEffects()
        await MainActor.run {
            self.effects = updatedEffects
        }
    }
}

class SceneManagerObject: ObservableObject {
    private let manager: any SceneManaging
    private var cancellables = Set<AnyCancellable>()
    
    @Published var scenes: [Scene] = []
    
    init(manager: any SceneManaging) {
        self.manager = manager
        
        // Subscribe to scene updates
        manager.sceneUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshScenes()
                }
            }
            .store(in: &cancellables)
        
        // Initial load
        Task {
            await refreshScenes()
        }
    }
    
    func getScene(withId id: String) async -> Scene? {
        await manager.getScene(withId: id)
    }
    
    func createScene(name: String, deviceIds: [String], effect: Effect?) async -> Scene {
        let scene = await manager.createScene(name: name, deviceIds: deviceIds, effect: effect)
        await refreshScenes()
        return scene
    }
    
    func updateScene(_ scene: Scene) async -> Scene {
        let updatedScene = await manager.updateScene(scene)
        await refreshScenes()
        return updatedScene
    }
    
    func deleteScene(_ scene: Scene) async {
        await manager.deleteScene(scene)
        await refreshScenes()
    }
    
    func activateScene(_ scene: Scene) async {
        await manager.activateScene(scene)
        await refreshScenes()
    }
    
    func deactivateScene(_ scene: Scene) async {
        await manager.deactivateScene(scene)
        await refreshScenes()
    }
    
    func scheduleScene(_ scene: Scene, schedule: SceneSchedule) async -> Scene {
        let updatedScene = await manager.scheduleScene(scene, schedule: schedule)
        await refreshScenes()
        return updatedScene
    }
    
    private func refreshScenes() async {
        let updatedScenes = await manager.getAllScenes()
        await MainActor.run {
            self.scenes = updatedScenes
        }
    }
}

class ConfigurationManagerObject: ObservableObject {
    private let manager: any ConfigurationManaging
    private var cancellables = Set<AnyCancellable>()
    
    @Published var configuration: Configuration = Configuration()
    
    init(manager: any ConfigurationManaging) {
        self.manager = manager
        
        // Subscribe to configuration updates
        manager.configurationUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] configuration in
                self?.configuration = configuration
            }
            .store(in: &cancellables)
        
        // Initial load
        Task {
            await refreshConfiguration()
        }
    }
    
    func updateConfiguration(_ configuration: Configuration) async {
        await manager.updateConfiguration(configuration)
        await refreshConfiguration()
    }
    
    func resetConfiguration() async {
        await manager.resetConfiguration()
        await refreshConfiguration()
    }
    
    private func refreshConfiguration() async {
        let updatedConfiguration = await manager.getConfiguration()
        await MainActor.run {
            self.configuration = updatedConfiguration
        }
    }
} 