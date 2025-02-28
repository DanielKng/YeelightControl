# UI Module

## Overview
The UI module provides a comprehensive set of SwiftUI views and components for the YeelightControl application. It implements a modern, responsive, and accessible user interface following Apple's Human Interface Guidelines.

## Architecture

### Directory Structure
```
UI/
├── Components/    - Reusable UI components
└── Views/        - Feature-specific views
```

## Components

### Core Components

#### ColorPicker
```swift
struct ColorPicker: View {
    /// Binding to selected color
    @Binding var selectedColor: Color
    
    /// Color selection callback
    var onColorSelected: (Color) -> Void
    
    /// Color history
    @State private var recentColors: [Color]
}
```
- Color wheel with brightness slider
- Recent colors history
- RGB/HSB value inputs
- Color preset selection
- Supports haptic feedback

#### BrightnessSlider
```swift
struct BrightnessSlider: View {
    /// Current brightness value (0.0-1.0)
    @Binding var brightness: Double
    
    /// Value change callback
    var onValueChanged: (Double) -> Void
    
    /// Haptic feedback style
    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
}
```
- Smooth value transitions
- Custom track appearance
- Live preview
- Accessibility support
- Haptic feedback

#### DeviceCard
```swift
struct DeviceCard: View {
    /// Device to display
    let device: Device
    
    /// Card selection handler
    var onSelect: (Device) -> Void
    
    /// Long press handler
    var onLongPress: (Device) -> Void
}
```
- Device status indicator
- Quick actions menu
- Power toggle
- Brightness control
- Color preview

#### SceneButton
```swift
struct SceneButton: View {
    /// Scene to represent
    let scene: Scene
    
    /// Activation handler
    var onActivate: (Scene) -> Void
    
    /// Edit mode handler
    var onEdit: (Scene) -> Void
}
```
- Scene preview
- Activation status
- Edit controls
- Schedule indicator
- Device count badge

### Feature Views

#### DeviceListView
```swift
struct DeviceListView: View {
    /// Available devices
    @StateObject var viewModel: DeviceListViewModel
    
    /// Filter options
    @State private var filterOptions: FilterOptions
    
    /// Sort criteria
    @State private var sortCriteria: SortCriteria
}
```
- Grid/list layout
- Search functionality
- Filtering options
- Sorting capabilities
- Pull to refresh

#### SceneEditorView
```swift
struct SceneEditorView: View {
    /// Scene being edited
    @StateObject var viewModel: SceneEditorViewModel
    
    /// Available devices
    let availableDevices: [Device]
    
    /// Scheduling options
    @State private var schedule: Schedule?
}
```
- Device selection
- Color/brightness settings
- Schedule configuration
- Preview capability
- Save/cancel actions

#### EffectCreatorView
```swift
struct EffectCreatorView: View {
    /// Effect configuration
    @StateObject var viewModel: EffectCreatorViewModel
    
    /// Selected devices
    @State private var selectedDevices: Set<Device>
    
    /// Effect parameters
    @State private var parameters: EffectParameters
}
```
- Effect type selection
- Parameter configuration
- Timeline editor
- Live preview
- Device selection

## Design System

### Colors
```swift
enum BrandColors {
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let accent = Color("Accent")
    static let background = Color("Background")
    static let surface = Color("Surface")
}
```

### Typography
```swift
enum Typography {
    static let title = Font.system(.title, design: .rounded)
    static let heading = Font.system(.headline, design: .rounded)
    static let body = Font.system(.body, design: .default)
    static let caption = Font.system(.caption, design: .default)
}
```

### Spacing
```swift
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

## Animations

### Transitions
```swift
extension AnyTransition {
    static let deviceCard = AnyTransition.asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .scale.combined(with: .opacity)
    )
}
```

### Animations
```swift
extension Animation {
    static let deviceStateChange = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0.1
    )
}
```

## Accessibility

### VoiceOver Support
- Meaningful labels
- Action descriptions
- Value adjustments
- Custom rotor actions
- Dynamic type support

### Color Accessibility
- High contrast support
- Color blindness considerations
- Dark mode adaptation
- Dynamic color system

## Best Practices

### View Organization
```swift
struct ContentView: View {
    // MARK: - Properties
    
    // MARK: - State
    
    // MARK: - Computed Properties
    
    // MARK: - View Body
    
    // MARK: - Helper Views
    
    // MARK: - Actions
}
```

### State Management
```swift
final class ViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // MARK: - Private Properties
    
    // MARK: - Initialization
    
    // MARK: - Public Methods
    
    // MARK: - Private Methods
}
```

### Performance
- View composition
- State management
- Memory usage
- Animation performance
- Layout optimization

## Testing

### Unit Tests
- View model tests
- State management
- Action handlers
- Data flow
- Error handling

### UI Tests
- View hierarchy
- User interactions
- Accessibility
- Dark mode
- Dynamic type

### Snapshot Tests
- Component appearance
- Layout consistency
- Theme variations
- State variations
- Platform compatibility

## Dependencies
- SwiftUI
- Combine
- Core module
- Features module

## Documentation
- [UI Guidelines](../../docs/ui-guidelines.md)
- [Component Catalog](../../docs/components.md)
- [Accessibility Guide](../../docs/accessibility.md)
- [Theme Documentation](../../docs/theming.md)
