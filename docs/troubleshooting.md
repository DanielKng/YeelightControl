# Troubleshooting Guide

## Common Issues

### Device Discovery

#### No Devices Found
```swift
// Problem
let devices = try await deviceManager.discoverDevices()
// Returns empty array

// Solution
// 1. Check network connectivity
let config = DiscoveryConfiguration(
    searchTimeout: 10.0,  // Increase timeout
    retryCount: 3        // Add retries
)
let devices = try await deviceManager.discoverDevices(config)

// 2. Verify device is in LAN mode
// 3. Check network permissions
```

#### Connection Failures
```swift
// Problem
try await deviceManager.connect(to: deviceId)
// Throws DeviceError.connectionFailed

// Solution
let options = ConnectionOptions(
    timeout: 30.0,
    retryPolicy: .exponentialBackoff(
        maxAttempts: 3,
        initialDelay: 1.0
    )
)
try await deviceManager.connect(to: deviceId, options: options)
```

### Device Control

#### Command Timeout
```swift
// Problem
try await deviceManager.setPower(true, for: deviceId)
// Throws DeviceError.timeout

// Solution
// 1. Check device connectivity
let state = try await deviceManager.getState(for: deviceId)

// 2. Implement retry logic
try await withRetry(maxAttempts: 3) {
    try await deviceManager.setPower(true, for: deviceId)
}
```

#### State Synchronization
```swift
// Problem
// Device state doesn't match commands

// Solution
// 1. Force state refresh
try await deviceManager.refreshState(for: deviceId)

// 2. Subscribe to state changes
deviceManager.observeState(for: deviceId) { state in
    // Handle state updates
}
```

### Effect System

#### Effect Application Failures
```swift
// Problem
try await effectManager.apply(effect, to: devices)
// Throws EffectError.executionFailed

// Solution
// 1. Verify device compatibility
let capabilities = try await deviceManager.getCapabilities(
    for: deviceId
)
guard capabilities.supportsEffect(effect.type) else {
    // Handle unsupported effect
    return
}

// 2. Check effect parameters
try effectManager.validateEffect(effect)
```

#### Performance Issues
```swift
// Problem
// Effect execution is sluggish

// Solution
// 1. Optimize effect parameters
let optimizedEffect = try effectManager.optimize(effect)

// 2. Batch commands
try await effectManager.applyBatched(
    effect,
    to: devices,
    batchSize: 5
)
```

### Scene Management

#### Scene Activation Failures
```swift
// Problem
try await sceneManager.activateScene(scene)
// Throws SceneError.activationFailed

// Solution
// 1. Verify device availability
let unavailableDevices = try await sceneManager
    .checkDeviceAvailability(for: scene)

// 2. Implement partial activation
try await sceneManager.activateScene(
    scene,
    options: .allowPartial
)
```

#### Scene Conflicts
```swift
// Problem
// Multiple scenes trying to control same device

// Solution
// 1. Implement priority system
scene.priority = .high

// 2. Use scene groups
try await sceneManager.createGroup(
    name: "Evening",
    scenes: [scene1, scene2],
    resolution: .priority
)
```

## Debugging

### Logging
```swift
// Enable debug logging
Logger.shared.setLevel(.debug)

// Add custom logging
Logger.shared.addHandler { event in
    // Process log event
}
```

### Network Diagnostics
```swift
// Monitor network traffic
NetworkMonitor.shared.start { event in
    // Track network events
}

// Test device connectivity
let diagnostic = try await deviceManager
    .runDiagnostic(for: deviceId)
```

### State Inspection
```swift
// Dump device state
let state = try await deviceManager.getState(for: deviceId)
print("Device state: \(String(describing: state))")

// Monitor state changes
deviceManager.observeState(for: deviceId) { state in
    print("State changed: \(state)")
}
```

## Best Practices

### Error Handling
1. Implement proper error handling
2. Use appropriate error types
3. Provide meaningful error messages
4. Log errors for debugging
5. Implement recovery strategies

### Performance
1. Batch operations when possible
2. Implement proper timeouts
3. Use appropriate retry policies
4. Monitor resource usage
5. Optimize network calls

### Maintenance
1. Regular state synchronization
2. Clean up resources
3. Monitor device health
4. Update firmware when needed
5. Maintain logs

## Support Resources
- [API Reference](api-reference.md)
- [Security Guide](security.md)
- [Migration Guide](migration-guide.md)
- [GitHub Issues](https://github.com/DanielKng/YeelightControl/issues) 