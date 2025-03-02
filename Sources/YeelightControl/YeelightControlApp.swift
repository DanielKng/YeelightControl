import SwiftUI
import Core
import UI

@main
struct YeelightControlApp: App {
    // MARK: - Properties
    
    private let serviceContainer = UnifiedServiceContainer.shared
    
    @StateObject private var uiEnvironment: UIEnvironment
    
    // MARK: - Initialization
    
    init() {
        // Initialize the service container
        initializeServiceContainer()
        
        // Create the UI environment
        let environment = UIEnvironment(container: serviceContainer)
        _uiEnvironment = StateObject(wrappedValue: environment)
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(uiEnvironment)
                .environmentObject(serviceContainer.deviceManager)
                .environmentObject(serviceContainer.yeelightManager)
                .environmentObject(serviceContainer.sceneManager)
                .environmentObject(serviceContainer.effectManager)
                .environmentObject(serviceContainer.roomManager)
                .environmentObject(serviceContainer.networkManager)
                .environmentObject(serviceContainer.themeManager)
                .task {
                    // Start device discovery when app launches
                    try? await serviceContainer.yeelightManager.discover()
                }
        }
    }
    
    // MARK: - Private Methods
    
    private func initializeServiceContainer() {
        // Create and configure the storage manager
        let storageManager = UnifiedStorageManager()
        
        // Create and configure the network manager
        let networkManager = UnifiedNetworkManager()
        
        // Create and configure the Yeelight manager
        let yeelightManager = UnifiedYeelightManager(
            storageManager: storageManager,
            networkManager: networkManager
        )
        
        // Create and configure the device manager
        let deviceManager = UnifiedDeviceManager()
        
        // Create and configure the scene manager
        let sceneManager = UnifiedSceneManager()
        
        // Create and configure the effect manager
        let effectManager = UnifiedEffectManager()
        
        // Create and configure the error manager
        let errorManager = UnifiedErrorManager()
        
        // Set up the service container
        serviceContainer.registerService(storageManager as any Core_StorageManaging, for: \.storageManager)
        serviceContainer.registerService(networkManager as any Core_NetworkManaging, for: \.networkManager)
        serviceContainer.registerService(yeelightManager as any Core_YeelightManaging, for: \.yeelightManager)
        serviceContainer.registerService(deviceManager as any Core_DeviceManaging, for: \.deviceManager)
        serviceContainer.registerService(sceneManager as any Core_SceneManaging, for: \.sceneManager)
        serviceContainer.registerService(effectManager as any Core_EffectManaging, for: \.effectManager)
        serviceContainer.registerService(errorManager as any Core_ErrorHandling, for: \.errorHandler)
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