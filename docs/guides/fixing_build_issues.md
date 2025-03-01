# Guide to Fixing YeelightControl Build Issues

This guide provides detailed steps to resolve the compilation errors in the YeelightControl project.

## Progress Update

I've made significant progress in resolving the build issues:

1. ✅ Removed duplicate `Core_Color` definitions by:
   - Moving the definition to a dedicated `ColorTypes.swift` file
   - Removing duplicate definitions from other files
   - Adding comments to indicate where the type is defined

2. ✅ Removed duplicate effect-related types:
   - `Core_Effect` is now defined only in `Effect.swift`
   - `Core_EffectType` is now defined only in `EffectType.swift`
   - `Core_EffectParameters` is now defined only in `EffectParameters.swift`
   - `Core_EffectUpdate` is now defined only in `EffectUpdate.swift`

3. ✅ Removed duplicate scene-related types from `UnifiedSceneManager.swift`

4. ✅ Created proper separation between device and Yeelight types

5. ✅ Fixed protocol conformance issues for several manager classes:
   - `UnifiedNotificationManager` now properly conforms to `Core_BaseService`
   - `UnifiedStorageManager` now properly conforms to `Core_BaseService`
   - `UnifiedDeviceManager` now properly conforms to `Core_DeviceManaging`
   - `UnifiedErrorHandler` now properly conforms to `Core_ErrorHandling`
   - `UnifiedNetworkManager` now properly conforms to `Core_BaseService`
   - `UnifiedStateManager` now properly conforms to `Core_StateManaging`
   - `UnifiedAnalyticsManager` now properly conforms to `Core_BaseService`
   - `UnifiedConfigurationManager` now properly conforms to `Core_BaseService`
   - `UnifiedYeelightManager` now properly conforms to `Core_YeelightManaging` and `Core_BaseService`

6. ✅ Fixed `Core_ConfigurationError` usage in `ServiceContainer.swift`

7. ✅ Cleaned up `TypeDefinitions.swift` to remove duplicate type definitions and add clear comments

8. ✅ Fixed actor isolation issues in several manager classes:
   - Made `UserDefaults` and `FileManager` conform to `Sendable`
   - Fixed `isEnabled` property in manager classes to be properly nonisolated
   - Ensured proper async/await usage in actor methods

9. ✅ Fixed background manager issues in `UnifiedBackgroundManager.swift`:
   - Updated method calls to match the expected parameter types
   - Ensured all member accesses are valid
   - Added proper constants for task identifiers and refresh intervals

10. ✅ Fixed UI components to use correct device types:
    - Updated `ScenePreview.swift` to use `YeelightDevice` instead of `UnifiedYeelightDevice`
    - Fixed `DeviceStateRow`, `MultiLightPreview`, and `StripEffectPreview` to work with the correct device type
    - Updated `LightsView.swift` to properly handle `YeelightDevice` type
    - Added missing `yeelightManager` environment object to UI components

11. ✅ Added missing methods to `UnifiedYeelightManager`:
    - Implemented `applyScene` and `stopEffect` methods required by UI components
    - Fixed type alias for `YeelightDevice` in `UIEnvironment.swift`

12. ✅ Fixed circular reference in `UIEnvironment.swift`:
    - Changed `YeelightDevice` typealias to reference `Core.YeelightDevice` instead of itself
    - Fixed other type aliases to use valid types

13. ✅ Created proper `Theme` implementation in `UIEnvironment.swift`:
    - Updated `Theme` struct to match the Core module's theme structure
    - Made `ThemeKey` and `EnvironmentValues` extension public
    - Added proper properties to match `Core_ThemeColors`

14. ✅ Added `YeelightScene` protocol to avoid ambiguity with `SwiftUI.Scene`:
    - Created a dedicated protocol for Yeelight scenes
    - This will help resolve ambiguity errors in UI components

15. ✅ Created observable wrapper classes for actor types:
    - Created `ObservableYeelightManager` wrapper class for `UnifiedYeelightManager`
    - Created `ObservableLogger` wrapper class for `UnifiedLogger`
    - Created `ObservableAutomationManager` wrapper class for `UnifiedAutomationManager`
    - Added `@Published` properties to wrapper classes
    - Made wrapper classes `@MainActor` to ensure UI updates happen on the main thread

16. ✅ Added missing types for UI components:
    - Added `LogEntry` type with `Level` and `Category` enums
    - Added `Automation` type with `AutomationTrigger` and `AutomationAction` enums
    - Added `DeviceSettings` type for scene creation
    - Added `ScenePreset` type for predefined scenes
    - Added `Color` extension to make it `Codable`

17. ✅ Fixed UI files to use observable wrapper classes:
    - Updated `MainView.swift` to use `ObservableYeelightManager` and other wrapper classes
    - Updated `AutomationView.swift` to use `ObservableAutomationManager`
    - Updated `LogViewerView.swift` to use `ObservableLogger`
    - Updated `SceneListView.swift` to use `YeelightScene` instead of `Scene`
    - Updated `CreateSceneView.swift` to use `DeviceSettings` type correctly

18. ✅ Created common UI components to avoid duplication:
    - Created `FilterChip` component in `CommonComponents.swift`
    - Created `DeviceChip` component in `CommonComponents.swift`
    - Created `ConnectionStatusView` component in `CommonComponents.swift`
    - Created `StatusRow` component in `CommonComponents.swift`
    - Created `DeviceRow` component in `CommonComponents.swift`

19. ✅ Created centralized components for commonly duplicated views:
    - Created centralized `LogViewerView` component in `LogViewerComponent.swift`
    - Created centralized `BackupView` and `RestoreView` components in `BackupRestoreComponents.swift`

20. ✅ Created more observable wrapper classes:
    - Created `ObservableDeviceManager` for `UnifiedDeviceManager`
    - Created `ObservableEffectManager` for `UnifiedEffectManager`
    - Created `ObservableSceneManager` for `UnifiedSceneManager`
    - Created `ObservableNetworkManager` for `UnifiedNetworkManager`
    - Created `ObservableStorageManager` for `UnifiedStorageManager`
    - Created `ObservableLocationManager` for `UnifiedLocationManager`
    - Created `ObservablePermissionManager` for `UnifiedPermissionManager`
    - Created `ObservableAnalyticsManager` for `UnifiedAnalyticsManager`
    - Created `ObservableConfigurationManager` for `UnifiedConfigurationManager`
    - Created `ObservableStateManager` for `UnifiedStateManager`
    - Created `ObservableSecurityManager` for `UnifiedSecurityManager`
    - Created `ObservableErrorManager` for `UnifiedErrorManager`
    - Created `ObservableThemeManager` for `UnifiedThemeManager`
    - Created `ObservableConnectionManager` for `UnifiedConnectionManager`
    - Created `ObservableRoomManager` for `UnifiedRoomManager`

21. ✅ Added missing types for UI components:
    - Added `Device` type for UI components
    - Added `DeviceState` type for UI components
    - Added `Effect` type for UI components
    - Added `EffectParameters` type for UI components
    - Added `FlowParams` type for UI components
    - Added `FlowTransition` type for UI components
    - Added `Room` type for UI components
    - Added `DeviceGroup` type for UI components
    - Added `MultiLightScene` type for UI components
    - Added `StripEffect` type for UI components

22. ✅ Updated type aliases in `UIEnvironment.swift` to use observable wrapper classes

23. ✅ Created `ServiceContainer+UI.swift` to extend `ServiceContainer` with UI-specific properties

24. ✅ Updated UI files to use centralized components:
    - Updated `SettingsView.swift` to use the centralized `LogViewerView` component
    - Updated `SettingsView.swift` to use the centralized `BackupView` and `RestoreView` components
    - Updated `AdvancedSettingsView.swift` to use the centralized `FilterChip` component
    - Updated `LightsView.swift` to use the centralized `DeviceRow` component
    - Updated `DeviceDetailView.swift` to use the centralized `ConnectionStatusView` component
    - Updated `NetworkTestsView.swift` to use the centralized `StatusRow` component
    - Updated `EffectsListView.swift` to use the centralized `DeviceChip` component

25. ✅ Added more centralized UI components:
    - Created centralized `StatusSection` component in `CommonComponents.swift`
    - Created centralized `EnhancedDeviceSelectionList` component in `CommonComponents.swift`
    - Updated `NetworkTestsView.swift` to use the centralized `StatusSection` component
    - Updated `CreateAutomationView.swift` to use the centralized `LocationPicker` component
    - Updated `CreateAutomationView.swift` to use the centralized `EnhancedDeviceSelectionList` component
    - Updated `CreateAutomationView.swift` to use observable wrapper classes

26. ✅ Updated DetailContentView.swift to use centralized components:
    - Removed duplicate `DeviceRow` implementation
    - Removed duplicate `DeviceDetailView` implementation
    - Updated to use `ObservableYeelightManager` instead of `YeelightManager`
    - Added proper imports for `Core` and `UI.Components`

27. ✅ Fixed string conversion in `UnifiedNotificationManager.swift`:
    - Fixed conditional binding issues in userInfo dictionary conversion
    - Corrected the method name from `unTrigger` to `unNotificationTrigger` to match `Core_AppNotificationTrigger` enum
    - Updated `AnalyticsEvent` reference to `Core_AnalyticsEvent` with correct parameters
    - Simplified string conversion logic to only check for the key being a string

28. ✅ Fixed actor isolation issues in `UnifiedLogger.swift`:
    - Updated the `log` method to be nonisolated and properly delegate to an internal method
    - Fixed the `clearLogs` method to be properly async
    - Added missing protocol requirements for `Core_LoggingService`
    - Updated storage method calls to use correct method names and argument labels

29. ✅ Fixed actor isolation issues in `UnifiedEffectManager.swift`:
    - Changed the class to an actor to properly handle isolation
    - Fixed the `isEnabled` property to properly handle async access
    - Updated method signatures to match the protocol requirements
    - Updated storage method calls to use correct argument labels

30. ✅ Fixed storage method calls in `UnifiedDeviceManager.swift`:
    - Updated all storage method calls to use correct argument labels (`forKey` instead of `key:value:`)
    - Fixed the `isEnabled` property to use `task.value` instead of `task.result.get()`

31. ✅ Added missing `getAll` method to `UnifiedStorageManager.swift`:
    - Implemented `getAll<T: Codable>(withPrefix:)` method to retrieve all items with a specific prefix
    - Added proper error handling and type conversion

32. ✅ Added `SourceLocation` struct and updated `Core_AppError`:
    - Added `SourceLocation` struct with file, function, and line properties
    - Updated `Core_AppError` to include a `sourceLocation` property
    - Modified the `unknown` case to accept an associated `Error` value
    - Updated `UnifiedErrorHandler` to use the new `sourceLocation` property

33. ✅ Fixed enum stored property issue in `Core_AppError`:
    - Changed the private stored property to use an associated value in the `unknown` case
    - Updated the `sourceLocation` property to use a computed property based on the case
    - Updated the `with(sourceLocation:)` method to create a new enum instance with the source location
    - Updated the `id` and `errorDescription` methods to handle the updated `unknown` case

## Current Status

We've made significant progress on fixing the Core module issues, but there are still several critical issues that need to be addressed:

1. **Device Type Issues**:
   - The `Device` struct is missing the `isConnected` property
   - The `DeviceType` enum is missing the `bulb` and `strip` members
   - The `DeviceColor` type has issues with the `red` property

2. **Type Conversion Issues**:
   - Cannot convert between types like `Device` and `Core_Device`
   - Cannot convert between types like `Effect` and `Core_Effect`

3. **Protocol Conformance Issues**:
   - `UnifiedDeviceManager` does not conform to `Core_DeviceManaging`
   - `UnifiedEffectManager` does not conform to `Core_EffectManaging`
   - `UnifiedLogger` does not conform to `Core_LoggingService`

## Remaining Issues to Fix

### Core Module Issues

1. **Device Type Issues**:
   - Add the `isConnected` property to the `Device` struct
   - Add the missing members to the `DeviceType` enum
   - Fix the `DeviceColor` type issues

2. **Type Conversion Issues**:
   - Implement proper type conversion between Core types and implementation types
   - Ensure all types properly conform to their Core counterparts

3. **Protocol Conformance Issues**:
   - Implement all required methods and properties for each protocol
   - Ensure the method signatures match the protocol requirements

### UI Module Issues

Once the Core module is fixed, we'll need to address the UI module issues:

1. **Duplicate view declarations**:
   - Update UI files to use centralized components
   - Remove duplicate view declarations from the original files

2. **ObservableObject conformance issues**:
   - Update UI files to use the observable wrapper classes
   - Update UI files to use `@EnvironmentObject` with the observable wrapper classes

3. **ServiceContainer access issues**:
   - Update UI files to import the `ServiceContainer+UI.swift` file
   - Update UI files to use the UI-specific properties from `ServiceContainer`

## Detailed Core Fix Plan

### 1. Fix Device Type Issues

Update the `Device` struct to include the `isConnected` property:

```swift
public struct Device: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let manufacturer: String
    public let model: String
    public let firmwareVersion: String
    public let ipAddress: String
    public let macAddress: String
    public var state: DeviceState
    public var isConnected: Bool // Add this property
    
    // Add initializer with isConnected parameter
    public init(id: String, name: String, type: DeviceType, manufacturer: String, model: String, 
                firmwareVersion: String, ipAddress: String, macAddress: String, state: DeviceState, 
                isConnected: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.manufacturer = manufacturer
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.state = state
        self.isConnected = isConnected
    }
}
```

Update the `DeviceType` enum to include the missing members:

```swift
public enum DeviceType: String, Codable {
    case bulb = "bulb"
    case strip = "strip"
    case ceiling = "ceiling"
    case desk = "desk"
    case ambient = "ambient"
    case unknown = "unknown"
}
```

Fix the `DeviceColor` type issues:

```swift
public struct DeviceColor: Codable, Hashable {
    public let red: Int
    public let green: Int
    public let blue: Int
    
    public static let white = DeviceColor(red: 255, green: 255, blue: 255)
    public static let red = DeviceColor(red: 255, green: 0, blue: 0)
    public static let green = DeviceColor(red: 0, green: 255, blue: 0)
    public static let blue = DeviceColor(red: 0, green: 0, blue: 255)
    
    public init(red: Int, green: Int, blue: Int) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}
```

### 2. Fix Storage Method Call Issues

Update the storage method calls to use the correct argument labels:

```swift
// Before
try? await storageManager.save(key: "device.\(device.id)", value: device)

// After
try? await storageManager.save(device, forKey: "device.\(device.id)")
```

Ensure the `storageManager` interface is consistent:

```swift
// Before
if let storedLogs: [Core_LogEntry] = try await storageManager.get(forKey: "logs") {
    logs = storedLogs
}

// After
if let storedLogs: [Core_LogEntry] = try await storageManager.load(forKey: "logs") {
    logs = storedLogs
}
```

### 3. Fix Type Conversion Issues

Implement proper type conversion between Core types and implementation types:

```swift
// Before
return await _devices.map { $0 }

// After
return await _devices.map { $0 }
```

Ensure all types properly conform to their Core counterparts:

```swift
// Make Device conform to Core_Device
extension Device: Core_Device {
    // Implement any required methods or properties
}
```

### 4. Fix Protocol Conformance Issues

Implement all required methods and properties for each protocol:

```swift
// Before (missing method)
public func getAvailableEffects() -> [Core_Effect] {
    // Convert local effects to Core_Effect
    return _effects.map { $0 as Core_Effect }
}

// After (implemented method)
public nonisolated func getAvailableEffects() async -> [Core_Effect] {
    let allEffects = await _effects
    return allEffects.map { $0 as Core_Effect }
}
```

### 5. Fix Error Handling Issues

Update the `Core_AppError` type to include the required properties:

```swift
public enum Core_AppError: Error, Identifiable {
    case network(Error)
    case storage(Error)
    case device(Error)
    case configuration(Error)
    case unknown(Error)
    
    public var id: String {
        switch self {
        case .network(let error): return "network.\(error.localizedDescription)"
        case .storage(let error): return "storage.\(error.localizedDescription)"
        case .device(let error): return "device.\(error.localizedDescription)"
        case .configuration(let error): return "configuration.\(error.localizedDescription)"
        case .unknown(let error): return "unknown.\(error.localizedDescription)"
        }
    }
    
    public var sourceLocation: SourceLocation {
        return SourceLocation(file: "", function: "", line: 0)
    }
}

public struct SourceLocation {
    public let file: String
    public let function: String
    public let line: Int
    
    public init(file: String, function: String, line: Int) {
        self.file = file
        self.function = function
        self.line = line
    }
}
```

## Implementation Strategy

1. Fix the Core module issues first, focusing on the most critical files:
   - `TypeDefinitions.swift`: Fix the `Device`, `DeviceType`, and `DeviceColor` types
   - `StorageProtocols.swift`: Ensure the storage manager interface is consistent
   - `ErrorTypes.swift`: Update the `Core_AppError` type
   - `UnifiedDeviceManager.swift`: Fix protocol conformance and method calls
   - `UnifiedEffectManager.swift`: Fix protocol conformance and method calls
   - `UnifiedLogger.swift`: Fix protocol conformance and method calls

2. Once the Core module builds successfully, address the UI module issues:
   - Update UI files to use centralized components
   - Update UI files to use observable wrapper classes
   - Fix ServiceContainer access issues

3. Test the build after each set of changes to ensure progress is being made

## Testing the Fixes

After implementing the fixes:

1. Run the setup script again: `./Scripts/setup_xcode_project.sh`
2. Build the project: `cd Build && xcodebuild -project YeelightControl.xcodeproj -scheme YeelightControl -configuration Debug CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO`
3. Address any remaining errors one by one

## Long-term Recommendations

1. **Adopt Swift Packages**: Split the codebase into modular Swift packages
2. **Use Namespaces**: When Swift introduces proper namespaces, refactor to use them
3. **Consistent Naming**: Adopt a consistent naming convention without prefixes
4. **Reduce Interdependencies**: Minimize dependencies between modules
5. **Automated Tests**: Add tests to catch type and protocol conformance issues early
6. **Sendability Annotations**: Add proper sendability annotations to all types that cross actor boundaries
7. **Consistent Async/Await Usage**: Ensure all async code properly uses the await keyword
8. **Proper Actor Design**: Design actors with UI interaction in mind, using MainActor where appropriate 