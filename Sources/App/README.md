# App Module

The App module serves as the main entry point for the YeelightControl application. It coordinates the initialization of all other modules and manages the app's lifecycle.

## Components

### Application Entry
- `YeelightControlApp.swift` - Main app entry point
  - App lifecycle management
  - Module initialization
  - Dependency injection setup
  - Environment configuration
  - Scene management

### Main Interface
- `ContentView.swift` - Root view of the application
  - Navigation structure
  - Tab organization
  - Main layout
  - State coordination

## Application Structure

### Initialization Flow
1. App launch
2. Service container setup
3. Core services initialization
4. Feature managers setup
5. UI preparation
6. Widget integration

### Navigation Architecture
- Tab-based navigation
- Feature-specific flows
- Modal presentations
- Deep linking support

## Integration Points

### Core Module Integration
```swift
import Core

@main
struct YeelightControlApp: App {
    // Initialize core services
    let serviceContainer = ServiceContainer.shared
    
    init() {
        // Configure core services
        serviceContainer.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer)
        }
    }
}
```

### Features Integration
```swift
import Features

struct ContentView: View {
    @EnvironmentObject var serviceContainer: ServiceContainer
    
    var body: some View {
        TabView {
            DevicesView()
                .tabItem { Label("Devices", systemImage: "lightbulb") }
            
            ScenesView()
                .tabItem { Label("Scenes", systemImage: "theatermasks") }
            
            AutomationView()
                .tabItem { Label("Automation", systemImage: "clock") }
            
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
```

## State Management

### App State
- Global app state
- User preferences
- Authentication state
- Network status

### Environment Objects
- Service container
- Feature managers
- UI state
- User settings

## Deep Linking

### URL Scheme
- yeelight://devices/{id}
- yeelight://scenes/{id}
- yeelight://automation/{id}
- yeelight://settings

### Universal Links
- Support for web links
- Shortcut integration
- Widget deep links

## Background Tasks

### Background Modes
- Network access
- Location updates
- State refresh
- Notifications

### Background Tasks
- Device status updates
- Scene scheduling
- Automation triggers
- Data synchronization

## Best Practices

1. **Initialization**
   - Lazy loading when possible
   - Asynchronous setup
   - Error handling
   - Recovery procedures

2. **State Management**
   - Single source of truth
   - State isolation
   - Predictable updates
   - Performance optimization

3. **Navigation**
   - Consistent patterns
   - State preservation
   - History management
   - Error recovery

4. **Memory Management**
   - Resource cleanup
   - Cache management
   - Memory warnings
   - State restoration

## Testing

### Launch Testing
```swift
final class AppLaunchTests: XCTestCase {
    func testAppInitialization() {
        let app = YeelightControlApp()
        XCTAssertNotNil(app.serviceContainer)
        // Additional initialization tests
    }
}
```

### Integration Testing
```swift
final class AppIntegrationTests: XCTestCase {
    func testCoreIntegration() {
        // Test core service availability
    }
    
    func testFeatureIntegration() {
        // Test feature manager setup
    }
}
```
