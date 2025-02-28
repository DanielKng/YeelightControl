# Features Module

The Features module contains high-level application features that build upon the Core module's functionality. Each feature is designed to be self-contained while integrating seamlessly with the rest of the application.

## Feature Components

### Scenes Management
- `Scenes/` - Lighting scene configuration and management
  - `SceneManager.swift` - Scene creation, editing, and activation
  - Supports saving, loading, and sharing of lighting scenes
  - Handles scene transitions and timing

### Effects System
- `Effects/` - Dynamic lighting effects
  - `EffectManager.swift` - Effect creation and control
  - Predefined and custom effect patterns
  - Music synchronization effects
  - Color flow animations

### Room Organization
- `Rooms/` - Room-based device grouping
  - Room creation and management
  - Device assignment to rooms
  - Group control operations
  - Room-specific scenes and effects

### Automation
- `Automation/` - Smart automation features
  - Time-based triggers
  - Location-based actions
  - Condition-based rules
  - Schedule management

## Integration Guidelines

1. **Feature Independence**: Each feature should work independently
2. **Core Integration**: Features should use Core module services through the ServiceContainer
3. **State Management**: Use UnifiedStateManager for feature state
4. **Error Handling**: Implement comprehensive error handling using Core error types

## Usage Example

```swift
import Features

// Scene Management
let sceneManager = SceneManager.shared
let newScene = Scene(name: "Movie Night", devices: roomDevices)
try await sceneManager.saveScene(newScene)

// Effect Control
let effectManager = EffectManager.shared
let colorFlow = ColorFlowEffect(colors: [.red, .blue], duration: 5.0)
try await effectManager.applyEffect(colorFlow, to: selectedDevices)
```

## Feature Development

When developing new features:

1. Create a new directory in the Features module
2. Implement the feature manager following the unified pattern
3. Add necessary UI components in the UI module
4. Write comprehensive tests in the Tests module
5. Document usage and integration guidelines

## Testing

Each feature has its own test suite. Run feature-specific tests:

```bash
swift test --filter "FeaturesTests"
```
