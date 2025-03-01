# YeelightControl Build Issues Summary

## Main Issues

1. Ambiguous type references for Core_ prefixed types
2. Protocol conformance issues
3. Actor isolation issues with nonisolated protocol requirements
4. Missing type definitions
5. Duplicate type definitions across multiple files
6. Sendability issues with non-sendable types in actor-isolated contexts

## Progress Made

1. ✅ Removed duplicate `Core_Color` definitions from multiple files
2. ✅ Removed duplicate effect-related types (`Core_Effect`, `Core_EffectType`, `Core_EffectParameters`, `Core_EffectUpdate`)
3. ✅ Removed duplicate scene-related types
4. ✅ Created proper separation between device and Yeelight types
5. ✅ Fixed protocol conformance issues for several manager classes
6. ✅ Fixed `Core_ConfigurationError` usage in `ServiceContainer.swift`
7. ✅ Cleaned up `TypeDefinitions.swift` to remove duplicate type definitions
8. ✅ Fixed actor isolation issues in several manager classes

## Remaining Issues

1. Actor isolation issues in BaseServiceContainer:
   - Passing non-sendable types into actor-isolated contexts
   - Not properly awaiting async calls
   - Type mismatches between BaseServiceContainer and ServiceContainer

2. Storage method signature issues:
   - The `load` method is not being called with the correct generic type parameter
   - The `save` method is being called with non-Codable types

3. Analytics manager issues:
   - Type mismatches in the `load` method calls
   - Missing generic type parameters

4. Background manager issues:
   - Type mismatches in method calls
   - Accessing private constants
   - Accessing non-existent members

## Recommended Approach

1. Fix BaseServiceContainer issues:
   - Make UserDefaults and FileManager conform to Sendable or use alternative approaches
   - Properly await async calls with the await keyword
   - Ensure BaseServiceContainer and ServiceContainer are compatible

2. Fix storage method signature issues:
   - Update all calls to load and save methods to include the correct generic type parameters
   - Ensure all types being saved conform to Codable

3. Fix analytics manager issues:
   - Update all calls to load and save methods to include the correct generic type parameters
   - Ensure all types being loaded/saved conform to Codable

4. Fix background manager issues:
   - Update method calls to match the expected parameter types
   - Make constants accessible or use alternative approaches
   - Ensure all member accesses are valid

## Specific Files Needing Attention

- BaseServiceContainer.swift: Fix actor isolation issues and type mismatches
- UnifiedAnalyticsManager.swift: Fix method signature issues
- UnifiedConfigurationManager.swift: Fix method signature issues
- UnifiedBackgroundManager.swift: Fix method calls and member accesses

More about potential fixing, [HERE](docs/guides/fixing_build_issues.md)