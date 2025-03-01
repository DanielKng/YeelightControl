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
9. ✅ Fixed `Core_BaseService` protocol conformance in `UnifiedStorageManager`, `UnifiedAnalyticsManager`, and `UnifiedConfigurationManager`
10. ✅ Made `UserDefaults` and `FileManager` conform to `Sendable` to fix actor isolation issues

## Remaining Issues

1. UI module issues:
   - Missing type references in UI components
   - Duplicate view declarations across multiple files
   - Environment object type mismatches
   - Invalid use of protocols as types without 'any' keyword

2. Background manager issues:
   - Type mismatches in method calls
   - Accessing non-existent members

## Recommended Approach

1. Fix UI module issues:
   - Ensure proper imports of Core types in UI components
   - Resolve duplicate view declarations
   - Update environment object types to match the Core module
   - Add 'any' keyword where protocols are used as types

2. Fix background manager issues:
   - Update method calls to match the expected parameter types
   - Ensure all member accesses are valid

## Specific Files Needing Attention

- UI module view files: Fix type references and environment object declarations
- UnifiedBackgroundManager.swift: Fix method calls and member accesses

More about potential fixing, [HERE](docs/guides/fixing_build_issues.md)