# Tests Module

## Overview
The Tests module contains a comprehensive suite of tests for the YeelightControl application. It includes unit tests, integration tests, UI tests, and performance tests to ensure the reliability and quality of the application.

## Architecture

### Directory Structure
```
Tests/
├── UnitTests/   - Unit and integration tests
└── UITests/     - User interface tests
```

## Test Categories

### Unit Tests

#### Core Module Tests
```swift
final class DeviceManagerTests: XCTestCase {
    /// Test device discovery
    func testDeviceDiscovery() async throws {
        // Given
        let manager = DeviceManager()
        let mockNetwork = MockNetworkService()
        mockNetwork.mockDevices = [mockDevice1, mockDevice2]
        
        // When
        let devices = try await manager.discoverDevices()
        
        // Then
        XCTAssertEqual(devices.count, 2)
        XCTAssertEqual(devices[0].id, mockDevice1.id)
    }
    
    /// Test device connection
    func testDeviceConnection() async throws {
        // Given
        let manager = DeviceManager()
        let device = MockDevice()
        
        // When
        try await manager.connect(to: device.id)
        
        // Then
        XCTAssertTrue(device.isConnected)
        XCTAssertNotNil(device.connectionTimestamp)
    }
}
```

#### Features Module Tests
```swift
final class SceneManagerTests: XCTestCase {
    /// Test scene creation
    func testSceneCreation() async throws {
        // Given
        let manager = SceneManager()
        let devices = [mockDevice1, mockDevice2]
        
        // When
        let scene = try await manager.createScene(
            name: "Test Scene",
            devices: devices,
            states: [.on, .off]
        )
        
        // Then
        XCTAssertEqual(scene.name, "Test Scene")
        XCTAssertEqual(scene.devices.count, 2)
    }
    
    /// Test scene activation
    func testSceneActivation() async throws {
        // Given
        let manager = SceneManager()
        let scene = MockScene()
        
        // When
        try await manager.activateScene(scene)
        
        // Then
        XCTAssertTrue(scene.isActive)
        XCTAssertNotNil(scene.activationTimestamp)
    }
}
```

### UI Tests

#### Device Control Tests
```swift
final class DeviceControlUITests: XCTestCase {
    /// Test device list navigation
    func testDeviceListNavigation() {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // When
        app.buttons["Devices"].tap()
        
        // Then
        XCTAssertTrue(app.tables["DeviceList"].exists)
        XCTAssertTrue(app.navigationBars["Devices"].exists)
    }
    
    /// Test device control interaction
    func testDeviceControl() {
        // Given
        let app = XCUIApplication()
        app.launch()
        
        // When
        app.buttons["Device1"].tap()
        app.sliders["Brightness"].adjust(toNormalizedSliderPosition: 0.5)
        
        // Then
        XCTAssertEqual(app.sliders["Brightness"].value as! Double, 0.5)
    }
}
```

### Performance Tests

#### Core Performance
```swift
final class CorePerformanceTests: XCTestCase {
    /// Test device discovery performance
    func testDeviceDiscoveryPerformance() {
        measure {
            let expectation = expectation(description: "Discovery")
            
            Task {
                let devices = try await deviceManager.discoverDevices()
                XCTAssertFalse(devices.isEmpty)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}
```

## Test Utilities

### Mock Objects
```swift
/// Mock device implementation
struct MockDevice: Device {
    var id: String
    var name: String
    var isConnected: Bool
    var state: DeviceState
    
    mutating func connect() async throws {
        isConnected = true
    }
    
    mutating func disconnect() async throws {
        isConnected = false
    }
}

/// Mock network service
class MockNetworkService: NetworkService {
    var mockDevices: [Device] = []
    
    func discoverDevices() async throws -> [Device] {
        return mockDevices
    }
}
```

### Test Helpers
```swift
/// Async test helper
func asyncTest(
    timeout: TimeInterval = 5.0,
    test: @escaping () async throws -> Void
) {
    let expectation = expectation(description: "Async test")
    
    Task {
        try await test()
        expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: timeout)
}

/// UI test helper
extension XCUIElement {
    func waitForExistence(timeout: TimeInterval = 5.0) -> Bool {
        return waitForExistence(timeout: timeout)
    }
}
```

## Best Practices

### Unit Testing
- Write tests before implementation (TDD)
- Test one thing per test
- Use descriptive test names
- Follow Arrange-Act-Assert pattern
- Mock external dependencies
- Test edge cases and error conditions

### UI Testing
- Test critical user flows
- Verify UI element states
- Test accessibility features
- Handle asynchronous operations
- Test different device sizes
- Test orientation changes

### Performance Testing
- Establish baseline metrics
- Test with realistic data sets
- Monitor memory usage
- Test background operations
- Test network conditions
- Profile CPU usage

## Test Configuration

### XCTest Configuration
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
- Use Test Navigator
- Configure test plans
- Set up CI integration
- Generate test reports
- Track test coverage

## Documentation
- [Testing Guide](../../docs/testing.md)
- [Mock Objects](../../docs/mocks.md)
- [Performance Testing](../../docs/performance.md)
- [UI Testing](../../docs/ui-testing.md)
