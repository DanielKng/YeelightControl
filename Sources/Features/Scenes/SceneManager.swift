import Foundation
import Combine

protocol SceneManaging {
    func createScene(_ scene: Scene) async throws
    func updateScene(_ scene: Scene) async throws
    func deleteScene(_ id: String) async throws
    func getScene(_ id: String) async throws -> Scene
    func getAllScenes() async throws -> [Scene]
    func activateScene(_ id: String) async throws
    func deactivateScene(_ id: String) async throws
    var scenesPublisher: AnyPublisher<[Scene], Never> { get }
}

struct Scene: Codable, Identifiable {
    let id: String
    var name: String
    var icon: String?
    var deviceStates: [String: DeviceState]
    var schedule: SceneSchedule?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
}

struct SceneSchedule: Codable {
    var daysOfWeek: Set<DayOfWeek>
    var startTime: TimeOfDay
    var endTime: TimeOfDay?
    var isEnabled: Bool
    
    enum DayOfWeek: Int, Codable, CaseIterable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }
}

final class SceneManager: SceneManaging {
    private let services: ServiceContainer
    private let storage: StorageManaging
    private let deviceManager: DeviceManaging
    private let scenesSubject = CurrentValueSubject<[Scene], Never>([])
    private var subscriptions = Set<AnyCancellable>()
    private var activeScenes: Set<String> = []
    private var scheduleTimer: Timer?
    
    init(services: ServiceContainer) {
        self.services = services
        self.storage = services.storageManager
        self.deviceManager = services.deviceManager
        
        setupSubscriptions()
        loadScenes()
        startScheduleTimer()
    }
    
    deinit {
        scheduleTimer?.invalidate()
    }
    
    var scenesPublisher: AnyPublisher<[Scene], Never> {
        scenesSubject.eraseToAnyPublisher()
    }
    
    func createScene(_ scene: Scene) async throws {
        var scenes = scenesSubject.value
        
        // Validate scene
        try await validateScene(scene)
        
        scenes.append(scene)
        try await saveScenes(scenes)
        scenesSubject.send(scenes)
    }
    
    func updateScene(_ scene: Scene) async throws {
        var scenes = scenesSubject.value
        guard let index = scenes.firstIndex(where: { $0.id == scene.id }) else {
            throw SceneError.notFound
        }
        
        // Validate scene
        try await validateScene(scene)
        
        scenes[index] = scene
        try await saveScenes(scenes)
        scenesSubject.send(scenes)
        
        // If scene is active, reapply it
        if activeScenes.contains(scene.id) {
            try await activateScene(scene.id)
        }
    }
    
    func deleteScene(_ id: String) async throws {
        var scenes = scenesSubject.value
        guard let index = scenes.firstIndex(where: { $0.id == id }) else {
            throw SceneError.notFound
        }
        
        // Deactivate scene if active
        if activeScenes.contains(id) {
            try await deactivateScene(id)
        }
        
        scenes.remove(at: index)
        try await saveScenes(scenes)
        scenesSubject.send(scenes)
    }
    
    func getScene(_ id: String) async throws -> Scene {
        guard let scene = scenesSubject.value.first(where: { $0.id == id }) else {
            throw SceneError.notFound
        }
        return scene
    }
    
    func getAllScenes() async throws -> [Scene] {
        return scenesSubject.value
    }
    
    func activateScene(_ id: String) async throws {
        let scene = try await getScene(id)
        
        // Apply device states
        for (deviceId, state) in scene.deviceStates {
            do {
                try await deviceManager.updateDeviceState(deviceId, state: state)
            } catch {
                throw SceneError.activationFailed(deviceId: deviceId, error: error)
            }
        }
        
        activeScenes.insert(id)
        
        // Update scene status
        var updatedScene = scene
        updatedScene.isActive = true
        try await updateScene(updatedScene)
    }
    
    func deactivateScene(_ id: String) async throws {
        let scene = try await getScene(id)
        
        // Reset devices to default state
        for deviceId in scene.deviceStates.keys {
            do {
                try await deviceManager.updateDeviceState(deviceId, state: .init(power: true))
            } catch {
                print("Failed to reset device \(deviceId): \(error)")
            }
        }
        
        activeScenes.remove(id)
        
        // Update scene status
        var updatedScene = scene
        updatedScene.isActive = false
        try await updateScene(updatedScene)
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
    
    private func loadScenes() {
        Task {
            do {
                let scenes: [Scene] = try await storage.load(.scenes)
                scenesSubject.send(scenes)
                
                // Reactivate active scenes
                for scene in scenes where scene.isActive {
                    try await activateScene(scene.id)
                }
            } catch {
                print("Failed to load scenes: \(error)")
                scenesSubject.send([])
            }
        }
    }
    
    private func saveScenes(_ scenes: [Scene]) async throws {
        try await storage.save(scenes, for: .scenes)
    }
    
    private func validateScene(_ scene: Scene) async throws {
        // Check for duplicate names
        let scenes = scenesSubject.value
        if let existingScene = scenes.first(where: { $0.name == scene.name && $0.id != scene.id }) {
            throw SceneError.duplicateName
        }
        
        // Validate devices exist
        for deviceId in scene.deviceStates.keys {
            guard let _ = try? await deviceManager.getDevice(deviceId) else {
                throw SceneError.deviceNotFound(deviceId)
            }
        }
        
        // Validate schedule if present
        if let schedule = scene.schedule {
            if schedule.startTime.hour < 0 || schedule.startTime.hour > 23 ||
                schedule.startTime.minute < 0 || schedule.startTime.minute > 59 {
                throw SceneError.invalidSchedule
            }
            if let endTime = schedule.endTime {
                if endTime.hour < 0 || endTime.hour > 23 ||
                    endTime.minute < 0 || endTime.minute > 59 {
                    throw SceneError.invalidSchedule
                }
            }
        }
    }
    
    private func startScheduleTimer() {
        scheduleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task {
                await self?.checkScheduledScenes()
            }
        }
    }
    
    private func checkScheduledScenes() async {
        let currentDate = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        let minute = calendar.component(.minute, from: currentDate)
        let weekday = calendar.component(.weekday, from: currentDate)
        let currentTime = TimeOfDay(hour: hour, minute: minute)
        
        for scene in scenesSubject.value {
            guard let schedule = scene.schedule, schedule.isEnabled else { continue }
            
            if schedule.daysOfWeek.contains(SceneSchedule.DayOfWeek(rawValue: weekday)!) {
                if schedule.startTime == currentTime {
                    do {
                        try await activateScene(scene.id)
                    } catch {
                        print("Failed to activate scheduled scene \(scene.id): \(error)")
                    }
                } else if let endTime = schedule.endTime, endTime == currentTime {
                    do {
                        try await deactivateScene(scene.id)
                    } catch {
                        print("Failed to deactivate scheduled scene \(scene.id): \(error)")
                    }
                }
            }
        }
    }
    
    private func handleDeviceStateUpdates(_ updates: [DeviceStateUpdate]) async {
        // Handle device state changes that might affect active scenes
        for update in updates {
            if update.state.power == false {
                // Check if this affects any active scenes
                let affectedScenes = scenesSubject.value.filter { scene in
                    scene.isActive && scene.deviceStates.keys.contains(update.deviceId)
                }
                
                for scene in affectedScenes {
                    do {
                        try await deactivateScene(scene.id)
                    } catch {
                        print("Failed to deactivate scene \(scene.id) after device power off: \(error)")
                    }
                }
            }
        }
    }
}

enum SceneError: LocalizedError {
    case notFound
    case deviceNotFound(String)
    case duplicateName
    case invalidSchedule
    case activationFailed(deviceId: String, error: Error)
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "Scene not found"
        case .deviceNotFound(let deviceId): return "Device not found: \(deviceId)"
        case .duplicateName: return "Scene name already exists"
        case .invalidSchedule: return "Invalid scene schedule"
        case .activationFailed(let deviceId, let error):
            return "Failed to activate scene for device \(deviceId): \(error.localizedDescription)"
        }
    }
} 