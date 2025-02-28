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
protocol DeviceManaging {
    /// Discover available devices on the network
    func discoverDevices() async throws -> [Device]
    
    /// Connect to a specific device
    func connect(to deviceId: String) async throws
    
    /// Disconnect from a device
    func disconnect(from deviceId: String) async throws
    
    /// Get device state
    func getState(for deviceId: String) async throws -> DeviceState
    
    /// Set device power state
    func setPower(_ isOn: Bool, for deviceId: String) async throws
    
    /// Set device brightness (0.0 - 1.0)
    func setBrightness(_ level: Float, for deviceId: String) async throws
    
    /// Set device color (RGB)
    func setColor(_ color: Color, for deviceId: String) async throws
}
```

#### YeelightManager
```swift
protocol YeelightManaging {
    /// Send raw command to device
    func sendCommand(_ command: YeelightCommand, to deviceId: String) async throws
    
    /// Get device capabilities
    func getCapabilities(for deviceId: String) async throws -> DeviceCapabilities
    
    /// Update device firmware
    func updateFirmware(for deviceId: String) async throws
}
```

### Effect Management

#### EffectManager
```swift
protocol EffectManaging {
    /// Apply effect to device(s)
    func apply(_ effect: Effect, to devices: [String]) async throws
    
    /// Stop current effect
    func stop(on devices: [String]) async throws
    
    /// Get available effects
    func getAvailableEffects() -> [Effect]
    
    /// Create custom effect
    func createEffect(parameters: EffectParameters) throws -> Effect
}
```

### Scene Management

#### SceneManager
```swift
protocol SceneManaging {
    /// Create new scene
    func createScene(_ scene: Scene) async throws
    
    /// Activate scene
    func activateScene(_ sceneId: String) async throws
    
    /// Update existing scene
    func updateScene(_ scene: Scene) async throws
    
    /// Delete scene
    func deleteScene(_ sceneId: String) async throws
    
    /// List available scenes
    func listScenes() async throws -> [Scene]
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

```swift
enum DeviceError: Error {
    case connectionFailed(reason: String)
    case commandFailed(command: String, reason: String)
    case invalidState
    case timeout
    case unauthorized
}

enum SceneError: Error {
    case activationFailed(reason: String)
    case invalidConfiguration
    case notFound
}

enum AutomationError: Error {
    case invalidRule
    case executionFailed(reason: String)
    case conditionNotMet
}
```

### Error Recovery

```swift
protocol ErrorRecoverable {
    /// Attempt to recover from error
    func recover(from error: Error) async throws
    
    /// Check if error is recoverable
    func isRecoverable(_ error: Error) -> Bool
    
    /// Get recovery options
    func recoveryOptions(for error: Error) -> [RecoveryOption]
}
```

## Best Practices

### Device Control
1. Always check device connectivity before sending commands
2. Implement retry logic for network operations
3. Cache device state for better responsiveness
4. Handle background state appropriately

### Effect Management
1. Validate effect parameters before application
2. Implement smooth transitions
3. Handle interruptions gracefully
4. Consider device capabilities

### Scene Management
1. Validate scene configuration
2. Handle partial failures
3. Implement proper state restoration
4. Consider timing and transitions

### Error Handling
1. Provide meaningful error messages
2. Implement proper recovery mechanisms
3. Log errors appropriately
4. Handle edge cases

## API Versioning

The API follows semantic versioning:
- Major version: Breaking changes
- Minor version: New features
- Patch version: Bug fixes

Current version: 1.0.0

## Security Considerations

1. **Authentication**
   - Device authentication
   - User authorization
   - API key management

2. **Network Security**
   - Secure communication
   - Certificate validation
   - Data encryption

3. **Privacy**
   - Data collection
   - User consent
   - Data retention

## Rate Limiting

1. **Device Commands**
   - Maximum 10 commands per second per device
   - Queue management for burst commands
   - Priority handling

2. **Network Discovery**
   - Scan interval: 30 seconds
   - Cache results
   - Background refresh

## Migration Guide

### Version 1.0.0
- Initial release

### Future Versions
- Planned features
- Breaking changes
- Migration paths

## Support

For API support:
- GitHub Issues
- Documentation Updates
- Version Compatibility
- Breaking Changes
