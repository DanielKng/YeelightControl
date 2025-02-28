# Lighting Effects Example

This example demonstrates how to create and apply various lighting effects using the YeelightControl API.

## Features
- Effect creation
- Effect application
- Custom transitions
- Effect scheduling
- Multiple device synchronization

## Implementation

### Effect Creation
```swift
import YeelightControl

// Initialize effect manager
let effectManager = try EffectManager()

// Create color flow effect
let colorFlow = try effectManager.createEffect(
    parameters: .init(
        type: .colorFlow,
        colors: [.red, .green, .blue],
        transition: .smooth,
        duration: .seconds(30),
        repeat: true
    )
)

// Create breathing effect
let breathing = try effectManager.createEffect(
    parameters: .init(
        type: .breathing,
        brightness: [1.0, 0.3, 1.0],
        transition: .smooth,
        duration: .seconds(10),
        repeat: true
    )
)

// Create custom effect
let custom = try effectManager.createEffect(
    parameters: .init(
        type: .custom,
        states: [
            DeviceState(power: true, brightness: 1.0, color: .white),
            DeviceState(power: true, brightness: 0.5, color: .orange),
            DeviceState(power: true, brightness: 0.2, color: .red)
        ],
        timing: [5.0, 5.0, 5.0],
        transition: .smooth
    )
)
```

### Effect Application
```swift
// Apply effect to single device
try await effectManager.apply(colorFlow, to: deviceId)

// Apply to multiple devices
try await effectManager.apply(
    breathing,
    to: [device1Id, device2Id]
)

// Apply with options
try await effectManager.apply(
    custom,
    to: devices,
    options: .init(
        sync: true,
        priority: .high,
        timeout: 30.0
    )
)
```

### Effect Scheduling
```swift
// Schedule effect
try await effectManager.schedule(
    colorFlow,
    for: deviceId,
    schedule: .init(
        startTime: Date().addingTimeInterval(3600),
        repeat: .daily
    )
)

// Cancel scheduled effect
try await effectManager.cancelScheduled(
    for: deviceId
)
```

### Effect Control
```swift
// Stop effect
try await effectManager.stop(on: deviceId)

// Pause effect
try await effectManager.pause(on: deviceId)

// Resume effect
try await effectManager.resume(on: deviceId)
```

### Effect Synchronization
```swift
// Create synchronized effect group
let group = try effectManager.createGroup(
    devices: [device1Id, device2Id],
    sync: .strict
)

// Apply effect to group
try await effectManager.apply(
    colorFlow,
    to: group
)
```

### Error Handling
```swift
do {
    try await effectManager.apply(effect, to: deviceId)
} catch EffectError.invalidParameters(let reason) {
    print("Invalid parameters: \(reason)")
} catch EffectError.executionFailed(let reason) {
    print("Execution failed: \(reason)")
} catch EffectError.unsupportedEffect(let deviceId) {
    print("Effect not supported by device: \(deviceId)")
} catch {
    print("Unknown error: \(error)")
}
```

## Usage
1. Copy the example code
2. Add necessary imports
3. Initialize effect manager
4. Create desired effects
5. Apply to devices

## Notes
- Check device capabilities
- Handle effect interruptions
- Manage effect lifecycle
- Consider performance impact
- Implement proper cleanup 