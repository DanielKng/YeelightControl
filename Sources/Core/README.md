# Core Module

The Core module is the foundation of the YeelightControl app, providing essential services, managers, and types that power the entire application. This module follows clean architecture principles and emphasizes type safety, modularity, and testability.

## Directory Structure

### Analytics and Monitoring
#### `Analytics/` - Usage Tracking and Metrics
- `UnifiedAnalyticsManager.swift` - Analytics event tracking and reporting
  - User interaction tracking
  - Feature usage analytics
  - Error reporting
  - Performance metrics

### System Integration
#### `Background/` - Background Task Management
- `UnifiedBackgroundManager.swift` - Background process handling
  - Task scheduling
  - Background refresh
  - State preservation
  - Resource management

#### `Location/` - Location Services
- `UnifiedLocationManager.swift` - Location awareness
  - Geofencing
  - Region monitoring
  - Location-based triggers
  - Privacy controls

#### `Notification/` - User Notifications
- `UnifiedNotificationManager.swift` - Notification handling
  - Local notifications
  - Remote notifications
  - Notification scheduling
  - User preferences

### Configuration and Security
#### `Configuration/` - App Configuration
- `UnifiedConfigurationManager.swift` - Configuration management
  - App settings
  - User preferences
  - Feature flags
  - Environment configuration

#### `Permission/` - Permission Management
- `UnifiedPermissionManager.swift` - System permissions
  - Permission requests
  - Authorization status
  - Permission changes
  - User guidance

#### `Security/` - Security Features
- `UnifiedSecurityManager.swift` - Security management
  - Authentication
  - Data encryption
  - Secure storage
  - Access control

### Device and Control
#### `Device/` - Device Management
- `UnifiedDeviceManager.swift` - Central device management
  - Device discovery
  - Connection handling
  - State management
  - Command dispatch
- `UnifiedYeelightManager.swift` - Yeelight-specific control
  - Protocol implementation
  - Command translation
  - State synchronization
- `YeelightModels.swift` - Device data models
  - Device properties
  - State definitions
  - Command structures

#### `Effect/` - Light Effects
- `UnifiedEffectManager.swift` - Effect management
  - Effect definitions
  - Animation control
  - Timing management
  - Synchronization

#### `Scene/` - Scene Management
- `UnifiedSceneManager.swift` - Scene control
  - Scene creation
  - Scene activation
  - State persistence
  - Transition handling

### Network and Communication
#### `Network/` - Network Operations
- `UnifiedNetworkManager.swift` - Network communication
  - Connection management
  - Protocol handling
  - Error recovery
  - State monitoring
- `UnifiedNetworkProtocolManager.swift` - Protocol-specific handling
  - Protocol implementation
  - Message formatting
  - Response parsing

### State and Storage
#### `State/` - Application State
- `UnifiedStateManager.swift` - State management
  - Global state
  - State updates
  - Change notifications
  - State restoration

#### `Storage/` - Data Persistence
- `UnifiedStorageManager.swift` - Storage management
  - Data persistence
  - Cache management
  - File operations
  - Migration handling

### Error Handling and Logging
#### `Error/` - Error Management
- `UnifiedErrorHandler.swift` - Error handling
  - Error definitions
  - Error recovery
  - User feedback
  - Logging integration
- `LoggingTypes.swift` - Logging structures
  - Log levels
  - Log categories
  - Message formatting

#### `Logging/` - Debug and Error Logging
- `UnifiedLogger.swift` - Logging system
  - Log management
  - File logging
  - Console output
  - Log rotation

### Type System
#### `Types/` - Core Type Definitions
- `Configuration/`
  - Configuration types
  - Setting definitions
  - Preference models
- `Device/`
  - Device state models
  - Command types
  - Property definitions
- `Effect/`
  - Effect parameters
  - Animation types
  - Timing models
- `Error/`
  - Error types
  - Error categories
  - Recovery options
- `Location/`
  - Location models
  - Region types
  - Coordinate handling
- `Permission/`
  - Permission types
  - Authorization models
  - Status definitions
- `Scene/`
  - Scene models
  - State definitions
  - Transition types

### Services Layer
#### `Services/` - Core Services
- `ServiceContainer.swift` - Dependency injection
  - Service registration
  - Dependency resolution
  - Lifecycle management
  - Service access
- `YeelightProtocols.swift` - Device protocols
  - Command interfaces
  - State protocols
  - Event handling

## Design Principles

1. **Unified Management**
   - Each subsystem has a unified manager
   - Single point of access
   - Consistent interfaces
   - Clear responsibilities

2. **Type Safety**
   - Strong typing throughout
   - Clear domain models
   - Compile-time safety
   - Protocol conformance

3. **Dependency Injection**
   - Service container based
   - Clear dependencies
   - Testable components
   - Flexible configuration

4. **Protocol-Oriented**
   - Interface-based design
   - Protocol composition
   - Default implementations
   - Extension points

5. **Error Handling**
   - Comprehensive error types
   - Recovery strategies
   - User feedback
   - Logging integration

## Usage

```swift
import Core

// Access managers through the service container
let deviceManager = ServiceContainer.shared.deviceManager
let effectManager = ServiceContainer.shared.effectManager

// Example: Device Control
try await deviceManager.connect(to: deviceId)
try await deviceManager.setBrightness(0.75, for: deviceId)

// Example: Effect Management
let effect = ColorFlowEffect(colors: [.red, .blue], duration: 5.0)
try await effectManager.apply(effect, to: deviceId)
```

## Testing

Each component has corresponding unit tests. Run Core-specific tests:

```bash
swift test --filter "CoreTests"
```

## Best Practices

1. **Manager Access**
   - Always access through ServiceContainer
   - Respect access levels
   - Handle errors appropriately
   - Check operation status

2. **State Management**
   - Observe state changes
   - Handle updates atomically
   - Maintain consistency
   - Cache appropriately

3. **Error Handling**
   - Use specific error types
   - Provide recovery options
   - Log appropriately
   - Inform users

4. **Resource Management**
   - Clean up resources
   - Handle background states
   - Monitor memory usage
   - Optimize performance
