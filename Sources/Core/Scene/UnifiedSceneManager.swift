import Foundation
import Combine
import SwiftUI

// MARK: - Scene Types
// Core_Scene, Core_SceneSchedule, and Core_Weekday are defined in SceneTypes.swift
// Removing duplicate definitions to resolve ambiguity errors

// MARK: - Effect Types
// Core_Effect, Core_EffectType, and Core_EffectParameters are defined in EffectTypes.swift
// Removing duplicate definitions to resolve ambiguity errors

// MARK: - Color Model

// Core_Color is already defined in UnifiedYeelightManager.swift
// Using the existing Core_Color struct from UnifiedYeelightManager.swift
// public struct Core_Color: Codable, Equatable, Hashable {
//     public var red: Int
//     public var green: Int
//     public var blue: Int
//     
//     public init(red: Int, green: Int, blue: Int) {
//         self.red = max(0, min(255, red))
//         self.green = max(0, min(255, green))
//         self.blue = max(0, min(255, blue))
//     }
//     
//     public static let clear = Core_Color(red: 0, green: 0, blue: 0)
//     public static let black = Core_Color(red: 0, green: 0, blue: 0)
//     public static let white = Core_Color(red: 255, green: 255, blue: 255)
//     public static let red = Core_Color(red: 255, green: 0, blue: 0)
//     public static let green = Core_Color(red: 0, green: 255, blue: 0)
//     public static let blue = Core_Color(red: 0, green: 0, blue: 255)
//     public static let yellow = Core_Color(red: 255, green: 255, blue: 0)
//     public static let orange = Core_Color(red: 255, green: 165, blue: 0)
//     public static let purple = Core_Color(red: 128, green: 0, blue: 128)
//     public static let pink = Core_Color(red: 255, green: 192, blue: 203)
//     
//     public func hash(into hasher: inout Hasher) {
//         hasher.combine(red)
//         hasher.combine(green)
//         hasher.combine(blue)
//     }
// }

// MARK: - Scene Managing Protocol

public protocol Core_SceneManaging: AnyObject {
    var scenes: [Core_Scene] { get }
    var sceneUpdates: AnyPublisher<Core_Scene, Never> { get }
    
    func getScene(withId id: String) async -> Core_Scene?
    func getAllScenes() async -> [Core_Scene]
    func createScene(name: String, deviceIds: [String], effect: Core_Effect?) async -> Core_Scene
    func updateScene(_ scene: Core_Scene) async -> Core_Scene
    func deleteScene(_ scene: Core_Scene) async
    func activateScene(_ scene: Core_Scene) async
    func deactivateScene(_ scene: Core_Scene) async
    func scheduleScene(_ scene: Core_Scene, schedule: Core_SceneSchedule) async
}

// MARK: - Unified Scene Manager Implementation

public final class UnifiedSceneManager: ObservableObject, Core_SceneManaging {
    // MARK: - Properties
    
    @Published public private(set) var scenes: [Core_Scene] = []
    
    private let storageManager: any Core_StorageManaging
    private let deviceManager: any Core_DeviceManaging
    private let effectManager: any Core_EffectManaging
    private let sceneSubject = PassthroughSubject<Core_Scene, Never>()
    
    // MARK: - Initialization
    
    public init(
        storageManager: any Core_StorageManaging,
        deviceManager: any Core_DeviceManaging,
        effectManager: any Core_EffectManaging
    ) {
        self.storageManager = storageManager
        self.deviceManager = deviceManager
        self.effectManager = effectManager
        
        Task {
            await loadScenes()
        }
    }
    
    // MARK: - SceneManaging Protocol
    
    public var sceneUpdates: AnyPublisher<Core_Scene, Never> {
        sceneSubject.eraseToAnyPublisher()
    }
    
    public func getScene(withId id: String) async -> Core_Scene? {
        return scenes.first { $0.id == id }
    }
    
    public func getAllScenes() async -> [Core_Scene] {
        return scenes
    }
    
    public func createScene(name: String, deviceIds: [String], effect: Core_Effect?) async -> Core_Scene {
        // Create device states dictionary
        let states: [String: DeviceState] = [:]
        
        let newScene = Core_Scene(
            name: name,
            deviceIds: deviceIds,
            states: states
        )
        
        scenes.append(newScene)
        sceneSubject.send(newScene)
        
        // Save scene to storage
        try? await storageManager.save(newScene, forKey: newScene.id)
        
        return newScene
    }
    
    public func updateScene(_ scene: Core_Scene) async -> Core_Scene {
        if let index = scenes.firstIndex(where: { $0.id == scene.id }) {
            scenes[index] = scene
            sceneSubject.send(scene)
            
            // Save scene to storage
            try? await storageManager.save(scene, forKey: scene.id)
        }
        
        return scene
    }
    
    public func deleteScene(_ scene: Core_Scene) async {
        if let index = scenes.firstIndex(where: { $0.id == scene.id }) {
            let sceneToDelete = scenes[index]
            scenes.remove(at: index)
            
            // Delete scene from storage
            try? await storageManager.remove(forKey: sceneToDelete.id)
        }
    }
    
    public func activateScene(_ scene: Core_Scene) async {
        // Since isActive is a let property, we need to create a new scene with the updated value
        let updatedScene = Core_Scene(
            id: scene.id,
            name: scene.name,
            deviceIds: scene.deviceIds,
            states: scene.states,
            schedule: scene.schedule,
            isActive: true,
            lastActivated: Date()
        )
        
        // Update the scene
        await updateScene(updatedScene)
    }
    
    public func deactivateScene(_ scene: Core_Scene) async {
        // Since isActive is a let property, we need to create a new scene with the updated value
        let updatedScene = Core_Scene(
            id: scene.id,
            name: scene.name,
            deviceIds: scene.deviceIds,
            states: scene.states,
            schedule: scene.schedule,
            isActive: false,
            lastActivated: scene.lastActivated
        )
        
        // Update the scene
        await updateScene(updatedScene)
    }
    
    public func scheduleScene(_ scene: Core_Scene, schedule: Core_SceneSchedule) async {
        // Since schedule is a let property, we need to create a new scene with the updated value
        let updatedScene = Core_Scene(
            id: scene.id,
            name: scene.name,
            deviceIds: scene.deviceIds,
            states: scene.states,
            schedule: schedule,
            isActive: scene.isActive,
            lastActivated: scene.lastActivated
        )
        
        // Update the scene
        await updateScene(updatedScene)
    }
    
    // MARK: - Private Methods
    
    private func loadScenes() async {
        do {
            let loadedScenes: [Core_Scene] = try await storageManager.getAll(Core_Scene.self, withPrefix: "")
            
            await MainActor.run {
                self.scenes = loadedScenes
            }
        } catch {
            print("Error loading scenes: \(error.localizedDescription)")
        }
    }
}

enum SceneError: Error {
    case unknown
    case invalidDevices
    case activationFailed
    case deactivationFailed
    
    var localizedDescription: String {
        switch self {
        case .unknown:
            return "Unknown scene error"
        case .invalidDevices:
            return "Invalid devices for scene"
        case .activationFailed:
            return "Failed to activate scene"
        case .deactivationFailed:
            return "Failed to deactivate scene"
        }
    }
} 
