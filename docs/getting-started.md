# Getting Started with YeelightControl

## Overview
This guide will help you get started with the YeelightControl API for managing Yeelight smart lighting devices.

## Prerequisites
- macOS/iOS development environment
- Xcode 15.0 or later
- Swift 5.9 or later
- Network access to Yeelight devices

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

## Quick Start

### 1. Initialize Device Manager
```swift
let deviceManager = try DeviceManager()
```

### 2. Discover Devices
```swift
let devices = try await deviceManager.discoverDevices()
```

### 3. Connect to Device
```swift
try await deviceManager.connect(to: deviceId)
```

### 4. Control Device
```swift
// Turn on
try await deviceManager.setPower(true, for: deviceId)

// Set brightness
try await deviceManager.setBrightness(0.75, for: deviceId)

// Set color
try await deviceManager.setColor(.blue, for: deviceId)
```

## Basic Concepts

### Device Management
- Device discovery
- Connection handling
- State management
- Command execution

### Effects
- Color transitions
- Brightness changes
- Custom effects
- Effect scheduling

### Scenes
- Scene creation
- Device grouping
- Scene activation
- Scene scheduling

### Error Handling
- Error types
- Recovery strategies
- Best practices
- Debugging

## Next Steps
- Explore the [API Reference](api-reference.md)
- Check out the [Examples](../examples)
- Read the [Security Guide](security.md)
- Review [Best Practices](../Sources/Core/README.md#best-practices) 