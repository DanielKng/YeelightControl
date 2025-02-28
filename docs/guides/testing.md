# Testing Guide

## Quick Links
- 📚 [API Reference](../reference/api-reference.md#error-handling)
- 🔧 [Troubleshooting](troubleshooting.md)
- 📝 [Example Code](../examples/basic-control/README.md)

## Table of Contents
- [Overview](#overview)
- [Test Categories](#test-categories)
- [Test Configuration](#test-configuration)
- [Running Tests](#running-tests)
- [Best Practices](#best-practices)
- [Continuous Integration](#continuous-integration)

## Overview

YeelightControl includes a comprehensive test suite covering unit tests, integration tests, UI tests, and performance tests. This guide explains how to write, run, and maintain tests for the framework.

## Test Categories

### Unit Tests
Located in `Sources/Tests/UnitTests/`:
```swift
class DeviceManagerTests: XCTestCase {
    func testDeviceDiscovery() async throws {
        let manager = DeviceManager()
        let devices = try await manager.discoverDevices()
        XCTAssertFalse(devices.isEmpty)
    }
    
    func testDeviceConnection() async throws {
        let manager = DeviceManager()
        try await manager.connect(to: mockDeviceId)
        XCTAssertTrue(manager.isConnected(to: mockDeviceId))
    }
}
```

### Integration Tests
Tests interactions between modules:
```swift
class SceneIntegrationTests: XCTestCase {
    func testSceneActivation() async throws {
        let deviceManager = DeviceManager()
        let sceneManager = SceneManager(deviceManager: deviceManager)
        
        let scene = try await sceneManager.createScene(
            name: "Test Scene",
            devices: mockDevices
        )
        
        try await sceneManager.activateScene(scene)
        // Verify all devices are in correct state
    }
}
```

### UI Tests
Located in `Sources/Tests/UITests/`:
```swift
class DeviceControlUITests: XCTestCase {
    func testDeviceControl() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to device
        app.buttons["deviceCell"].tap()
        
        // Test power toggle
        app.switches["powerToggle"].tap()
        XCTAssertTrue(app.switches["powerToggle"].isOn)
        
        // Test brightness slider
        let slider = app.sliders["brightnessSlider"]
        slider.adjust(toNormalizedSliderPosition: 0.5)
    }
}
```

### Performance Tests
Measure critical operations:
```swift
class PerformanceTests: XCTestCase {
    func testDeviceDiscoveryPerformance() {
        measure {
            let expectation = expectation(description: "Discovery")
            Task {
                let devices = try await deviceManager.discoverDevices()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
}
```

## Test Configuration

### Setup
```swift
class TestConfiguration: NSObject {
    static let shared = TestConfiguration()
    
    var isTestMode: Bool = false
    var mockNetworkDelay: TimeInterval = 0.1
    var mockDevices: [Device] = []
    
    func setUp() {
        isTestMode = true
        // Additional setup
    }
    
    func tearDown() {
        isTestMode = false
        // Additional cleanup
    }
}
```

### Test Plans
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Scheme>
    <TestAction>
        <TestPlans>
            <TestPlanReference
                reference="container:UnitTests.xctestplan"
                default="YES"/>
            <TestPlanReference
                reference="container:UITests.xctestplan"/>
            <TestPlanReference
                reference="container:PerformanceTests.xctestplan"/>
        </TestPlans>
    </TestAction>
</Scheme>
```

## Running Tests

### Command Line
```bash
# Run all tests
swift test

# Run specific test target
swift test --filter "CoreTests"

# Run specific test case
swift test --filter "DeviceManagerTests/testDeviceDiscovery"

# Run performance tests
swift test --filter "PerformanceTests"
```

### Xcode Integration
1. Use Test Navigator (⌘6)
2. Configure test plans
3. Set up CI integration
4. Generate test reports
5. Track test coverage

## Best Practices

### Test Organization
- Group related tests
- Use descriptive names
- Follow naming conventions
- Maintain test independence
- Clean up after tests

### Mock Objects
```swift
class MockDeviceManager: DeviceManaging {
    var discoveredDevices: [Device] = []
    var isConnected = false
    
    func discoverDevices() async throws -> [Device] {
        return discoveredDevices
    }
    
    func connect(to deviceId: String) async throws {
        isConnected = true
    }
}
```

### Async Testing
```swift
func testAsyncOperation() async throws {
    let expectation = expectation(description: "Operation")
    
    Task {
        try await operation()
        expectation.fulfill()
    }
    
    await waitForExpectations(timeout: 5.0)
}
```

### Test Helpers
```swift
extension XCTestCase {
    func createMockDevice() -> Device {
        return Device(
            id: UUID().uuidString,
            name: "Mock Device",
            isConnected: false
        )
    }
    
    func waitForDeviceState(_ device: Device, timeout: TimeInterval = 5.0) async throws {
        try await withTimeout(timeout) {
            while !device.isReady {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
}
```

## Continuous Integration

### GitHub Actions
```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and Test
        run: |
          swift build
          swift test
```

### Test Reports
- Generate coverage reports
- Track performance metrics
- Monitor test stability
- Report test failures
- Archive test results

## Additional Resources
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing Tips & Tricks](../examples/error-handling/README.md)
- [UI Testing Guide](../examples/basic-control/README.md)
- [Performance Testing Best Practices](../reference/api-reference.md#best-practices) 