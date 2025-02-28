# YeelightControl API Documentation

## Table of Contents
- [Overview](#overview)
- [Core APIs](#core-apis)
- [Feature APIs](#feature-apis)
- [UI Components](#ui-components)
- [Widget Integration](#widget-integration)
- [Error Handling](#error-handling)
- [Additional Documentation](#additional-documentation)

## Overview

YeelightControl provides a comprehensive set of APIs for controlling Yeelight smart lighting devices. The API is organized into several layers, each serving a specific purpose in the application architecture.

### API Layers
1. Device Control Layer - Direct device interaction
2. Feature Layer - High-level functionality
3. UI Layer - User interface components
4. Widget Layer - Home screen widgets

### Common Patterns
- Async/await for asynchronous operations
- Result types for error handling
- Protocol-based interfaces
- Dependency injection

## Additional Documentation

Detailed implementation documentation is available in the respective module directories:

### Module-Specific Documentation
- [`Sources/Core/README.md`](../Sources/Core/README.md) - Core module architecture, components, and implementation details
- [`Sources/Features/README.md`](../Sources/Features/README.md) - Feature implementations and integration guidelines
- [`Sources/UI/README.md`](../Sources/UI/README.md) - UI components, design system, and usage patterns
- [`Sources/Tests/README.md`](../Sources/Tests/README.md) - Testing strategy, organization, and best practices
- [`Sources/Widget/README.md`](../Sources/Widget/README.md) - Widget implementation and configuration
- [`Sources/App/README.md`](../Sources/App/README.md) - Application structure and coordination

Each module's documentation provides:
- Detailed component descriptions
- Implementation guidelines
- Usage examples
- Best practices
- Testing approaches
- Integration patterns

## Core APIs

### Device Management

#### DeviceManager
```swift
/// Protocol defining core device management functionality
/// Responsible for device discovery, connection management, and basic device control
protocol DeviceManaging {
    /// Discovers and returns a list of available Yeelight devices on the local network
    /// - Returns: Array of discovered Device objects
    /// - Throws: DeviceError if discovery fails or network is unavailable
    func discoverDevices() async throws -> [Device]
    
    /// Establishes connection with a specific device
    /// - Parameter deviceId: Unique identifier of the target device
    /// - Throws: DeviceError.connectionFailed if connection cannot be established
    func connect(to deviceId: String) async throws
    
    /// Safely disconnects from a specified device
    /// - Parameter deviceId: Unique identifier of the device to disconnect from
    /// - Throws: DeviceError if disconnection fails or device is not connected
    func disconnect(from deviceId: String) async throws
    
    /// Retrieves current state of a specified device
    /// - Parameter deviceId: Unique identifier of the target device
    /// - Returns: DeviceState containing current power, brightness, color, and other properties
    /// - Throws: DeviceError if state cannot be retrieved
    func getState(for deviceId: String) async throws -> DeviceState
    
    /// Controls power state of a specified device
    /// - Parameters:
    ///   - isOn: Boolean indicating desired power state (true = on, false = off)
    ///   - deviceId: Unique identifier of the target device
    /// - Throws: DeviceError if power state cannot be set
    func setPower(_ isOn: Bool, for deviceId: String) async throws
    
    /// Adjusts brightness level of a specified device
    /// - Parameters:
    ///   - level: Float value between 0.0 (off) and 1.0 (maximum brightness)
    ///   - deviceId: Unique identifier of the target device
    /// - Throws: DeviceError if brightness cannot be set
    func setBrightness(_ level: Float, for deviceId: String) async throws
    
    /// Sets RGB color of a specified device
    /// - Parameters:
    ///   - color: Color object representing desired RGB values
    ///   - deviceId: Unique identifier of the target device
    /// - Throws: DeviceError if color cannot be set
    func setColor(_ color: Color, for deviceId: String) async throws
}
```

#### YeelightManager
```swift
/// Protocol for Yeelight-specific device management functionality
/// Handles low-level device communication and advanced features
protocol YeelightManaging {
    /// Sends raw command to device using Yeelight protocol
    /// - Parameters:
    ///   - command: YeelightCommand object containing command details
    ///   - deviceId: Unique identifier of the target device
    /// - Throws: DeviceError if command fails or device is unreachable
    func sendCommand(_ command: YeelightCommand, to deviceId: String) async throws
    
    /// Retrieves supported features and limitations of a device
    /// - Parameter deviceId: Unique identifier of the target device
    /// - Returns: DeviceCapabilities object detailing supported features
    /// - Throws: DeviceError if capabilities cannot be retrieved
    func getCapabilities(for deviceId: String) async throws -> DeviceCapabilities
    
    /// Initiates firmware update process for a device
    /// - Parameter deviceId: Unique identifier of the target device
    /// - Throws: DeviceError if update fails or is not available
    func updateFirmware(for deviceId: String) async throws
}
```

### Effect Management

#### EffectManager
```swift
/// Protocol for managing lighting effects across devices
/// Handles creation, application, and management of lighting effects
protocol EffectManaging {
    /// Applies specified effect to one or more devices
    /// - Parameters:
    ///   - effect: Effect object containing effect parameters and timing
    ///   - devices: Array of device IDs to apply the effect to
    /// - Throws: EffectError if effect cannot be applied
    func apply(_ effect: Effect, to devices: [String]) async throws
    
    /// Stops currently running effect on specified devices
    /// - Parameter devices: Array of device IDs to stop effects on
    /// - Throws: EffectError if effect cannot be stopped
    func stop(on devices: [String]) async throws
    
    /// Returns list of predefined and custom effects available for use
    /// - Returns: Array of available Effect objects
    func getAvailableEffects() -> [Effect]
    
    /// Creates new custom effect based on provided parameters
    /// - Parameter parameters: EffectParameters defining effect behavior
    /// - Returns: Newly created Effect object
    /// - Throws: EffectError if parameters are invalid
    func createEffect(parameters: EffectParameters) throws -> Effect
}
```

### Scene Management

#### SceneManager
```swift
/// Protocol for managing lighting scenes across multiple devices
/// Handles creation, modification, and activation of predefined lighting configurations
protocol SceneManaging {
    /// Creates new scene with specified configuration
    /// - Parameters:
    ///   - name: Unique name for the scene
    ///   - devices: Array of device configurations for the scene
    ///   - schedule: Optional scheduling parameters for automatic activation
    /// - Returns: Newly created Scene object
    /// - Throws: SceneError if creation fails or name conflicts
    func createScene(name: String, devices: [DeviceConfig], schedule: Schedule?) async throws -> Scene
    
    /// Activates specified scene across all associated devices
    /// - Parameter scene: Scene object to activate
    /// - Throws: SceneError if activation fails or devices are unreachable
    func activateScene(_ scene: Scene) async throws
    
    /// Updates existing scene with new configuration
    /// - Parameters:
    ///   - scene: Scene object to update
    ///   - config: New configuration parameters
    /// - Throws: SceneError if update fails or scene doesn't exist
    func updateScene(_ scene: Scene, with config: SceneConfig) async throws
    
    /// Deletes specified scene from storage
    /// - Parameter scene: Scene object to delete
    /// - Throws: SceneError if deletion fails
    func deleteScene(_ scene: Scene) async throws
}
```

### Testing
```swift
protocol TestingProtocol {
    /// Run unit tests for a specific component
    /// - Parameter component: Component to test
    /// - Returns: Test results
    /// - Throws: TestError if tests fail
    func runTests(for component: Component) async throws -> TestResults
    
    /// Run integration tests
    /// - Parameter configuration: Test configuration
    /// - Returns: Test results
    /// - Throws: TestError if tests fail
    func runIntegrationTests(
        configuration: TestConfiguration
    ) async throws -> TestResults
    
    /// Run performance tests
    /// - Parameter metrics: Metrics to measure
    /// - Returns: Performance results
    /// - Throws: TestError if tests fail
    func runPerformanceTests(
        metrics: [PerformanceMetric]
    ) async throws -> PerformanceResults
}
```

## Feature APIs

### Automation

#### AutomationManager
```swift
protocol AutomationManaging {
    /// Create automation rule
    func createRule(_ rule: AutomationRule) async throws
    
    /// Enable/disable rule
    func setRuleEnabled(_ ruleId: String, enabled: Bool) async throws
    
    /// Delete rule
    func deleteRule(_ ruleId: String) async throws
    
    /// List active rules
    func listRules() async throws -> [AutomationRule]
}
```

### Room Management

#### RoomManager
```swift
protocol RoomManaging {
    /// Create room
    func createRoom(_ room: Room) async throws
    
    /// Add devices to room
    func addDevices(_ deviceIds: [String], to roomId: String) async throws
    
    /// Remove devices from room
    func removeDevices(_ deviceIds: [String], from roomId: String) async throws
    
    /// Delete room
    func deleteRoom(_ roomId: String) async throws
}
```

## UI Components

### Device Control

#### DeviceControlView
```swift
struct DeviceControlView: View {
    /// Initialize with device
    init(device: Device)
    
    /// Binding for device state
    @Binding var deviceState: DeviceState
    
    /// Control callbacks
    var onPowerToggle: () -> Void
    var onBrightnessChange: (Float) -> Void
    var onColorChange: (Color) -> Void
}
```

### Scene Control

#### SceneControlView
```swift
struct SceneControlView: View {
    /// Initialize with scene
    init(scene: Scene)
    
    /// Scene activation callback
    var onActivate: () -> Void
    
    /// Scene edit callback
    var onEdit: () -> Void
}
```

## Widget Integration

### Device Control Widget

#### DeviceControlWidget
```swift
struct DeviceControlWidget: Widget {
    /// Widget configuration
    var body: some WidgetConfiguration
    
    /// Timeline provider
    struct Provider: TimelineProvider {
        func getTimeline(in context: Context) async -> Timeline<DeviceEntry>
    }
}
```

### Status Widget

#### StatusWidget
```swift
struct StatusWidget: Widget {
    /// Widget configuration
    var body: some WidgetConfiguration
    
    /// Timeline provider
    struct Provider: TimelineProvider {
        func getTimeline(in context: Context) async -> Timeline<StatusEntry>
    }
}
```

## Error Handling

### Error Types

#### DeviceError
```swift
/// Enumeration of possible device-related errors
enum DeviceError: Error {
    /// Device cannot be found on network
    case deviceNotFound
    
    /// Connection to device failed
    /// - Parameter reason: String describing connection failure reason
    case connectionFailed(reason: String)
    
    /// Device is not responding to commands
    case deviceUnresponsive
    
    /// Operation timeout exceeded
    /// - Parameter seconds: Number of seconds before timeout
    case timeout(seconds: Int)
    
    /// Device firmware is incompatible
    /// - Parameter required: Required firmware version
    /// - Parameter current: Current firmware version
    case firmwareIncompatible(required: String, current: String)
    
    /// Operation not supported by device
    /// - Parameter operation: String describing unsupported operation
    case operationNotSupported(operation: String)
}
```

#### EffectError
```swift
/// Enumeration of possible effect-related errors
enum EffectError: Error {
    /// Effect parameters are invalid
    /// - Parameter reason: Description of validation failure
    case invalidParameters(reason: String)
    
    /// Effect execution failed
    /// - Parameter reason: Description of execution failure
    case executionFailed(reason: String)
    
    /// Effect is not supported by device
    /// - Parameter deviceId: ID of device that doesn't support the effect
    case unsupportedEffect(deviceId: String)
    
    /// Effect was interrupted
    /// - Parameter reason: Description of interruption cause
    case interrupted(reason: String)
}

#### SceneError
```swift
/// Enumeration of possible scene-related errors
enum SceneError: Error {
    /// Scene name already exists
    case duplicateName
    
    /// Scene configuration is invalid
    /// - Parameter reason: Description of configuration issue
    case invalidConfiguration(reason: String)
    
    /// Scene activation failed
    /// - Parameter reason: Description of activation failure
    case activationFailed(reason: String)
    
    /// Scene not found in storage
    case sceneNotFound
    
    /// Scene schedule is invalid
    /// - Parameter reason: Description of scheduling issue
    case invalidSchedule(reason: String)
}

### Error Recovery

#### Recovery Protocols
```swift
/// Protocol defining error recovery strategies
protocol ErrorRecoverable {
    /// Attempts to recover from a specific error
    /// - Parameters:
    ///   - error: The error to recover from
    ///   - context: Additional context for recovery attempt
    /// - Returns: Boolean indicating if recovery was successful
    /// - Throws: RecoveryError if recovery attempt fails
    func attemptRecovery(from error: Error, context: RecoveryContext) async throws -> Bool
    
    /// Suggests recovery options for a given error
    /// - Parameter error: The error to get recovery options for
    /// - Returns: Array of available recovery options
    func getRecoveryOptions(for error: Error) -> [RecoveryOption]
}
```

### Best Practices

#### Device Control
```swift
/// Guidelines for optimal device control implementation
protocol DeviceControlBestPractices {
    /// Implement robust connection management
    /// - Always check device availability before sending commands
    /// - Handle connection timeouts gracefully
    /// - Implement automatic reconnection logic
    /// - Cache device states for quick access
    
    /// Optimize command execution
    /// - Batch similar commands when possible
    /// - Implement command queuing for sequential operations
    /// - Handle rate limiting appropriately
    /// - Validate commands before sending
    
    /// Manage device state
    /// - Maintain local state cache
    /// - Implement state synchronization
    /// - Handle state conflicts resolution
    /// - Provide state change notifications
}
```

#### Effect Management
```swift
/// Guidelines for implementing effect management
protocol EffectManagementBestPractices {
    /// Effect Creation
    /// - Validate effect parameters before creation
    /// - Check device compatibility
    /// - Implement proper error handling
    /// - Document effect requirements
    
    /// Effect Execution
    /// - Handle device unavailability
    /// - Implement proper timing control
    /// - Manage effect transitions
    /// - Monitor effect execution
    
    /// Effect Optimization
    /// - Cache commonly used effects
    /// - Implement effect previews
    /// - Optimize resource usage
    /// - Handle effect interruptions
}
```

#### Scene Management
```swift
/// Guidelines for scene management implementation
protocol SceneManagementBestPractices {
    /// Scene Creation
    /// - Validate device configurations
    /// - Implement proper naming conventions
    /// - Handle scheduling requirements
    /// - Manage scene dependencies
    
    /// Scene Activation
    /// - Check device availability
    /// - Handle partial activation
    /// - Implement fallback options
    /// - Monitor activation status
    
    /// Scene Storage
    /// - Implement proper persistence
    /// - Handle version control
    /// - Manage scene updates
    /// - Implement backup/restore
}
```

#### Error Handling
```swift
/// Guidelines for implementing error handling
protocol ErrorHandlingBestPractices {
    /// Error Detection
    /// - Implement proper error categorization
    /// - Provide detailed error context
    /// - Handle nested errors
    /// - Log error occurrences
    
    /// Error Recovery
    /// - Implement automatic recovery where possible
    /// - Provide user-friendly error messages
    /// - Handle recovery failures
    /// - Document recovery procedures
    
    /// Error Prevention
    /// - Implement input validation
    /// - Handle edge cases
    /// - Implement proper testing
    /// - Monitor error patterns
}
```

## API Versioning

### Version Management
```swift
/// Protocol for managing API versions and compatibility
protocol VersionManagement {
    /// Current API version information
    /// - Major: Breaking changes
    /// - Minor: New features, backwards compatible
    /// - Patch: Bug fixes, backwards compatible
    static var currentVersion: SemanticVersion { get }
    
    /// Checks compatibility between versions
    /// - Parameters:
    ///   - version: Version to check compatibility with
    /// - Returns: Boolean indicating compatibility
    static func isCompatible(with version: SemanticVersion) -> Bool
    
    /// Provides migration path between versions
    /// - Parameters:
    ///   - fromVersion: Source version
    ///   - toVersion: Target version
    /// - Returns: Array of migration steps
    static func migrationPath(from fromVersion: SemanticVersion, to toVersion: SemanticVersion) -> [MigrationStep]
}
```

## Security Considerations

### Authentication
```swift
/// Protocol for implementing secure device authentication
protocol DeviceAuthentication {
    /// Authenticates with a device using secure credentials
    /// - Parameters:
    ///   - deviceId: Target device identifier
    ///   - credentials: Authentication credentials
    /// - Returns: Authentication token
    /// - Throws: AuthenticationError if authentication fails
    func authenticate(deviceId: String, credentials: DeviceCredentials) async throws -> AuthToken
    
    /// Validates authentication token
    /// - Parameter token: Token to validate
    /// - Returns: Boolean indicating if token is valid
    func validateToken(_ token: AuthToken) -> Bool
    
    /// Revokes authentication token
    /// - Parameter token: Token to revoke
    /// - Throws: AuthenticationError if revocation fails
    func revokeToken(_ token: AuthToken) async throws
}
```

### Encryption
```swift
/// Protocol for implementing secure communication
protocol SecureCommunication {
    /// Establishes secure channel with device
    /// - Parameter deviceId: Target device identifier
    /// - Returns: Encrypted channel object
    /// - Throws: SecurityError if channel establishment fails
    func establishSecureChannel(with deviceId: String) async throws -> SecureChannel
    
    /// Encrypts command data
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - key: Encryption key
    /// - Returns: Encrypted data
    /// - Throws: EncryptionError if encryption fails
    func encryptCommand(_ data: Data, using key: EncryptionKey) throws -> EncryptedData
    
    /// Decrypts response data
    /// - Parameters:
    ///   - data: Data to decrypt
    ///   - key: Decryption key
    /// - Returns: Decrypted data
    /// - Throws: DecryptionError if decryption fails
    func decryptResponse(_ data: EncryptedData, using key: EncryptionKey) throws -> Data
}
```

## Support and Resources

### Documentation
- [Getting Started Guide](../docs/getting-started.md)
- [API Reference](../docs/api-reference.md)
- [Migration Guide](../docs/migration-guide.md)
- [Security Best Practices](../docs/security.md)
- [Troubleshooting Guide](../docs/troubleshooting.md)

### Support Channels
- GitHub Issues: Report bugs and feature requests

### Sample Code
- [Basic Device Control](../examples/basic-control)
- [Effect Creation](../examples/effects)
- [Scene Management](../examples/scenes)
- [Error Handling](../examples/error-handling)
- [Security Implementation](../examples/security)

### Support
For technical support and assistance:
- GitHub Issues: Report bugs and feature requests
- Documentation: Refer to module README files

### Best Practices
- Follow the provided protocols and interfaces
- Handle errors appropriately
- Implement proper error recovery
- Use appropriate logging levels
- Follow rate limiting guidelines
- Maintain type safety

### Documentation
For detailed information about specific topics, please refer to the module README files:
- [Core Module](../Sources/Core/README.md)
- [Features Module](../Sources/Features/README.md)
- [UI Module](../Sources/UI/README.md)
- [Tests Module](../Sources/Tests/README.md)
- [Widget Module](../Sources/Widget/README.md)
- [App Module](../Sources/App/README.md)
