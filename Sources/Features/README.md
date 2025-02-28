# Features Module

## Overview
The Features module implements high-level functionality and business logic for YeelightControl's main features. It builds upon the Core module's foundation to provide sophisticated lighting control capabilities.

## Architecture

### Directory Structure
```
Features/
├── Scenes/      - Scene management and activation
├── Effects/     - Lighting effect implementation
├── Automation/  - Automated control rules
└── Rooms/       - Room-based device grouping
```

## Features

### Scene Management

#### Scene Creation
```swift
struct SceneCreator {
    /// Creates a new scene with specified configuration
    /// - Parameters:
    ///   - name: Scene name
    ///   - devices: Devices to include
    ///   - states: Target device states
    ///   - schedule: Optional activation schedule
    /// - Returns: Created Scene object
    /// - Throws: SceneError if creation fails
    func createScene(
        name: String,
        devices: [Device],
        states: [DeviceState],
        schedule: Schedule?
    ) async throws -> Scene
}
```

#### Scene Activation
```swift
struct SceneActivator {
    /// Activates a scene across all included devices
    /// - Parameters:
    ///   - scene: Scene to activate
    ///   - transition: Optional transition duration
    /// - Throws: SceneError if activation fails
    func activateScene(
        _ scene: Scene,
        transition: TimeInterval?
    ) async throws
    
    /// Deactivates current scene
    /// - Parameter transition: Optional transition duration
    /// - Throws: SceneError if deactivation fails
    func deactivateScene(
        transition: TimeInterval?
    ) async throws
}
```

### Effect System

#### Effect Creation
```swift
struct EffectBuilder {
    /// Creates a new lighting effect
    /// - Parameters:
    ///   - type: Effect type (e.g., color flow, pulse)
    ///   - parameters: Effect-specific parameters
    ///   - duration: Effect duration
    /// - Returns: Created Effect object
    /// - Throws: EffectError if creation fails
    func createEffect(
        type: EffectType,
        parameters: EffectParameters,
        duration: TimeInterval
    ) throws -> Effect
}
```

#### Effect Application
```swift
struct EffectController {
    /// Applies effect to specified devices
    /// - Parameters:
    ///   - effect: Effect to apply
    ///   - devices: Target devices
    ///   - options: Application options
    /// - Throws: EffectError if application fails
    func applyEffect(
        _ effect: Effect,
        to devices: [Device],
        options: EffectOptions
    ) async throws
}
```

### Automation

#### Rule Creation
```swift
struct AutomationRuleBuilder {
    /// Creates new automation rule
    /// - Parameters:
    ///   - trigger: Rule trigger condition
    ///   - actions: Actions to perform
    ///   - constraints: Optional constraints
    /// - Returns: Created Rule object
    /// - Throws: AutomationError if creation fails
    func createRule(
        trigger: Trigger,
        actions: [Action],
        constraints: [Constraint]?
    ) throws -> Rule
}
```

#### Rule Execution
```swift
struct RuleExecutor {
    /// Executes automation rule
    /// - Parameters:
    ///   - rule: Rule to execute
    ///   - context: Execution context
    /// - Returns: Execution result
    /// - Throws: AutomationError if execution fails
    func executeRule(
        _ rule: Rule,
        context: ExecutionContext
    ) async throws -> ExecutionResult
}
```

### Room Management

#### Room Creation
```swift
struct RoomManager {
    /// Creates new room with devices
    /// - Parameters:
    ///   - name: Room name
    ///   - devices: Devices in room
    ///   - location: Optional room location
    /// - Returns: Created Room object
    /// - Throws: RoomError if creation fails
    func createRoom(
        name: String,
        devices: [Device],
        location: Location?
    ) throws -> Room
}
```

#### Room Control
```swift
struct RoomController {
    /// Controls all devices in room
    /// - Parameters:
    ///   - room: Target room
    ///   - state: Desired state
    ///   - transition: Optional transition duration
    /// - Throws: RoomError if control fails
    func controlRoom(
        _ room: Room,
        state: DeviceState,
        transition: TimeInterval?
    ) async throws
}
```

## Integration Examples

### Scene with Schedule
```swift
// Create and schedule evening scene
let scene = try await sceneCreator.createScene(
    name: "Evening Relax",
    devices: livingRoomLights,
    states: [.dim, .warmWhite],
    schedule: .daily(at: "19:00")
)
```

### Complex Effect
```swift
// Create color flow effect
let effect = try effectBuilder.createEffect(
    type: .colorFlow,
    parameters: .init(
        colors: [.red, .blue, .green],
        transition: .smooth,
        repeat: true
    ),
    duration: .minutes(30)
)
```

### Automation Rule
```swift
// Create location-based rule
let rule = try automationBuilder.createRule(
    trigger: .location(
        event: .enter,
        region: homeRegion
    ),
    actions: [
        .activateScene("Welcome Home"),
        .setDeviceState(hallwayLight, .on)
    ],
    constraints: [
        .timeRange("17:00"..."23:00"),
        .dayOfWeek([.monday, .friday])
    ]
)
```

### Room Control
```swift
// Control entire room
try await roomController.controlRoom(
    livingRoom,
    state: .movie,
    transition: .seconds(2)
)
```

## Best Practices

### Scene Management
- Validate device compatibility
- Handle partial failures gracefully
- Implement proper state restoration
- Cache scene configurations
- Handle schedule conflicts

### Effect System
- Validate effect parameters
- Implement smooth transitions
- Handle interruptions
- Monitor system resources
- Support effect preview

### Automation
- Validate rule logic
- Handle trigger conditions
- Implement fail-safes
- Log rule execution
- Support rule testing

### Room Management
- Handle device changes
- Maintain room state
- Support hierarchical rooms
- Implement room discovery
- Handle location updates

## Dependencies
- Core module
- Combine framework
- CoreLocation framework

## Testing
- Unit tests for business logic
- Integration tests for features
- Performance testing
- State validation
- Error handling verification

## Documentation
- [Scene Guide](../../docs/scenes.md)
- [Effect System](../../docs/effects.md)
- [Automation Rules](../../docs/automation.md)
- [Room Management](../../docs/rooms.md)
