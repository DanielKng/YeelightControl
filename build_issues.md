# YeelightControl Build Issues Summary

## Main Issues

1. Ambiguous type references for Core_ prefixed types
2. Protocol conformance issues
3. Actor isolation issues with nonisolated protocol requirements
4. Missing type definitions
5. Duplicate type definitions across multiple files

## Progress Made

1. ✅ Removed duplicate `Core_Color` definitions from multiple files
2. ✅ Removed duplicate effect-related types (`Core_Effect`, `Core_EffectType`, `Core_EffectParameters`, `Core_EffectUpdate`)
3. ✅ Removed duplicate scene-related types
4. ✅ Created proper separation between device and Yeelight types

## Remaining Issues

1. Storage-related type duplications (`Core_StorageKey`, `Core_StorageDirectory`)
2. Analytics-related type duplications
3. Configuration-related type duplications
4. Actor isolation issues in various manager classes
5. Protocol conformance issues for some types

## Recommended Approach

1. Create a clear type hierarchy with proper namespacing
2. Ensure all Core_ prefixed types are uniquely defined
3. Update protocol conformances to match requirements
4. Address actor isolation issues by making protocol requirements nonisolated where appropriate
5. Fix missing type definitions

## Specific Files Needing Attention

- StorageTypes.swift and UnifiedStorageManager.swift: Resolve duplicate `Core_StorageKey` and `Core_StorageDirectory`
- AnalyticsTypes.swift and UnifiedAnalyticsManager.swift: Resolve duplicate analytics-related types
- ConfigurationTypes.swift and UnifiedConfigurationManager.swift: Resolve duplicate configuration-related types
- TypeDefinitions.swift: Remove or properly organize duplicate type definitions
- ServiceContainer.swift: Ensure proper type aliases are used consistently

More about potential fixing, [HERE](docs/guides/fixing_build_issues.md)