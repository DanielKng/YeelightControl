# Scene Management Example

This example demonstrates how to create and manage lighting scenes using the YeelightControl API.

## Features
- Scene creation
- Scene activation
- Scene scheduling
- Room integration
- Scene groups

## Implementation

### Scene Creation
```swift
import YeelightControl

// Initialize scene manager
let sceneManager = try SceneManager()

// Create movie scene
let movieScene = try await sceneManager.createScene(
    name: "Movie Night",
    devices: [
        DeviceConfig(
            deviceId: tvLight.id,
            state: DeviceState(
                power: true,
                brightness: 0.3,
                color: .blue
            )
        ),
        DeviceConfig(
            deviceId: ceilingLight.id,
            state: DeviceState(
                power: false
            )
        )
    ]
)

// Create reading scene
let readingScene = try await sceneManager.createScene(
    name: "Reading",
    devices: [
        DeviceConfig(
            deviceId: readingLight.id,
            state: DeviceState(
                power: true,
                brightness: 0.8,
                temperature: 4000
            )
        )
    ]
)

// Create evening scene
let eveningScene = try await sceneManager.createScene(
    name: "Evening",
    devices: [
        DeviceConfig(
            deviceId: livingRoomLight.id,
            state: DeviceState(
                power: true,
                brightness: 0.5,
                temperature: 2700
            )
        ),
        DeviceConfig(
            deviceId: kitchenLight.id,
            state: DeviceState(
                power: true,
                brightness: 0.7,
                temperature: 3000
            )
        )
    ],
    schedule: Schedule(
        time: "19:00",
        days: [.monday, .tuesday, .wednesday, .thursday, .friday]
    )
)
```

### Scene Activation
```swift
// Activate scene
try await sceneManager.activateScene(movieScene)

// Activate with transition
try await sceneManager.activateScene(
    readingScene,
    transition: .smooth(duration: 2.0)
)

// Activate with options
try await sceneManager.activateScene(
    eveningScene,
    options: .init(
        force: true,
        priority: .high,
        transition: .smooth(duration: 1.0)
    )
)
```

### Scene Scheduling
```swift
// Schedule scene
try await sceneManager.scheduleScene(
    movieScene,
    schedule: .init(
        time: "20:00",
        days: [.friday, .saturday],
        repeat: true
    )
)

// Update schedule
try await sceneManager.updateSchedule(
    for: eveningScene,
    schedule: .init(
        time: "18:30",
        days: [.monday, .friday]
    )
)

// Cancel schedule
try await sceneManager.cancelSchedule(for: movieScene)
```

### Room Integration
```swift
// Create room scene
let roomScene = try await sceneManager.createRoomScene(
    name: "Living Room Cozy",
    room: livingRoom,
    state: DeviceState(
        power: true,
        brightness: 0.4,
        temperature: 2500
    )
)

// Activate room scene
try await sceneManager.activateScene(roomScene)
```

### Scene Groups
```swift
// Create scene group
let eveningGroup = try await sceneManager.createGroup(
    name: "Evening Routine",
    scenes: [
        eveningScene,
        roomScene
    ],
    activation: .sequential(delay: 1.0)
)

// Activate group
try await sceneManager.activateGroup(eveningGroup)
```

### Error Handling
```swift
do {
    try await sceneManager.activateScene(scene)
} catch SceneError.sceneNotFound {
    print("Scene not found")
} catch SceneError.activationFailed(let reason) {
    print("Activation failed: \(reason)")
} catch SceneError.deviceUnavailable(let deviceId) {
    print("Device unavailable: \(deviceId)")
} catch {
    print("Unknown error: \(error)")
}
```

## Usage
1. Copy the example code
2. Add necessary imports
3. Initialize scene manager
4. Create desired scenes
5. Activate and manage scenes

## Notes
- Verify device availability
- Handle activation failures
- Manage scene conflicts
- Consider scheduling overlaps
- Implement proper cleanup 