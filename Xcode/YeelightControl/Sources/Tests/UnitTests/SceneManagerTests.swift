import XCTest
@testable import YeelightControl

final class SceneManagerTests: XCTestCase {
    var sceneManager: SceneManager!
    var testDevice: YeelightDevice!
    
    override func setUp() {
        super.setUp()
        sceneManager = SceneManager.shared
        testDevice = YeelightDevice(ip: "192.168.1.100", port: 55443)
        testDevice.name = "Test Light"
    }
    
    func testCreateAndLoadScene() {
        // Given
        let sceneName = "Movie Night"
        let scene = YeelightManager.Scene.colorTemperature(temperature: 2700, brightness: 50)
        
        // When
        sceneManager.saveScene(name: sceneName, scene: scene, devices: [testDevice.ip])
        let loadedScenes = sceneManager.loadScenes()
        
        // Then
        XCTAssertEqual(loadedScenes.count, 1)
        XCTAssertEqual(loadedScenes.first?.name, sceneName)
        
        if case .colorTemperature(let temp, let bright) = loadedScenes.first?.scene {
            XCTAssertEqual(temp, 2700)
            XCTAssertEqual(bright, 50)
        } else {
            XCTFail("Incorrect scene type loaded")
        }
    }
    
    func testDeleteScene() {
        // Given
        let sceneName = "Test Scene"
        let scene = YeelightManager.Scene.color(red: 255, green: 0, blue: 0, brightness: 100)
        sceneManager.saveScene(name: sceneName, scene: scene, devices: [testDevice.ip])
        
        // When
        let scenes = sceneManager.loadScenes()
        guard let sceneToDelete = scenes.first else {
            XCTFail("No scene to delete")
            return
        }
        
        sceneManager.deleteScene(sceneToDelete.id)
        
        // Then
        let remainingScenes = sceneManager.loadScenes()
        XCTAssertTrue(remainingScenes.isEmpty)
    }
    
    func testUpdateScene() {
        // Given
        let sceneName = "Update Test"
        let originalScene = YeelightManager.Scene.color(red: 255, green: 0, blue: 0, brightness: 100)
        sceneManager.saveScene(name: sceneName, scene: originalScene, devices: [testDevice.ip])
        
        // When
        let scenes = sceneManager.loadScenes()
        guard let sceneToUpdate = scenes.first else {
            XCTFail("No scene to update")
            return
        }
        
        let updatedScene = YeelightManager.Scene.color(red: 0, green: 255, blue: 0, brightness: 50)
        sceneManager.updateScene(sceneToUpdate.id, name: "Updated Scene", scene: updatedScene)
        
        // Then
        let updatedScenes = sceneManager.loadScenes()
        XCTAssertEqual(updatedScenes.first?.name, "Updated Scene")
        
        if case .color(let red, let green, let blue, let brightness) = updatedScenes.first?.scene {
            XCTAssertEqual(red, 0)
            XCTAssertEqual(green, 255)
            XCTAssertEqual(blue, 0)
            XCTAssertEqual(brightness, 50)
        } else {
            XCTFail("Incorrect scene type after update")
        }
    }
    
    func testFavoriteScenes() {
        // Given
        let scene1 = YeelightManager.Scene.color(red: 255, green: 0, blue: 0, brightness: 100)
        let scene2 = YeelightManager.Scene.colorTemperature(temperature: 4000, brightness: 80)
        
        sceneManager.saveScene(name: "Scene 1", scene: scene1, devices: [testDevice.ip])
        sceneManager.saveScene(name: "Scene 2", scene: scene2, devices: [testDevice.ip])
        
        // When
        let scenes = sceneManager.loadScenes()
        guard let firstScene = scenes.first else {
            XCTFail("No scenes found")
            return
        }
        
        sceneManager.toggleFavorite(firstScene.id)
        
        // Then
        let favorites = sceneManager.loadFavoriteScenes()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.name, "Scene 1")
    }
    
    func testScenePresets() {
        // Given
        let presets = sceneManager.loadPresetScenes()
        
        // Then
        XCTAssertFalse(presets.isEmpty)
        XCTAssertTrue(presets.contains { $0.name == "Movie Night" })
        XCTAssertTrue(presets.contains { $0.name == "Reading" })
    }
    
    func testSceneSharing() {
        // Given
        let scene = YeelightManager.Scene.color(red: 255, green: 0, blue: 0, brightness: 100)
        let sharedScene = SharedScene(
            name: "Shared Scene",
            icon: "lightbulb.fill",
            scene: scene,
            createdBy: "Test User",
            description: "Test Description",
            tags: ["test"],
            version: 1
        )
        
        // When
        guard let url = sharedScene.shareURL else {
            XCTFail("Failed to create share URL")
            return
        }
        
        let importedScene = SharedScene.from(url: url)
        
        // Then
        XCTAssertNotNil(importedScene)
        XCTAssertEqual(importedScene?.name, "Shared Scene")
        XCTAssertEqual(importedScene?.createdBy, "Test User")
        
        if case .color(let red, let green, let blue, let brightness) = importedScene?.scene {
            XCTAssertEqual(red, 255)
            XCTAssertEqual(green, 0)
            XCTAssertEqual(blue, 0)
            XCTAssertEqual(brightness, 100)
        } else {
            XCTFail("Incorrect scene type after import")
        }
    }
} 