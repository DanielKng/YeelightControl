# API Reference

## Core APIs

### Device Management

#### DeviceManager
The main interface for discovering and controlling Yeelight devices.

```swift
protocol DeviceManaging {
    func discoverDevices() async throws -> [Device]
    func connect(to deviceId: String) async throws
    func disconnect(from deviceId: String) async throws
    func getState(for deviceId: String) async throws -> DeviceState
    func setPower(_ isOn: Bool, for deviceId: String) async throws
    func setBrightness(_ level: Float, for deviceId: String) async throws
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

## Additional Resources
- [Getting Started Guide](getting-started.md)
- [Migration Guide](migration-guide.md)
- [Security Guide](security.md)
- [Module Documentation](../Sources/) 