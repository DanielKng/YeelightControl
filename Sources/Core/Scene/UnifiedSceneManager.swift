import Foundation
import Combine
import SwiftUI

// MARK: - Scene Types

public struct Core_Scene: Identifiable, Codable, Equatable {
    public var id: String
    public var name: String
    public var deviceIds: [String]
    public var effect: Core_Effect?
    public var isActive: Bool
    public var schedule: Core_SceneSchedule?
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        deviceIds: [String],
        effect: Core_Effect? = nil,
        isActive: Bool = false,
        schedule: Core_SceneSchedule? = nil
    ) {
        self.id = id
        self.name = name
        self.deviceIds = deviceIds
        self.effect = effect
        self.isActive = isActive
        self.schedule = schedule
    }
}

public struct Core_SceneSchedule: Codable, Equatable {
    public var startTime: Date
    public var endTime: Date
    public var days: [Core_Weekday]
    public var isEnabled: Bool
    
    public init(
        startTime: Date,
        endTime: Date,
        days: [Core_Weekday],
        isEnabled: Bool = true
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.days = days
        self.isEnabled = isEnabled
    }
}

public enum Core_Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

// MARK: - Effect Types

public struct Core_Effect: Identifiable, Codable, Equatable {
    public var id: String
    public var name: String
    public var type: Core_EffectType
    public var parameters: Core_EffectParameters
    public var isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        type: Core_EffectType,
        parameters: Core_EffectParameters,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.parameters = parameters
        self.isActive = isActive
    }
}

public enum Core_EffectType: String, Codable, CaseIterable {
    case pulse
    case strobe
    case colorCycle
    case colorFlow
    case custom
}

public struct Core_EffectParameters: Codable, Equatable {
    public var speed: Int
    public var brightness: Int
    public var colors: [Core_Color]
    public var duration: TimeInterval
    public var repeatEffect: Bool
    public var customData: [String: String]
    
    public init(
        speed: Int = 50,
        brightness: Int = 100,
        colors: [Core_Color] = [],
        duration: TimeInterval = 5.0,
        repeatEffect: Bool = false,
        customData: [String: String] = [:]
    ) {
        self.speed = speed
        self.brightness = brightness
        self.colors = colors
        self.duration = duration
        self.repeatEffect = repeatEffect
        self.customData = customData
    }
    
    // Explicit implementation of Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        speed = try container.decode(Int.self, forKey: .speed)
        brightness = try container.decode(Int.self, forKey: .brightness)
        colors = try container.decode([Core_Color].self, forKey: .colors)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        repeatEffect = try container.decode(Bool.self, forKey: .repeatEffect)
        customData = try container.decode([String: String].self, forKey: .customData)
    }
    
    // Explicit implementation of Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(speed, forKey: .speed)
        try container.encode(brightness, forKey: .brightness)
        try container.encode(colors, forKey: .colors)
        try container.encode(duration, forKey: .duration)
        try container.encode(repeatEffect, forKey: .repeatEffect)
        try container.encode(customData, forKey: .customData)
    }
    
    private enum CodingKeys: String, CodingKey {
        case speed, brightness, colors, duration, repeatEffect, customData
    }
}

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
    func scheduleScene(_ scene: Core_Scene, schedule: Core_SceneSchedule) async -> Core_Scene
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
        let newScene = Core_Scene(
            name: name,
            deviceIds: deviceIds,
            effect: effect
        )
        
        scenes.append(newScene)
        sceneSubject.send(newScene)
        
        // Save scene to storage
        try? await storageManager.save(newScene, withId: newScene.id, inCollection: "scenes")
        
        return newScene
    }
    
    public func updateScene(_ scene: Core_Scene) async -> Core_Scene {
        if let index = scenes.firstIndex(where: { $0.id == scene.id }) {
            scenes[index] = scene
            sceneSubject.send(scene)
            
            // Update scene in storage
            try? await storageManager.save(scene, withId: scene.id, inCollection: "scenes")
        }
        
        return scene
    }
    
    public func deleteScene(_ scene: Core_Scene) async {
        if let index = scenes.firstIndex(where: { $0.id == scene.id }) {
            let sceneToDelete = scenes[index]
            scenes.remove(at: index)
            
            // Delete scene from storage
            try? await storageManager.delete(withId: sceneToDelete.id, fromCollection: "scenes")
        }
    }
    
    public func activateScene(_ scene: Core_Scene) async {
        var updatedScene = scene
        updatedScene.isActive = true
        
        // Activate the scene's effect if it has one
        if let effect = updatedScene.effect {
            await effectManager.startEffect(effect)
        }
        
        // Update the scene
        await updateScene(updatedScene)
    }
    
    public func deactivateScene(_ scene: Core_Scene) async {
        var updatedScene = scene
        updatedScene.isActive = false
        
        // Deactivate the scene's effect if it has one
        if let effect = updatedScene.effect {
            await effectManager.stopEffect(effect)
        }
        
        // Update the scene
        await updateScene(updatedScene)
    }
    
    public func scheduleScene(_ scene: Core_Scene, schedule: Core_SceneSchedule) async -> Core_Scene {
        var updatedScene = scene
        updatedScene.schedule = schedule
        
        // Update the scene
        return await updateScene(updatedScene)
    }
    
    // MARK: - Private Methods
    
    private func loadScenes() async {
        do {
            let loadedScenes: [Core_Scene] = try await storageManager.getAll(fromCollection: "scenes")
            
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
