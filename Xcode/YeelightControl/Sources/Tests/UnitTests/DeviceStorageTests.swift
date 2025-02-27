import XCTest
@testable import YeelightControl

final class DeviceStorageTests: XCTestCase {
    var storage: DeviceStorage!
    let testDevice = YeelightDevice(ip: "192.168.1.100", port: 55443)
    
    override func setUp() {
        super.setUp()
        storage = DeviceStorage.shared
        // Clear any existing data
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        // Setup test device
        testDevice.name = "Test Light"
        testDevice.isOn = true
        testDevice.brightness = 75
        testDevice.colorTemperature = 4000
    }
    
    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        super.tearDown()
    }
    
    func testSaveAndLoadDevice() {
        // Given
        let roomName = "Living Room"
        
        // When
        storage.saveDevice(testDevice, inRoom: roomName)
        let loadedDevices = storage.loadDevices()
        
        // Then
        XCTAssertEqual(loadedDevices.count, 1)
        XCTAssertEqual(loadedDevices[testDevice.ip]?.name, "Test Light")
        XCTAssertEqual(loadedDevices[testDevice.ip]?.room, roomName)
        XCTAssertEqual(loadedDevices[testDevice.ip]?.lastKnownState.isOn, true)
        XCTAssertEqual(loadedDevices[testDevice.ip]?.lastKnownState.brightness, 75)
    }
    
    func testSaveAndLoadRooms() {
        // Given
        let roomName = "Test Room"
        let roomIcon = "lightbulb.fill"
        
        // When
        storage.saveRoom(roomName, icon: roomIcon)
        let rooms = storage.loadRooms()
        
        // Then
        XCTAssertTrue(rooms.contains { $0.name == roomName })
        XCTAssertEqual(rooms.first { $0.name == roomName }?.icon, roomIcon)
    }
    
    func testSaveAndLoadCustomScene() {
        // Given
        let sceneName = "Movie Night"
        let scene = YeelightManager.Scene.colorTemperature(temperature: 2700, brightness: 50)
        let devices = [testDevice.ip]
        
        // When
        storage.saveCustomScene(name: sceneName, scene: scene, devices: devices)
        let scenes = storage.loadSavedScenes()
        
        // Then
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
        XCTAssertEqual(loadedDevice?.lastKnownState.brightness, testDevice.brightness)
        XCTAssertEqual(loadedDevice?.lastKnownState.colorTemperature, testDevice.colorTemperature)
        XCTAssertEqual(loadedDevice?.lastKnownState.isOn, testDevice.isOn)
    }
    
    func testDefaultRooms() {
        // Given
        let rooms = storage.loadRooms()
        
        // Then
        XCTAssertTrue(rooms.contains { $0.name == "Living Room" })
        XCTAssertTrue(rooms.contains { $0.name == "Bedroom" })
        XCTAssertTrue(rooms.contains { $0.name == "Kitchen" })
    }
} 