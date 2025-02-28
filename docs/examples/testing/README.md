# Testing Example

This example demonstrates how to effectively test your YeelightControl implementation, including unit tests, integration tests, and performance tests.

## Features
- Unit testing device management
- Integration testing with mock devices
- Performance testing and profiling
- Test helpers and utilities
- Error simulation and handling

## Implementation

### Test Configuration Setup
```swift
import XCTest
@testable import YeelightControl

class YeelightControlTests: XCTestCase {
    var deviceManager: DeviceManager!
    var mockDevices: [Device]!
    
    override func setUp() async throws {
        super.setUp()
        deviceManager = DeviceManager()
        
        // Configure test environment
        deviceManager.configure(
            isTestMode: true,
            mockNetworkDelay: 0.1,
            mockDevices: []
        )
        
        // Create mock devices
        mockDevices = [
            createMockDevice(name: "Living Room"),
            createMockDevice(name: "Bedroom")
        ]
        
        // Set up mock devices
        deviceManager.setMockDevices(mockDevices)
    }
    
    override func tearDown() async throws {
        deviceManager.reset()
        deviceManager = nil
        mockDevices = nil
        super.tearDown()
    }
}
```

### Unit Testing Device Operations
```swift
extension YeelightControlTests {
    func testDeviceDiscovery() async throws {
        // Test device discovery
        let devices = try await deviceManager.discoverDevices()
        XCTAssertEqual(devices.count, mockDevices.count)
        
        // Verify discovered devices match mock devices
        for (discovered, mock) in zip(devices, mockDevices) {
            XCTAssertEqual(discovered.id, mock.id)
            XCTAssertEqual(discovered.name, mock.name)
        }
    }
    
    func testDeviceControl() async throws {
        guard let device = mockDevices.first else {
            XCTFail("No mock device available")
            return
        }
        
        // Test power control
        try await deviceManager.setPower(true, for: device.id)
        try await waitForDeviceState(device)
        verifyDeviceState(device, power: true, brightness: 100, color: nil)
        
        // Test brightness control
        try await deviceManager.setBrightness(50, for: device.id)
        try await waitForDeviceState(device)
        verifyDeviceState(device, power: true, brightness: 50, color: nil)
    }
}
```

### Testing Error Handling
```swift
extension YeelightControlTests {
    func testConnectionError() async throws {
        guard let device = mockDevices.first else {
            XCTFail("No mock device available")
            return
        }
        
        // Simulate connection error
        deviceManager.simulateError(.connectionFailed, for: device.id)
        
        do {
            try await deviceManager.setPower(true, for: device.id)
            XCTFail("Expected error not thrown")
        } catch let error as DeviceError {
            XCTAssertEqual(error, .connectionFailed)
        }
    }
    
    func testRecoveryBehavior() async throws {
        guard let device = mockDevices.first else {
            XCTFail("No mock device available")
            return
        }
        
        // Simulate temporary disconnection
        deviceManager.simulateStateChange(
            for: device.id,
            state: .disconnected
        )
        
        // Wait for auto-reconnect
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let updatedDevice = try await deviceManager.getDevice(device.id)
        XCTAssertTrue(updatedDevice.isConnected)
    }
}
```

### Performance Testing
```swift
extension YeelightControlTests {
    func testDiscoveryPerformance() async throws {
        measure {
            let expectation = expectation(description: "Discovery")
            
            Task {
                do {
                    let metrics = try await deviceManager.measureDiscoveryPerformance(
                        timeout: 1.0,
                        expectedCount: mockDevices.count
                    )
                    XCTAssertLessThan(metrics.duration, 1.5) // Should complete within 1.5s
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    func testCommandLatency() async throws {
        guard let device = mockDevices.first else {
            XCTFail("No mock device available")
            return
        }
        
        let command = DeviceCommand.setPower(true)
        let latency = try await deviceManager.measureCommandLatency(
            command: command,
            deviceId: device.id
        )
        
        XCTAssertLessThan(latency, 0.2) // Should complete within 200ms
    }
}
```

## Usage

1. Copy the example code into your test target
2. Add necessary imports and dependencies
3. Configure the test environment
4. Run the tests using Xcode's test navigator

## Notes

- Always reset the test environment between test cases
- Use appropriate timeout values for async operations
- Mock network delays to simulate real-world conditions
- Profile memory usage for long-running operations
- Test both success and error scenarios
- Verify state changes and error handling
- Use performance tests to catch regressions 