# Core Module

## Overview
The Core module serves as the foundation of the YeelightControl application, providing essential services, types, and utilities that power the entire system. This module implements the core business logic and infrastructure components necessary for device control, state management, and system operations.

## Architecture

### Directory Structure
```
Core/
├── Analytics/      - Usage tracking and performance monitoring
├── Background/     - Background task management
├── Configuration/  - System and user preferences
├── Device/         - Device discovery and control
├── Effect/         - Lighting effect implementation
├── Error/         - Error handling and recovery
├── Location/      - Geolocation services
├── Logging/       - System logging and debugging
├── Network/       - Network communication
├── Notification/  - Push and local notifications
├── Permission/    - System permission handling
├── Scene/         - Scene management
├── Security/      - Authentication and encryption
├── Services/      - Core service implementations
├── State/         - Application state management
├── Storage/       - Data persistence
└── Types/         - Common type definitions
```

## Components

### Analytics
- Performance metrics collection
- Usage statistics tracking
- Crash reporting
- Analytics event dispatching
- Privacy-compliant data handling

### Background Processing
- Background task scheduling
- Task prioritization
- Resource management
- State persistence
- Background refresh handling

### Configuration
- User preferences management
- System settings
- Feature flags
- Environment configuration
- Default values management

### Device Management
- Device discovery protocols
- Connection management
- State synchronization
- Command queuing
- Device capability detection
- Firmware management

### Effect System
- Effect creation and management
- Transition handling
- Timeline management
- Effect synchronization
- Custom effect definition
- Effect preview generation

### Error Handling
- Error categorization
- Recovery strategies
- Error logging
- User feedback generation
- Debug information collection

### Location Services
- Geofencing
- Room-based location
- Location permission management
- Location-based automation
- Position tracking

### Logging System
- Debug logging
- Performance logging
- Error logging
- Log rotation
- Log export
- Privacy filtering

### Network Layer
- HTTP/HTTPS communication
- WebSocket management
- Network reachability
- Request retrying
- Cache management
- Rate limiting

### Notification System
- Push notification handling
- Local notification scheduling
- Notification grouping
- Action handling
- Rich notification support

### Permission Management
- Permission request handling
- Permission state tracking
- User consent management
- Permission dependencies
- Restricted feature handling

### Scene Management
- Scene creation and editing
- Scene activation
- Scene scheduling
- Scene synchronization
- Scene backup/restore
- Scene sharing

### Security
- Authentication
- Encryption
- Key management
- Secure storage
- Certificate pinning
- Security policy enforcement

### Core Services
- Service registration
- Dependency injection
- Service lifecycle
- Service discovery
- Inter-service communication

### State Management
- Application state
- State persistence
- State synchronization
- State restoration
- Change notification

### Storage
- Data persistence
- Caching
- File management
- Database operations
- Migration handling

### Common Types
- Data models
- Protocols
- Enumerations
- Type extensions
- Utility types

## Usage

### Service Registration
```swift
// Register core services
CoreServiceRegistry.shared.register {
    DeviceService()
    EffectService()
    SceneService()
    // Additional services...
}
```

### Device Discovery
```swift
let deviceManager = CoreServiceRegistry.shared.resolve(DeviceManaging.self)
let devices = try await deviceManager.discoverDevices()
```

### Effect Creation
```swift
let effectManager = CoreServiceRegistry.shared.resolve(EffectManaging.self)
let effect = try effectManager.createEffect(parameters: .init(
    name: "Sunset",
    duration: .minutes(30),
    transitions: [
        .color(from: .white, to: .orange),
        .brightness(from: 1.0, to: 0.3)
    ]
))
```

### Scene Management
```swift
let sceneManager = CoreServiceRegistry.shared.resolve(SceneManaging.self)
let scene = try await sceneManager.createScene(
    name: "Movie Night",
    devices: movieRoomDevices,
    schedule: .evening
)
```

## Best Practices

### Error Handling
```swift
do {
    try await deviceManager.connect(to: deviceId)
} catch DeviceError.connectionFailed(let reason) {
    logger.error("Connection failed: \(reason)")
    // Implement recovery strategy
} catch DeviceError.timeout {
    // Handle timeout specifically
}
```

### State Management
```swift
// Subscribe to state changes
stateManager.observe(\.deviceState) { state in
    // Update UI or trigger side effects
}

// Update state
await stateManager.update { state in
    state.deviceState.power = .on
    state.deviceState.brightness = 0.8
}
```

### Background Tasks
```swift
backgroundManager.schedule(
    task: DeviceUpdateTask(),
    frequency: .hourly,
    requirements: [
        .network,
        .charging
    ]
)
```

## Dependencies
- Foundation
- Combine
- CoreLocation
- Network
- Security

## Thread Safety
The Core module is designed with thread safety in mind:
- All public APIs are thread-safe
- State modifications are synchronized
- Background operations are properly queued
- Resource access is coordinated

## Testing
Each component includes:
- Unit tests
- Integration tests
- Performance tests
- Mock implementations
- Test utilities

## Documentation
Additional documentation:
- [API Reference](../../docs/API.md)
- [Architecture Guide](../../docs/architecture.md)
- [Migration Guide](../../docs/migration.md)
- [Security Guide](../../docs/security.md)
