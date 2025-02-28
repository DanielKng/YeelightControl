# Widget Module

## Overview
The Widget module provides home screen widgets for YeelightControl, offering quick access to device control and status information. Built using WidgetKit, it supports various widget sizes and configurations.

## Architecture

### Directory Structure
```
Widget/
├── WidgetBundle.swift       - Widget bundle configuration
├── YeelightWidget.swift     - Main widget implementation
└── DeviceControlWidget.swift - Device control widget
```

## Components

### Widget Bundle
```swift
/// Main widget bundle configuration
@main
struct YeelightWidgetBundle: WidgetBundle {
    /// Available widgets
    var body: some Widget {
        DeviceControlWidget()
        StatusWidget()
        SceneWidget()
    }
}
```

### Device Control Widget

#### Configuration
```swift
struct DeviceControlWidgetConfiguration: WidgetConfiguration {
    /// Widget family support
    supportedFamilies: [.systemSmall, .systemMedium]
    
    /// Content configuration
    content: DeviceControlProvider()
    
    /// Deep link support
    deepLink: URL(string: "yeelightcontrol://widget/device")
    
    /// Description for widget gallery
    description: "Quick access to device controls"
}
```

#### Timeline Provider
```swift
struct DeviceControlProvider: TimelineProvider {
    /// Placeholder for widget gallery
    func placeholder(context: Context) -> DeviceControlEntry {
        DeviceControlEntry(
            date: Date(),
            device: .placeholder,
            state: .default
        )
    }
    
    /// Snapshot for widget gallery
    func snapshot(context: Context) async -> DeviceControlEntry {
        let devices = try? await DeviceManager.shared.getDevices()
        return DeviceControlEntry(
            date: Date(),
            device: devices?.first ?? .placeholder,
            state: .default
        )
    }
    
    /// Timeline for widget updates
    func timeline(context: Context) async -> Timeline<DeviceControlEntry> {
        let devices = try? await DeviceManager.shared.getDevices()
        let entries = devices?.map { device in
            DeviceControlEntry(
                date: Date(),
                device: device,
                state: device.state
            )
        } ?? []
        
        return Timeline(
            entries: entries,
            policy: .atEnd
        )
    }
}
```

#### Widget View
```swift
struct DeviceControlWidgetView: View {
    /// Widget environment
    @Environment(\.widgetFamily) var family
    
    /// Widget entry
    let entry: DeviceControlEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallDeviceControl(entry: entry)
        case .systemMedium:
            MediumDeviceControl(entry: entry)
        default:
            EmptyView()
        }
    }
}
```

### Status Widget

#### Configuration
```swift
struct StatusWidgetConfiguration: WidgetConfiguration {
    /// Widget family support
    supportedFamilies: [.systemSmall]
    
    /// Content configuration
    content: StatusProvider()
    
    /// Deep link support
    deepLink: URL(string: "yeelightcontrol://widget/status")
    
    /// Description for widget gallery
    description: "Device status at a glance"
}
```

#### Timeline Provider
```swift
struct StatusProvider: TimelineProvider {
    /// Update interval
    static let updateInterval: TimeInterval = 300 // 5 minutes
    
    /// Timeline generation
    func timeline(context: Context) async -> Timeline<StatusEntry> {
        let now = Date()
        let nextUpdate = now.addingTimeInterval(Self.updateInterval)
        
        let status = try? await DeviceManager.shared.getSystemStatus()
        let entry = StatusEntry(
            date: now,
            deviceCount: status?.deviceCount ?? 0,
            activeDevices: status?.activeDevices ?? 0,
            currentScene: status?.currentScene
        )
        
        return Timeline(
            entries: [entry],
            policy: .after(nextUpdate)
        )
    }
}
```

## Features

### Device Control
- Power toggle
- Brightness adjustment
- Color selection
- Scene activation
- Status display

### Status Display
- Connected devices
- Active devices
- Current scene
- System status

### Widget Sizes
- Small (single device)
- Medium (multiple devices)
- Large (device grid)

### Interactions
- Tap actions
- Long press menu
- Deep linking
- Quick actions

## Implementation

### State Management
```swift
/// Widget state management
struct WidgetState {
    /// Device state
    var deviceState: DeviceState
    
    /// Update interval
    var updateInterval: TimeInterval
    
    /// Refresh policy
    var refreshPolicy: TimelineReloadPolicy
    
    /// State persistence
    func persist() {
        UserDefaults.suite.set(
            try? JSONEncoder().encode(self),
            forKey: "WidgetState"
        )
    }
}
```

### Network Communication
```swift
/// Widget network manager
struct WidgetNetworkManager {
    /// Fetch device state
    func fetchDeviceState(
        deviceId: String
    ) async throws -> DeviceState {
        let request = URLRequest(
            url: URL(string: "api/device/\(deviceId)/state")!
        )
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(DeviceState.self, from: data)
    }
}
```

### Deep Linking
```swift
/// Widget deep link handling
struct WidgetDeepLink {
    /// Handle widget tap
    static func handleTap(
        _ url: URL,
        context: Context
    ) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else { return }
        
        switch components.path {
        case "/device":
            openDeviceControl(components.queryItems)
        case "/scene":
            activateScene(components.queryItems)
        default:
            break
        }
    }
}
```

## Best Practices

### Performance
- Minimize network requests
- Cache widget data
- Optimize rendering
- Handle background updates

### User Experience
- Provide clear feedback
- Support accessibility
- Handle errors gracefully
- Maintain consistency

### Data Management
- Implement caching
- Handle offline state
- Sync with main app
- Manage updates

### Widget Design
- Follow system guidelines
- Support dark mode
- Handle all sizes
- Provide placeholders

## Testing

### Unit Tests
- Timeline provider
- Data fetching
- State management
- Error handling

### Integration Tests
- Widget rendering
- Deep linking
- Data synchronization
- Background updates

### UI Tests
- Widget appearance
- Interaction handling
- Size adaptation
- Theme switching

## Dependencies
- WidgetKit
- SwiftUI
- Core module
- Network layer

## Documentation
- [Widget Guide](../../docs/widgets.md)
- [Integration Guide](../../docs/widget-integration.md)
- [Design Guidelines](../../docs/widget-design.md)
- [Testing Guide](../../docs/widget-testing.md)
