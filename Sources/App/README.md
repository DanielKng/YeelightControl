# App Module

## Overview
The App module serves as the main entry point and coordinator for the YeelightControl application. It manages the application lifecycle, coordinates between modules, and handles high-level navigation and state management.

## Architecture

### Directory Structure
```
App/
├── YeelightControlApp.swift - Main application entry
└── ContentView.swift       - Root view coordination
```

## Components

### Application Entry

#### YeelightControlApp
```swift
@main
struct YeelightControlApp: App {
    /// Application state
    @StateObject private var appState = AppState()
    
    /// Scene phase monitoring
    @Environment(\.scenePhase) private var scenePhase
    
    /// Application configuration
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    await setupApplication()
                }
        }
        .onChange(of: scenePhase) { phase in
            handleScenePhase(phase)
        }
    }
    
    /// Application setup
    private func setupApplication() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await setupCore() }
            group.addTask { await setupFeatures() }
            group.addTask { await setupUI() }
            group.addTask { await setupWidget() }
        }
    }
}
```

### Root Coordination

#### ContentView
```swift
struct ContentView: View {
    /// Application state
    @EnvironmentObject var appState: AppState
    
    /// Navigation path
    @State private var navigationPath = NavigationPath()
    
    /// Tab selection
    @State private var selectedTab: Tab = .devices
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            TabView(selection: $selectedTab) {
                DevicesTab()
                    .tabItem { Label("Devices", systemImage: "lightbulb") }
                    .tag(Tab.devices)
                
                ScenesTab()
                    .tabItem { Label("Scenes", systemImage: "theatermasks") }
                    .tag(Tab.scenes)
                
                AutomationTab()
                    .tabItem { Label("Automation", systemImage: "wand.and.stars") }
                    .tag(Tab.automation)
                
                SettingsTab()
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .tag(Tab.settings)
            }
        }
    }
}
```

## State Management

### Application State
```swift
final class AppState: ObservableObject {
    /// Published properties
    @Published var isInitialized: Bool = false
    @Published var currentUser: User?
    @Published var systemStatus: SystemStatus = .default
    @Published var activeScene: Scene?
    
    /// State restoration
    func restoreState() async {
        guard let data = UserDefaults.standard.data(forKey: "AppState")
        else { return }
        
        let state = try? JSONDecoder().decode(StoredState.self, from: data)
        await MainActor.run {
            self.currentUser = state?.user
            self.systemStatus = state?.status ?? .default
            self.activeScene = state?.scene
        }
    }
    
    /// State persistence
    func persistState() {
        let state = StoredState(
            user: currentUser,
            status: systemStatus,
            scene: activeScene
        )
        
        UserDefaults.standard.set(
            try? JSONEncoder().encode(state),
            forKey: "AppState"
        )
    }
}
```

## Navigation

### Deep Linking
```swift
struct DeepLinkHandler {
    /// Handle incoming URLs
    static func handle(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else { return }
        
        switch components.path {
        case "/device":
            navigateToDevice(components.queryItems)
        case "/scene":
            navigateToScene(components.queryItems)
        case "/automation":
            navigateToAutomation(components.queryItems)
        default:
            break
        }
    }
}
```

### Navigation Coordination
```swift
struct NavigationCoordinator {
    /// Navigation state
    @Binding var path: NavigationPath
    
    /// Navigate to device
    func navigateToDevice(_ device: Device) {
        path.append(Route.device(device))
    }
    
    /// Navigate to scene
    func navigateToScene(_ scene: Scene) {
        path.append(Route.scene(scene))
    }
    
    /// Navigate to automation
    func navigateToAutomation(_ automation: Automation) {
        path.append(Route.automation(automation))
    }
}
```

## Module Coordination

### Core Integration
```swift
struct CoreCoordinator {
    /// Initialize core services
    func initialize() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await initializeDeviceManager() }
            group.addTask { try await initializeSceneManager() }
            group.addTask { try await initializeEffectManager() }
        }
    }
    
    /// Handle core events
    func handleCoreEvent(_ event: CoreEvent) {
        switch event {
        case .deviceStateChanged(let device):
            updateDeviceState(device)
        case .sceneActivated(let scene):
            updateActiveScene(scene)
        case .error(let error):
            handleCoreError(error)
        }
    }
}
```

### Feature Integration
```swift
struct FeatureCoordinator {
    /// Initialize features
    func initialize() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await initializeAutomation() }
            group.addTask { try await initializeRooms() }
        }
    }
    
    /// Handle feature events
    func handleFeatureEvent(_ event: FeatureEvent) {
        switch event {
        case .automationTriggered(let automation):
            executeAutomation(automation)
        case .roomStateChanged(let room):
            updateRoomState(room)
        case .error(let error):
            handleFeatureError(error)
        }
    }
}
```

## Best Practices

### Application Lifecycle
- Handle state restoration
- Manage background tasks
- Monitor memory usage
- Handle system events

### Module Communication
- Use clear interfaces
- Maintain loose coupling
- Handle errors gracefully
- Ensure thread safety

### State Management
- Centralize state
- Use appropriate scopes
- Handle conflicts
- Maintain consistency

### Performance
- Optimize startup time
- Manage resources
- Monitor metrics
- Handle low memory

## Dependencies
- Core module
- Features module
- UI module
- Widget module

## Testing
- Integration tests
- State management
- Navigation flow
- Deep linking
- Performance

## Documentation
- [App Architecture](../../docs/architecture.md)
- [State Management](../../docs/state.md)
- [Navigation](../../docs/navigation.md)
- [Module Integration](../../docs/integration.md)
