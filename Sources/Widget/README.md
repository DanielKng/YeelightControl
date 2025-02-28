# Widget Module

The Widget module provides iOS home screen and lock screen widgets for quick access to YeelightControl functionality. Built using WidgetKit and SwiftUI, it offers various widget sizes and configurations for optimal user experience.

## Components

### Device Control Widget
- `DeviceControlWidget.swift` - Main device control widget
  - Quick toggle controls
  - Brightness adjustment
  - Color selection
  - Scene activation
  - Supports multiple sizes
  - Lock screen compatibility

### Yeelight Widget
- `YeelightWidget.swift` - Status and information widget
  - Device status display
  - Power consumption
  - Current scene info
  - Connection status
  - Quick actions

### Widget Bundle
- `WidgetBundle.swift` - Widget configuration
  - Widget registration
  - Shared resources
  - Configuration handling

## Widget Sizes

### Small Widget (2x2)
- Single device control
- Basic toggle and brightness
- Current status display

### Medium Widget (4x2)
- Multiple device controls
- Scene activation
- Color selection
- Status information

### Large Widget (4x4)
- Room overview
- Multiple device controls
- Scene management
- Detailed status

## Features

1. **Real-time Updates**
   - Live device status
   - Background refresh
   - Timeline updates

2. **Deep Linking**
   - Quick app access
   - Feature-specific navigation
   - Context preservation

3. **Customization**
   - Device selection
   - Control layout
   - Color schemes
   - Action configuration

## Implementation

```swift
struct DeviceControlWidget: Widget {
    private let kind: String = "DeviceControlWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DeviceControlProvider()
        ) { entry in
            DeviceControlWidgetView(entry: entry)
        }
        .configurationDisplayName("Device Control")
        .description("Quick access to device controls")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

## Widget Development

1. **Timeline Provider**
   - Implement data refresh
   - Handle background updates
   - Manage entry lifecycle

2. **Widget View**
   - Create responsive layouts
   - Handle user interactions
   - Support dynamic type
   - Dark mode compatibility

3. **Configuration**
   - Intent configuration
   - User preferences
   - Default settings

## Best Practices

1. **Performance**
   - Minimize network calls
   - Optimize rendering
   - Cache data appropriately
   - Handle timeouts

2. **Battery Efficiency**
   - Smart refresh intervals
   - Efficient data storage
   - Background task optimization

3. **Error Handling**
   - Graceful fallbacks
   - Error states
   - Network issues
   - Timeout handling

4. **Testing**
   - Widget preview testing
   - Timeline testing
   - Configuration testing
   - Performance testing

## Usage Example

```swift
// Adding a new widget
import WidgetKit
import SwiftUI

struct CustomWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "CustomWidget",
            provider: CustomWidgetProvider()
        ) { entry in
            CustomWidgetView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Custom Widget")
        .description("Widget description")
    }
}

// Register in WidgetBundle
@main
struct YeelightWidgets: WidgetBundle {
    var body: some Widget {
        DeviceControlWidget()
        YeelightWidget()
        CustomWidget()
    }
}
```
