# Migration Guide

## Version History

### 1.0.0 (Current)
- Initial release
- Core device management
- Effect system
- Scene management
- Room organization
- Widget support

## Migration Steps

### Upgrading to 1.0.0

#### New Features
- Async/await API support
- Enhanced error handling
- Improved type safety
- Widget integration
- Comprehensive testing support

#### Breaking Changes
- Replaced completion handlers with async/await
- Updated error types
- Modified device discovery process
- Changed scene configuration format

#### Migration Example

##### Before (0.9.x)
```swift
// Device discovery
deviceManager.discoverDevices { result in
    switch result {
    case .success(let devices):
        // Handle devices
    case .failure(let error):
        // Handle error
    }
}

// Device control
deviceManager.setPower(true, for: deviceId) { error in
    if let error = error {
        // Handle error
    }
}
```

##### After (1.0.0)
```swift
// Device discovery
do {
    let devices = try await deviceManager.discoverDevices()
    // Handle devices
} catch {
    // Handle error
}

// Device control
do {
    try await deviceManager.setPower(true, for: deviceId)
} catch {
    // Handle error
}
```

## Deprecation Notices

### Deprecated in 1.0.0
- Completion handler-based APIs
- Old error types
- Legacy device discovery
- Previous scene format

### Future Deprecations
- None planned at this time

## Compatibility

### Version Compatibility Matrix
| Feature | 0.9.x | 1.0.0 |
|---------|--------|--------|
| Core Device Management | ✓ | ✓ |
| Effect System | ✓ | ✓ |
| Scene Management | ✓ | ✓ |
| Room Organization | - | ✓ |
| Widget Support | - | ✓ |
| Async/Await | - | ✓ |

### Minimum Requirements
- iOS 15.0+
- macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## Best Practices

### Migration Best Practices
1. Update to latest version directly
2. Replace all completion handlers
3. Update error handling
4. Test thoroughly
5. Review documentation

### Testing During Migration
1. Run existing tests
2. Update test cases
3. Add new tests
4. Verify functionality
5. Check performance

## Support

### Getting Help
- Review documentation
- Check [GitHub issues](https://github.com/DanielKng/YeelightControl/issues)

### Reporting Issues
- Use GitHub issues
- Provide version numbers
- Include migration context
- Share error details 