# YeelightControl API Reference

## Quick Links
- 📖 [Getting Started Guide](../guides/getting-started.md)
- 🔒 [Security Guide](../guides/security.md)
- ❓ [Troubleshooting](../guides/troubleshooting.md)
- 📝 [Examples](../examples/)

## Table of Contents
- [Overview](#overview)
- [Core APIs](#core-apis)
  - [Device Management](#device-management)
  - [Effect Management](#effect-management)
  - [Scene Management](#scene-management)
- [Feature APIs](#feature-apis)
  - [Automation](#automation)
  - [Room Management](#room-management)
- [UI Components](#ui-components)
  - [Device Control](#device-control)
  - [Scene Control](#scene-control)
- [Widget Integration](#widget-integration)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

### API Layers
1. **Device Control Layer** ([Examples](../examples/basic-control/README.md))
   - Direct device interaction
   - Low-level communication
   - State management

2. **Feature Layer** ([Examples](../examples/effects/README.md))
   - High-level functionality
   - Effects and scenes
   - Automation

3. **UI Layer** ([UI Module](../Sources/UI/README.md))
   - User interface components
   - SwiftUI integration
   - Widget support

### Common Patterns
- Async/await for asynchronous operations ([Error Handling Example](../examples/error-handling/README.md))
- Result types for error handling
- Protocol-based interfaces
- Dependency injection

## Core APIs

### Device Management
> 📘 See the [Basic Device Control Example](../examples/basic-control/README.md) for implementation details.
> 
> 🔧 For troubleshooting, check the [Device Issues Guide](../guides/troubleshooting.md#device-issues).

#### DeviceManager
The main interface for discovering and controlling Yeelight devices.

```swift
protocol DeviceManaging {
    /// Discovers and returns a list of available Yeelight devices on the local network
    func discoverDevices() async throws -> [Device]
    
    /// Establishes connection with a specific device
    func connect(to deviceId: String) async throws
    
    /// Safely disconnects from a specified device
    func disconnect(from deviceId: String) async throws
    
    /// Retrieves current state of a specified device
    func getState(for deviceId: String) async throws -> DeviceState
    
    /// Controls power state of a specified device
    func setPower(_ isOn: Bool, for deviceId: String) async throws
    
    /// Adjusts brightness level of a specified device
    func setBrightness(_ level: Float, for deviceId: String) async throws
    
    /// Sets RGB color of a specified device
    func setColor(_ color: Color, for deviceId: String) async throws
}
```

#### Device Types
```swift
struct Device {
    let id: String
    let name: String
    var isConnected: Bool
    var state: DeviceState
}

struct DeviceState {
    var power: Bool
    var brightness: Float
    var color: Color?
    var temperature: Int?
}
```

### Effect Management
> 📘 See the [Lighting Effects Example](../examples/effects/README.md) for implementation details.
>
> ⚡ For performance tips, check the [Best Practices Guide](../guides/troubleshooting.md#performance).

#### EffectManager
Interface for creating and applying lighting effects.

```swift
protocol EffectManaging {
    func apply(_ effect: Effect, to devices: [String]) async throws
    func stop(on devices: [String]) async throws
    func getAvailableEffects() -> [Effect]
    func createEffect(parameters: EffectParameters) throws -> Effect
}
```

#### Effect Types
```swift
struct Effect {
    let id: String
    let name: String
    let parameters: EffectParameters
    let duration: TimeInterval
}

struct EffectParameters {
    var type: EffectType
    var colors: [Color]?
    var brightness: [Float]?
    var timing: [TimeInterval]?
}
```

### Scene Management
> 📘 See the [Scene Management Example](../examples/scenes/README.md) for implementation details.
>
> 🔄 For migration information, check the [Migration Guide](../guides/migration.md#scene-management).

#### SceneManager
Interface for managing lighting scenes.

```swift
protocol SceneManaging {
    func createScene(name: String, devices: [DeviceConfig], schedule: Schedule?) async throws -> Scene
    func activateScene(_ scene: Scene) async throws
    func updateScene(_ scene: Scene, with config: SceneConfig) async throws
    func deleteScene(_ scene: Scene) async throws
}
```

#### Scene Types
```swift
struct Scene {
    let id: String
    let name: String
    var devices: [DeviceConfig]
    var schedule: Schedule?
}

struct DeviceConfig {
    let deviceId: String
    var state: DeviceState
}
```

## Feature APIs

### Automation

#### AutomationManager
Interface for creating and managing automation rules.

```swift
protocol AutomationManaging {
    func createRule(_ rule: AutomationRule) async throws
    func setRuleEnabled(_ ruleId: String, enabled: Bool) async throws
    func deleteRule(_ ruleId: String) async throws
    func listRules() async throws -> [AutomationRule]
}
```

### Room Management

#### RoomManager
Interface for managing device rooms and groups.

```swift
protocol RoomManaging {
    func createRoom(_ room: Room) async throws
    func addDevices(_ deviceIds: [String], to roomId: String) async throws
    func removeDevices(_ deviceIds: [String], from roomId: String) async throws
    func deleteRoom(_ roomId: String) async throws
}
```

## UI Components

### Device Control

#### DeviceControlView
SwiftUI view for device control.

```swift
struct DeviceControlView: View {
    init(device: Device)
    var onPowerToggle: () -> Void
    var onBrightnessChange: (Float) -> Void
    var onColorChange: (Color) -> Void
}
```

### Scene Control

#### SceneControlView
SwiftUI view for scene management.

```swift
struct SceneControlView: View {
    init(scene: Scene)
    var onActivate: () -> Void
    var onEdit: () -> Void
}
```

## Widget Integration

### WidgetManager
Interface for managing widgets.

```swift
protocol WidgetManaging {
    func createWidget(parameters: WidgetParameters) throws -> Widget
    func deleteWidget(_ widget: Widget) async throws
    func getWidgets() async throws -> [Widget]
}
```

## Error Handling

### Error Types

```swift
enum DeviceError: Error {
    case deviceNotFound
    case connectionFailed(reason: String)
    case deviceUnresponsive
    case timeout(seconds: Int)
    case firmwareIncompatible(required: String, current: String)
    case operationNotSupported(operation: String)
}

enum EffectError: Error {
    case invalidParameters(reason: String)
    case executionFailed(reason: String)
    case unsupportedEffect(deviceId: String)
    case interrupted(reason: String)
}

enum SceneError: Error {
    case duplicateName
    case invalidConfiguration(reason: String)
    case activationFailed(reason: String)
    case sceneNotFound
    case invalidSchedule(reason: String)
}
```

## Best Practices

### Device Control
> 📘 Related: [Basic Device Control Example](../examples/basic-control/README.md)
>
> 🔧 See also: [Troubleshooting Device Issues](../guides/troubleshooting.md#device-issues)

- Always check device availability before sending commands
- Handle connection timeouts gracefully
- Implement automatic reconnection logic
- Cache device states for quick access
- Batch similar commands when possible
- Validate commands before sending

### Effect Management
> 📘 Related: [Lighting Effects Example](../examples/effects/README.md)
>
> ⚡ See also: [Performance Optimization](../guides/troubleshooting.md#performance)

- Validate effect parameters before creation
- Check device compatibility
- Implement proper timing control
- Cache commonly used effects
- Handle effect interruptions
- Monitor effect execution

### Scene Management
> 📘 Related: [Scene Management Example](../examples/scenes/README.md)
>
> 🔄 See also: [Scene Migration](../guides/migration.md#scene-management)

- Validate device configurations
- Implement proper naming conventions
- Handle scheduling requirements
- Check device availability
- Implement fallback options
- Monitor activation status

### Error Handling
> 📘 Related: [Error Handling Example](../examples/error-handling/README.md)
>
> 🔧 See also: [Troubleshooting Guide](../guides/troubleshooting.md)

- Implement proper error categorization
- Provide detailed error context
- Handle nested errors
- Log error occurrences
- Implement automatic recovery where possible
- Monitor error patterns

## Additional Resources
- [Getting Started Guide](../guides/getting-started.md)
- [Migration Guide](../guides/migration.md)
- [Security Guide](../guides/security.md)
- [Troubleshooting Guide](../guides/troubleshooting.md)
- [Examples](../examples/) 