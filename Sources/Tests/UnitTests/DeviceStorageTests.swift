import XCTest
@testable import YeelightControl

final class DeviceStorageTests: XCTestCase {
    var storage: DeviceStorage!
    let testDevice = YeelightDevice(ip: "192.168.1.100", port: 55443)
    
    override func setUp() {
        super.setUp()
        
        // Create a fresh instance for each test
        storage = DeviceStorage()
        
        // Clear any existing data
        storage.clearAllData()
        
        // Setup test device
        testDevice.name = "Test Light"
        testDevice.model = "color"
        testDevice.firmwareVersion = "18"
    }
    
    override func tearDown() {
        storage.clearAllData()
        storage = nil
        super.tearDown()
    }
    
    func testSaveAndLoadDevice() {
        // Given
        let roomName = "Living Room"
        
        // When
        storage.saveDevice(testDevice, inRoom: roomName)
        
        // Then
        let loadedDevices = storage.loadDevices()
        XCTAssertEqual(loadedDevices.count, 1)
        XCTAssertNotNil(loadedDevices[testDevice.ip])
        XCTAssertEqual(loadedDevices[testDevice.ip]?.name, "Test Light")
        XCTAssertEqual(storage.getDeviceRoom(testDevice.ip), roomName)
    }
    
    func testSaveAndLoadRooms() {
        // Given
        let roomName = "Test Room"
        let roomIcon = "lightbulb.fill"
        
        // When
        storage.saveRoom(name: roomName, icon: roomIcon)
        
        // Then
        let rooms = storage.loadRooms()
        XCTAssertTrue(rooms.contains { $0.name == roomName && $0.icon == roomIcon })
        XCTAssertEqual(storage.getRoomIcon(roomName), roomIcon)
    }
    
    func testSaveAndLoadCustomScene() {
        // Given
        let sceneName = "Movie Night"
        let scene = YeelightManager.Scene.colorTemperature(temperature: 2700, brightness: 50)
        let devices = [testDevice.ip]
        
        // When
        storage.saveCustomScene(name: sceneName, scene: scene, devices: devices)
        
        // Then
        let scenes = storage.loadSavedScenes()
        XCTAssertEqual(scenes.count, 1)
        XCTAssertEqual(scenes.first?.name, sceneName)
        XCTAssertEqual(scenes.first?.devices, devices)
        
        if case .colorTemperature(let temp, let bright) = scenes.first?.scene {
            XCTAssertEqual(temp, 2700)
            XCTAssertEqual(bright, 50)
        } else {
            XCTFail("Incorrect scene type saved")
        }
    }
    
    func testDeviceStateRestoration() {
        // Given
        storage.saveDevice(testDevice, inRoom: "Test Room")
        
        // When
        let loadedDevices = storage.loadDevices()
        let loadedDevice = loadedDevices[testDevice.ip]
        
        // Then
        XCTAssertNotNil(loadedDevice)
        XCTAssertEqual(loadedDevice?.ip, testDevice.ip)
        XCTAssertEqual(loadedDevice?.port, testDevice.port)
        XCTAssertEqual(loadedDevice?.name, testDevice.name)
        XCTAssertEqual(loadedDevice?.model, testDevice.model)
        XCTAssertEqual(loadedDevice?.firmwareVersion, testDevice.firmwareVersion)
    }
    
    func testDefaultRooms() {
        // When
        let rooms = storage.loadRooms()
        
        // Then
        XCTAssertTrue(rooms.contains { $0.name == "Living Room" })
        XCTAssertTrue(rooms.contains { $0.name == "Bedroom" })
        XCTAssertTrue(rooms.contains { $0.name == "Kitchen" })
    }
    
    func testSaveAndRetrieveScene() throws {
        // Create a test scene
        let scene = YeelightManager.Scene.color(red: 255, green: 0, blue: 0, brightness: 100)
        let savedScene = DeviceStorage.SavedScene(
            name: "Test Scene",
            scene: scene,
            devices: [testDevice.ip],
            id: UUID().uuidString
        )
        
        // Save the scene
        try storage.saveScene(savedScene)
        
        // Verify it was saved
        XCTAssertEqual(storage.savedScenes.count, 1)
        XCTAssertEqual(storage.savedScenes[0].name, "Test Scene")
        
        // Retrieve the scene
        let retrievedScene = storage.getScene(id: savedScene.id)
        XCTAssertNotNil(retrievedScene)
        
        if case .color(let r, let g, let b, let brightness) = retrievedScene {
            XCTAssertEqual(r, 255)
            XCTAssertEqual(g, 0)
            XCTAssertEqual(b, 0)
            XCTAssertEqual(brightness, 100)
        } else {
            XCTFail("Retrieved scene is not of the expected type")
        }
    }
    
    func testSceneValidation() {
        // Test empty name validation
        let sceneWithEmptyName = DeviceStorage.SavedScene(
            name: "",
            scene: .color(red: 255, green: 0, blue: 0, brightness: 100),
            devices: [testDevice.ip],
            id: UUID().uuidString
        )
        
        XCTAssertThrowsError(try storage.saveScene(sceneWithEmptyName)) { error in
            XCTAssertEqual(error as? DeviceStorage.StorageError, .validationFailed("Scene name cannot be empty"))
        }
    }
    
    func testDuplicateSceneNames() throws {
        // Create and save a scene
        let scene1 = DeviceStorage.SavedScene(
            id: UUID(),
            name: "Duplicate Name",
            scene: .color(red: 255, green: 0, blue: 0, brightness: 100),
            devices: ["192.168.1.100"]
        )
        
        try storage.saveScene(scene1)
        
        // Try to save another scene with the same name
        let scene2 = DeviceStorage.SavedScene(
            id: UUID(),
            name: "Duplicate Name",
            scene: .color(red: 0, green: 255, blue: 0, brightness: 100),
            devices: ["192.168.1.101"]
        )
        
        XCTAssertThrowsError(try storage.saveScene(scene2)) { error in
            XCTAssertEqual(error as? DeviceStorage.StorageError, .duplicateName("Duplicate Name"))
        }
    }
    
    func testDeleteScene() throws {
        // Create and save a scene
        let scene = DeviceStorage.SavedScene(
            name: "Scene to Delete",
            scene: .color(red: 255, green: 0, blue: 0, brightness: 100),
            devices: ["192.168.1.100"]
        )
        
        try storage.saveScene(scene)
        XCTAssertEqual(storage.savedScenes.count, 1)
        
        // Delete the scene
        try storage.deleteScene(withId: scene.id)
        XCTAssertEqual(storage.savedScenes.count, 0)
        
        // Try to delete a non-existent scene
        XCTAssertThrowsError(try storage.deleteScene(withId: UUID())) { error in
            if let storageError = error as? DeviceStorage.StorageError {
                XCTAssertTrue(storageError.isSceneNotFound)
            } else {
                XCTFail("Expected StorageError.sceneNotFound")
            }
        }
    }
    
    func testThreadSafety() {
        // Test concurrent access to storage
        let expectation = XCTestExpectation(description: "Concurrent scene operations")
        expectation.expectedFulfillmentCount = 20
        
        let dispatchGroup = DispatchGroup()
        
        for i in 0..<20 {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                do {
                    let scene = DeviceStorage.SavedScene(
                        name: "Concurrent Scene \(i)",
                        scene: .color(red: 255, green: 0, blue: 0, brightness: 100),
                        devices: ["192.168.1.\(i)"]
                    )
                    
                    try self.storage.saveScene(scene)
                    expectation.fulfill()
                    dispatchGroup.leave()
                } catch {
                    XCTFail("Failed to save scene: \(error)")
                    dispatchGroup.leave()
                }
            }
        }
        
        // Wait for all operations to complete
        dispatchGroup.wait()
        
        // Verify all scenes were saved
        XCTAssertEqual(storage.savedScenes.count, 20)
    }
    
    func testConcurrentReadWrite() {
        // Test concurrent read and write operations
        let writeExpectation = XCTestExpectation(description: "Write operations")
        let readExpectation = XCTestExpectation(description: "Read operations")
        
        // Create and save initial scenes
        for i in 0..<5 {
            do {
                let scene = DeviceStorage.SavedScene(
                    name: "Initial Scene \(i)",
                    scene: .color(red: 255, green: 0, blue: 0, brightness: 100),
                    devices: ["192.168.1.\(i)"]
                )
                try storage.saveScene(scene)
            } catch {
                XCTFail("Failed to save initial scene: \(error)")
            }
        }
        
        // Perform concurrent read and write operations
        let dispatchGroup = DispatchGroup()
        
        // Write operations
        for i in 5..<15 {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                do {
                    let scene = DeviceStorage.SavedScene(
                        name: "Concurrent Write Scene \(i)",
                        scene: .color(red: 0, green: 255, blue: 0, brightness: 100),
                        devices: ["192.168.1.\(i)"]
                    )
                    try self.storage.saveScene(scene)
                    dispatchGroup.leave()
                } catch {
                    XCTFail("Failed to save scene during concurrent operation: \(error)")
                    dispatchGroup.leave()
                }
            }
        }
        
        // Read operations
        for _ in 0..<20 {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                let scenes = self.storage.savedScenes
                XCTAssertGreaterThanOrEqual(scenes.count, 5)
                dispatchGroup.leave()
            }
        }
        
        // Wait for all operations to complete
        dispatchGroup.wait()
        writeExpectation.fulfill()
        readExpectation.fulfill()
        
        wait(for: [writeExpectation, readExpectation], timeout: 5.0)
        
        // Verify final state
        XCTAssertEqual(storage.savedScenes.count, 15)
    }
    
    func testAutomationOperations() throws {
        // Create a test automation
        let scene = YeelightManager.Scene.color(red: 255, green: 0, blue: 0, brightness: 100)
        let action = Automation.Action.setScene(devices: ["192.168.1.100"], scene: scene)
        let automation = Automation(
            name: "Test Automation",
            trigger: .time(Date()),
            action: action
        )
        
        // Save the automation
        try storage.saveAutomation(automation)
        
        // Verify it was saved
        XCTAssertEqual(storage.automations.count, 1)
        XCTAssertEqual(storage.automations[0].name, "Test Automation")
        
        // Retrieve the automation
        let retrievedAutomation = storage.getAutomation(id: automation.id)
        XCTAssertNotNil(retrievedAutomation)
        
        // Delete the automation
        try storage.deleteAutomation(withId: automation.id)
        XCTAssertEqual(storage.automations.count, 0)
        
        // Try to delete a non-existent automation
        XCTAssertThrowsError(try storage.deleteAutomation(withId: UUID())) { error in
            if let storageError = error as? DeviceStorage.StorageError {
                XCTAssertTrue(storageError.isAutomationNotFound)
            } else {
                XCTFail("Expected StorageError.automationNotFound")
            }
        }
    }
    
    func testSceneExportImport() throws {
        // Create a test scene
        let scene = YeelightManager.Scene.color(red: 255, green: 0, blue: 0, brightness: 100)
        let savedScene = DeviceStorage.SavedScene(
            name: "Export Test Scene",
            scene: scene,
            devices: ["192.168.1.100"]
        )
        
        // Save the scene
        try storage.saveScene(savedScene)
        
        // Export the scene
        let exportedData = try storage.exportScene(id: savedScene.id)
        XCTAssertFalse(exportedData.isEmpty)
        
        // Import the scene for a different device
        let importedScene = try storage.importScene(from: exportedData, forDevices: ["192.168.1.101"])
        
        // Verify the imported scene
        XCTAssertEqual(importedScene.name, savedScene.name)
        XCTAssertEqual(storage.savedScenes.count, 2)
        XCTAssertEqual(importedScene.devices, ["192.168.1.101"])
        
        // Test importing with invalid data
        let invalidData = "Invalid JSON".data(using: .utf8)!
        XCTAssertThrowsError(try storage.importScene(from: invalidData, forDevices: ["192.168.1.102"])) { error in
            XCTAssertEqual(error as? DeviceStorage.StorageError, .decodingFailed)
        }
    }
    
    func testScenesByDevice() throws {
        // Create and save multiple scenes for different devices
        let device1 = "192.168.1.100"
        let device2 = "192.168.1.101"
        
        let scene1 = DeviceStorage.SavedScene(
            name: "Device 1 Scene",
            scene: .color(red: 255, green: 0, blue: 0, brightness: 100),
            devices: [device1]
        )
        
        let scene2 = DeviceStorage.SavedScene(
            name: "Device 2 Scene",
            scene: .color(red: 0, green: 255, blue: 0, brightness: 100),
            devices: [device2]
        )
        
        let scene3 = DeviceStorage.SavedScene(
            name: "Shared Scene",
            scene: .color(red: 0, green: 0, blue: 255, brightness: 100),
            devices: [device1, device2]
        )
        
        try storage.saveScene(scene1)
        try storage.saveScene(scene2)
        try storage.saveScene(scene3)
        
        // Get scenes for device 1
        let device1Scenes = storage.getScenes(forDevice: device1)
        XCTAssertEqual(device1Scenes.count, 2)
        XCTAssertTrue(device1Scenes.contains { $0.name == "Device 1 Scene" })
        XCTAssertTrue(device1Scenes.contains { $0.name == "Shared Scene" })
        
        // Get scenes for device 2
        let device2Scenes = storage.getScenes(forDevice: device2)
        XCTAssertEqual(device2Scenes.count, 2)
        XCTAssertTrue(device2Scenes.contains { $0.name == "Device 2 Scene" })
        XCTAssertTrue(device2Scenes.contains { $0.name == "Shared Scene" })
    }
}

// Helper extension for testing
extension DeviceStorage.StorageError: Equatable {
    public static func == (lhs: DeviceStorage.StorageError, rhs: DeviceStorage.StorageError) -> Bool {
        switch (lhs, rhs) {
        case (.encodingFailed, .encodingFailed),
             (.decodingFailed, .decodingFailed),
             (.invalidData, .invalidData):
            return true
        case (.duplicateName(let lhsName), .duplicateName(let rhsName)):
            return lhsName == rhsName
        case (.sceneNotFound(let lhsId), .sceneNotFound(let rhsId)):
            return lhsId == rhsId
        case (.automationNotFound(let lhsId), .automationNotFound(let rhsId)):
            return lhsId == rhsId
        case (.validationFailed(let lhsReason), .validationFailed(let rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }
    
    var isSceneNotFound: Bool {
        if case .sceneNotFound = self {
            return true
        }
        return false
    }
    
    var isAutomationNotFound: Bool {
        if case .automationNotFound = self {
            return true
        }
        return false
    }
} 