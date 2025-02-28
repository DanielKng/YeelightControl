# Tests Module

This module contains all test suites for the YeelightControl app, ensuring code quality, functionality, and reliability across all modules.

## Test Organization

### Unit Tests
- `UnitTests/` - Component and integration tests
  - Core module tests
    - Manager tests
    - Service tests
    - Type tests
  - Features module tests
    - Scene management tests
    - Effect system tests
    - Automation tests
  - Mock implementations
  - Test utilities

### UI Tests
- `UITests/` - User interface tests
  - View tests
  - Component tests
  - Integration tests
  - User flow tests
  - Accessibility tests

## Testing Strategy

### Unit Testing
1. **Core Module**
   - Service container initialization
   - Manager functionality
   - Network operations
   - Data persistence
   - Error handling

2. **Features Module**
   - Scene management
   - Effect processing
   - Automation rules
   - Room organization

3. **Test Coverage Goals**
   - Core module: 90%+ coverage
   - Features module: 85%+ coverage
   - Critical paths: 100% coverage

### UI Testing
1. **Component Testing**
   - Individual view behavior
   - User interactions
   - State management
   - Animation verification

2. **Integration Testing**
   - Feature workflows
   - Navigation flows
   - Data flow
   - Error states

3. **Accessibility Testing**
   - VoiceOver functionality
   - Dynamic type
   - Color contrast
   - Navigation

## Running Tests

### All Tests
```bash
swift test
```

### Specific Test Suites
```bash
# Run Core module tests
swift test --filter "CoreTests"

# Run Feature module tests
swift test --filter "FeaturesTests"

# Run UI tests
swift test --filter "UITests"
```

### Coverage Report
```bash
swift test --enable-code-coverage
xcrun llvm-cov report .build/debug/YeelightControlPackageTests.xctest/Contents/MacOS/YeelightControlPackageTests
```

## Test Development Guidelines

1. **Naming Convention**
   - Test classes: `{Component}Tests`
   - Test methods: `test_{scenario}_{expectedResult}`
   - Mock classes: `Mock{Component}`

2. **Test Structure**
   ```swift
   final class DeviceManagerTests: XCTestCase {
       // MARK: - Properties
       private var sut: DeviceManager!
       private var mockNetwork: MockNetworkManager!
       
       // MARK: - Setup
       override func setUp() {
           super.setUp()
           mockNetwork = MockNetworkManager()
           sut = DeviceManager(network: mockNetwork)
       }
       
       // MARK: - Tests
       func test_deviceDiscovery_succeeds() async throws {
           // Given
           mockNetwork.mockDevices = [mockDevice]
           
           // When
           let devices = try await sut.discoverDevices()
           
           // Then
           XCTAssertEqual(devices.count, 1)
       }
   }
   ```

3. **Mock Objects**
   - Use protocol-based mocks
   - Implement verification
   - Track method calls
   - Support error simulation

4. **Async Testing**
   - Use async/await
   - Test timeouts
   - Error conditions
   - Race conditions

## Continuous Integration

Tests are automatically run:
- On pull requests
- Before merges to main
- On release branches
- Nightly for performance tests

## Best Practices

1. **Test Independence**
   - Tests should be self-contained
   - Clean up after each test
   - No shared state between tests

2. **Test Data**
   - Use factory methods
   - Avoid hard-coded values
   - Document test data requirements

3. **Error Testing**
   - Test error conditions
   - Verify error messages
   - Check error recovery

4. **Performance Testing**
   - Measure critical operations
   - Set performance baselines
   - Monitor regressions
