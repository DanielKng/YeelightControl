# Getting Started with YeelightControl

## Quick Links
- 📚 [API Reference](../reference/api-reference.md)
- 🔧 [Troubleshooting](troubleshooting.md)
- 📝 [Example Code](../examples/basic-control/README.md)

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Next Steps](#next-steps)

## Prerequisites

### Development Environment
- macOS/iOS development environment
- Xcode 15.0 or later
- Swift 5.9 or later
- Network access to Yeelight devices

### Required Frameworks
- SwiftUI
- Combine
- Network.framework

> 🔧 Having trouble? Check the [Network Issues](troubleshooting.md#network-issues) section.

## Installation

### Swift Package Manager
Add YeelightControl to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/DanielKng/YeelightControl.git", from: "1.0.0")
]
```

### Manual Integration
1. Clone the repository
2. Add the Sources directory to your project
3. Link against the necessary frameworks

> 📘 For more details about the project structure, see the [Core Module Documentation](../../Sources/Core/README.md).

## Quick Start

### 1. Initialize Device Manager
```swift
import YeelightControl

// Initialize device manager
let deviceManager = try DeviceManager()
```

> 🔍 See [Device Management API](../reference/api-reference.md#device-management) for more details.

### 2. Discover Devices
```swift
// Discover devices on the network
let devices = try await deviceManager.discoverDevices()

// Print found devices
for device in devices {
    print("Found device: \(device.name) (\(device.id))")
}
```

> 🔧 If no devices are found, check the [Device Discovery Troubleshooting](troubleshooting.md#device-discovery).

### 3. Connect to Device
```swift
// Connect to a specific device
let deviceId = devices.first?.id ?? ""
try await deviceManager.connect(to: deviceId)

// Get device state
let state = try await deviceManager.getState(for: deviceId)
print("Device state: \(state)")
```

> 🔒 For secure connection handling, see the [Security Guide](security.md#device-authentication).

### 4. Control Device
```swift
// Turn on
try await deviceManager.setPower(true, for: deviceId)

// Set brightness to 50%
try await deviceManager.setBrightness(0.5, for: deviceId)

// Set color to blue
try await deviceManager.setColor(.blue, for: deviceId)
```

> 📘 For more control options, see the [Basic Control Example](../examples/basic-control/README.md).

### Error Handling
```swift
do {
    try await deviceManager.connect(to: deviceId)
} catch DeviceError.deviceNotFound {
    print("Device not found")
} catch DeviceError.connectionFailed(let reason) {
    print("Connection failed: \(reason)")
} catch {
    print("Unknown error: \(error)")
}
```

> 🔧 For comprehensive error handling, see the [Error Handling Guide](../examples/error-handling/README.md).

## Next Steps

### Explore Advanced Features
- [Create Lighting Effects](../examples/effects/README.md)
- [Manage Scenes](../examples/scenes/README.md)
- [Implement Security](../examples/security/README.md)
- [Add Widgets](../../Sources/Widget/README.md)

### Learn Best Practices
- [Device Control Best Practices](../reference/api-reference.md#device-control)
- [Error Handling Best Practices](../reference/api-reference.md#error-handling)
- [Security Best Practices](security.md#best-practices)

### Get Help
- Check the [Troubleshooting Guide](troubleshooting.md)
- Review [Common Issues](troubleshooting.md#common-issues)
- Report issues on [GitHub](https://github.com/DanielKng/YeelightControl/issues) 