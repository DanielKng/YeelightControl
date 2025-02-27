import XCTest
@testable import YeelightControl

final class YeelightManagerTests: XCTestCase {
    var manager: YeelightManager!
    
    override func setUp() {
        super.setUp()
        manager = YeelightManager()
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    func testDeviceDiscovery() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Device discovery")
        
        // When
        try manager.startDiscovery()
        
        // Wait for discovery
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 6)
        
        // Then
        XCTAssertFalse(manager.devices.isEmpty, "Should discover at least one device")
    }
    
    func testDeviceStateRestoration() {
        // Given
        let testDevice = YeelightDevice(ip: "192.168.1.100", port: 55443)
        testDevice.name = "Test Device"
        testDevice.isOn = true
        testDevice.brightness = 75
        
        // When
        manager.devices = [testDevice]
        manager.saveDeviceState()
        manager.devices.removeAll()
        manager.restoreDeviceState()
        
        // Then
        XCTAssertEqual(manager.devices.count, 1)
        XCTAssertEqual(manager.devices.first?.name, "Test Device")
        XCTAssertEqual(manager.devices.first?.brightness, 75)
        XCTAssertTrue(manager.devices.first?.isOn ?? false)
    }
    
    func testNetworkErrorHandling() {
        // Given
        NetworkStatus.shared.isWiFiEnabled = false
        
        // When/Then
        XCTAssertThrowsError(try manager.startDiscovery()) { error in
            XCTAssertEqual(error as? YeelightManager.NetworkError, .noWiFiConnection)
        }
    }
    
    func testBackgroundStateHandling() {
        // Given
        let testDevice = YeelightDevice(ip: "192.168.1.100", port: 55443)
        manager.devices = [testDevice]
        
        // When
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Then
        // Verify cleanup
        XCTAssertTrue(manager.devices.isEmpty)
        
        // When
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // Then
        // Verify restoration
        XCTAssertFalse(manager.devices.isEmpty)
    }
} 