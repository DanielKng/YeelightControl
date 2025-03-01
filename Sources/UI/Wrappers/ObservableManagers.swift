import SwiftUI
import Core
import Combine

// MARK: - ObservableDeviceManager

/// Observable wrapper for UnifiedDeviceManager
@MainActor
public class ObservableDeviceManager: ObservableObject {
    private let manager: UnifiedDeviceManager
    @Published public private(set) var devices: [Device] = []
    
    public init(manager: UnifiedDeviceManager) {
        self.manager = manager
        Task {
            await updateDevices()
        }
    }
    
    private func updateDevices() async {
        self.devices = await manager.devices
    }
    
    public func addDevice(_ device: Device) async {
        await manager.addDevice(device)
        await updateDevices()
    }
    
    public func removeDevice(_ device: Device) async {
        await manager.removeDevice(device)
        await updateDevices()
    }
    
    public func updateDevice(_ device: Device) async {
        await manager.updateDevice(device)
        await updateDevices()
    }
    
    public func getDevice(withId id: String) -> Device? {
        return devices.first { $0.id == id }
    }
}

// MARK: - ObservableEffectManager

/// Observable wrapper for UnifiedEffectManager
@MainActor
public class ObservableEffectManager: ObservableObject {
    private let manager: UnifiedEffectManager
    @Published public private(set) var effects: [Effect] = []
    
    public init(manager: UnifiedEffectManager) {
        self.manager = manager
        Task {
            await updateEffects()
        }
    }
    
    private func updateEffects() async {
        self.effects = await manager.effects
    }
    
    public func addEffect(_ effect: Effect) async {
        await manager.addEffect(effect)
        await updateEffects()
    }
    
    public func removeEffect(_ effect: Effect) async {
        await manager.removeEffect(effect)
        await updateEffects()
    }
    
    public func updateEffect(_ effect: Effect) async {
        await manager.updateEffect(effect)
        await updateEffects()
    }
    
    public func getEffect(withId id: String) -> Effect? {
        return effects.first { $0.id == id }
    }
    
    public func applyEffect(_ effect: Effect, to device: YeelightDevice) async throws {
        try await manager.applyEffect(effect, to: device)
    }
}

// MARK: - ObservableSceneManager

/// Observable wrapper for UnifiedSceneManager
@MainActor
public class ObservableSceneManager: ObservableObject {
    private let manager: UnifiedSceneManager
    @Published public private(set) var scenes: [any YeelightScene] = []
    
    public init(manager: UnifiedSceneManager) {
        self.manager = manager
        Task {
            await updateScenes()
        }
    }
    
    private func updateScenes() async {
        self.scenes = manager.scenes
    }
    
    public func addScene(_ scene: any YeelightScene) {
        manager.addScene(scene as! Scene)
        Task {
            await updateScenes()
        }
    }
    
    public func deleteScene(_ scene: any YeelightScene) {
        manager.deleteScene(scene as! Scene)
        Task {
            await updateScenes()
        }
    }
    
    public func deleteScene(at indexSet: IndexSet) {
        manager.deleteScene(at: indexSet)
        Task {
            await updateScenes()
        }
    }
    
    public func updateScene(_ scene: any YeelightScene) {
        manager.updateScene(scene as! Scene)
        Task {
            await updateScenes()
        }
    }
    
    public func activateScene(_ scene: any YeelightScene) {
        manager.activateScene(scene as! Scene)
    }
    
    public func getScene(withId id: String) -> (any YeelightScene)? {
        return scenes.first { $0.id == id }
    }
}

// MARK: - ObservableNetworkManager

/// Observable wrapper for UnifiedNetworkManager
@MainActor
public class ObservableNetworkManager: ObservableObject {
    private let manager: UnifiedNetworkManager
    @Published public private(set) var isConnected: Bool = false
    @Published public private(set) var connectionType: String = "Unknown"
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(manager: UnifiedNetworkManager) {
        self.manager = manager
        setupPublishers()
    }
    
    private func setupPublishers() {
        manager.connectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isConnected = isConnected
            }
            .store(in: &cancellables)
        
        // In a real implementation, this would also observe the connection type
        self.isConnected = manager.isConnected
        self.connectionType = manager.connectionType
    }
    
    public func startMonitoring() {
        manager.startMonitoring()
    }
    
    public func stopMonitoring() {
        manager.stopMonitoring()
    }
    
    public var connectionPublisher: AnyPublisher<Bool, Never> {
        $isConnected.eraseToAnyPublisher()
    }
}

// MARK: - ObservableLocationManager

/// Observable wrapper for UnifiedLocationManager
@MainActor
public class ObservableLocationManager: ObservableObject {
    private let manager: UnifiedLocationManager
    @Published public private(set) var currentLocation: CLLocation?
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    public init(manager: UnifiedLocationManager) {
        self.manager = manager
        Task {
            await updateLocation()
        }
    }
    
    private func updateLocation() async {
        self.currentLocation = await manager.currentLocation
        self.authorizationStatus = await manager.authorizationStatus
    }
    
    public func startMonitoring() async {
        await manager.startMonitoring()
        await updateLocation()
    }
    
    public func stopMonitoring() async {
        await manager.stopMonitoring()
    }
    
    public func requestAuthorization() async {
        await manager.requestAuthorization()
        await updateLocation()
    }
}

// MARK: - ObservableStorageManager

/// Observable wrapper for UnifiedStorageManager
@MainActor
public class ObservableStorageManager: ObservableObject {
    private let manager: UnifiedStorageManager
    
    public init(manager: UnifiedStorageManager) {
        self.manager = manager
    }
    
    public func saveData<T: Encodable>(_ data: T, forKey key: String) async throws {
        try await manager.saveData(data, forKey: key)
    }
    
    public func loadData<T: Decodable>(forKey key: String) async throws -> T {
        return try await manager.loadData(forKey: key)
    }
    
    public func deleteData(forKey key: String) async throws {
        try await manager.deleteData(forKey: key)
    }
    
    public func clearAllData() async throws {
        try await manager.clearAllData()
    }
}

// MARK: - Type Imports

import CoreLocation 