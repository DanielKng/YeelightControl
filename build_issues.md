# YeelightControl Build Issues Summary

## Main Issues

1. Ambiguous type references for Core_ prefixed types
2. Protocol conformance issues
3. Actor isolation issues with nonisolated protocol requirements
4. Missing type definitions

## Recommended Approach

1. Create a clear type hierarchy with proper namespacing
2. Ensure all Core_ prefixed types are uniquely defined
3. Update protocol conformances to match requirements
4. Address actor isolation issues by making protocol requirements nonisolated where appropriate
5. Fix missing type definitions

## Specific Files Needing Attention

- ErrorTypes.swift: Remove duplicate type definitions
- NetworkTypes.swift: Fix ambiguous Core_NetworkError references
- PermissionTypes.swift: Resolve Core_PermissionStatus ambiguity
- NotificationTypes.swift: Fix Core_NotificationRequest conformance
- YeelightTypes.swift and CoreYeelightTypes.swift: Ensure clear separation
- UnifiedManagers: Update to conform to their respective protocols
