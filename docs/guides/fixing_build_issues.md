# Guide to Fixing YeelightControl Build Issues

This guide provides detailed steps to resolve the compilation errors in the YeelightControl project.

## Root Causes

The project has several structural issues that lead to compilation errors:

1. **Type Redeclarations**: Multiple files define the same types with `Core_` prefix
2. **Ambiguous Type References**: Due to redeclarations, the compiler cannot determine which type to use
3. **Protocol Conformance Issues**: Some types don't properly conform to their declared protocols
4. **Actor Isolation Problems**: Actor-isolated properties are used to satisfy nonisolated protocol requirements
5. **Missing Type Definitions**: Some referenced types are not defined in the codebase

## Step-by-Step Fix Plan

### 1. Establish Clear Type Hierarchy

Create a clear hierarchy for all Core types:

```swift
// Example structure
namespace Core {
    namespace Network {
        // Network types
    }
    
    namespace Device {
        // Device types
    }
    
    // etc.
}
```

### 2. Fix Type Redeclarations

For each redeclared type:

1. Identify all occurrences of the type (e.g., `Core_NetworkError`)
2. Keep only one definition in the appropriate file
3. Update all references to use the single definition

Example files to fix:
- `ErrorTypes.swift`
- `NetworkTypes.swift`
- `NotificationTypes.swift`

### 3. Resolve Protocol Conformance Issues

For each type with conformance issues:

1. Identify the required protocol methods and properties
2. Implement all required methods and properties
3. Ensure the implementations match the protocol requirements

Example:
```swift
// Protocol
protocol Core_BaseService {
    func initialize() async
    func shutdown() async
}

// Implementation
extension UnifiedConfigurationManager: Core_BaseService {
    public func initialize() async {
        // Implementation
    }
    
    public func shutdown() async {
        // Implementation
    }
}
```

### 4. Address Actor Isolation Issues

For actor-isolated properties used in protocols:

1. Mark protocol requirements as `nonisolated` where appropriate
2. Use `nonisolated` getters for properties that need to be accessed outside the actor
3. Consider using publishers for state that needs to be observed

Example:
```swift
protocol Core_LocationManaging {
    nonisolated var currentLocation: CLLocation? { get }
}

actor UnifiedLocationManager: Core_LocationManaging {
    private var _currentLocation: CLLocation?
    
    nonisolated public var currentLocation: CLLocation? {
        get {
            _currentLocation
        }
    }
}
```

### 5. Fix Missing Type Definitions

For each missing type:

1. Identify where the type should be defined
2. Create the appropriate definition
3. Update all references to use the new definition

Example missing types:
- `AppPermissionType` → Replace with `Core_PermissionType`
- `LogCategory` → Create this enum if missing

## Critical Files to Fix First

1. **Core/Types/Error/ErrorTypes.swift**
   - Remove duplicate enum definitions
   - Keep only typealiases and unique types

2. **Core/Types/Network/NetworkTypes.swift**
   - Remove duplicate `Core_NetworkError` definition
   - Ensure `Core_NetworkAPIManaging` is used consistently

3. **Core/Types/Permission/PermissionTypes.swift**
   - Resolve `Core_PermissionStatus` ambiguity
   - Ensure `Core_PermissionType` is used instead of `AppPermissionType`

4. **Core/Types/Notification/NotificationTypes.swift**
   - Fix `Core_NotificationRequest` Hashable conformance
   - Ensure `Core_AppNotificationCategory` and `Core_AppNotificationTrigger` are properly defined

5. **Core/Types/Yeelight/CoreYeelightTypes.swift** and **Core/Types/Device/YeelightTypes.swift**
   - Ensure clear separation between these files
   - Use consistent naming for Yeelight-related types

## Testing the Fixes

After implementing the fixes:

1. Run the setup script again: `./Scripts/setup_xcode_project.sh`
2. Build the project: `cd Build && xcodebuild -project YeelightControl.xcodeproj -scheme YeelightControl -destination "platform=iOS Simulator,id=65B712EF-66D5-40DC-8306-E34D0376F218" build`
3. Address any remaining errors one by one

## Long-term Recommendations

1. **Adopt Swift Packages**: Split the codebase into modular Swift packages
2. **Use Namespaces**: When Swift introduces proper namespaces, refactor to use them
3. **Consistent Naming**: Adopt a consistent naming convention without prefixes
4. **Reduce Interdependencies**: Minimize dependencies between modules
5. **Automated Tests**: Add tests to catch type and protocol conformance issues early 