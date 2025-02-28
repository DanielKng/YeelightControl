# Basic Device Control Example

This example demonstrates basic device control operations using the YeelightControl API.

## Features
- Device discovery
- Connection management
- Power control
- Brightness adjustment
- Color setting

## Implementation

### Device Discovery
```swift
import YeelightControl

// Initialize device manager
let deviceManager = try DeviceManager()

// Discover devices
let devices = try await deviceManager.discoverDevices()

// Print found devices
for device in devices {
    print("Found device: \(device.name) (\(device.id))")
}
```

### Device Connection
```swift
// Connect to specific device
let deviceId = devices.first?.id ?? ""
try await deviceManager.connect(to: deviceId)

// Get device state
let state = try await deviceManager.getState(for: deviceId)
print("Device state: \(state)")
```

### Basic Control
```swift
// Turn device on
try await deviceManager.setPower(true, for: deviceId)

// Set brightness to 50%
try await deviceManager.setBrightness(0.5, for: deviceId)

// Set color to blue
try await deviceManager.setColor(.blue, for: deviceId)
```

### State Observation
```swift
// Observe state changes
deviceManager.observeState(for: deviceId) { state in
    print("State changed: \(state)")
}
```

### Error Handling
```swift
do {
    try await deviceManager.setPower(true, for: deviceId)
} catch DeviceError.deviceNotFound {
    print("Device not found")
} catch DeviceError.connectionFailed(let reason) {
    print("Connection failed: \(reason)")
} catch {
    print("Unknown error: \(error)")
}
```

## Usage
1. Copy the example code
2. Add necessary imports
3. Initialize device manager
4. Run the example
5. Observe device control

## Notes
- Ensure devices are on same network
- Enable LAN Control in Yeelight app
- Handle errors appropriately
- Implement proper cleanup 