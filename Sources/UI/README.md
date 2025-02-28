# UI Module

The UI module contains all user interface components for the YeelightControl app. Built with SwiftUI, it follows modern iOS design patterns and provides a beautiful, intuitive user experience.

## Directory Structure

### Components
- `Components/` - Reusable UI components
  - Common controls (buttons, sliders, pickers)
  - Custom views (color wheels, device cards)
  - Animations and transitions
  - Loading states and indicators

### Views
- `Views/` - Feature-specific views
  - Device control interfaces
  - Scene management screens
  - Effect configuration views
  - Settings and preferences
  - Network diagnostics

## Design System

### Colors and Typography
- Consistent color palette
- Dynamic type support
- Dark mode compatibility
- Accessibility considerations

### Layout Guidelines
- Responsive design principles
- Safe area awareness
- Device adaptation (iPhone, iPad)
- Orientation handling

### Component Guidelines
1. **Reusability**: Components should be modular and reusable
2. **Customization**: Support appearance customization through parameters
3. **Accessibility**: VoiceOver support and dynamic type
4. **Performance**: Efficient rendering and memory usage

## Usage Example

```swift
import UI

// Using a custom color picker
struct DeviceControlView: View {
    @State private var selectedColor: Color = .white
    
    var body: some View {
        VStack {
            ColorWheelPicker(color: $selectedColor)
            DeviceControlPanel(device: device, color: selectedColor)
            EffectControls(device: device)
        }
    }
}

// Custom button styles
struct ActionButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}
```

## Animation System

The UI module includes a comprehensive animation system:
- Smooth transitions between states
- Custom effect animations
- Loading indicators
- Feedback animations

## Testing

UI components can be tested using:
- SwiftUI Previews
- XCTest UI tests
- Snapshot tests

Run UI-specific tests:
```bash
swift test --filter "UITests"
```

## Best Practices

1. **State Management**
   - Use appropriate property wrappers (@State, @Binding, @ObservedObject)
   - Keep state at appropriate levels
   - Handle loading and error states

2. **Performance**
   - Minimize view updates
   - Use lazy loading where appropriate
   - Optimize drawing and layout passes

3. **Accessibility**
   - Provide meaningful labels
   - Support VoiceOver
   - Handle dynamic type
   - Consider color contrast

4. **Documentation**
   - Document complex components
   - Provide usage examples
   - Include preview providers
