# Device Module Documentation

This directory contains the core device management functionality for YeelightControl.

## Note on DeviceStorage.swift

The file `DeviceStorage.swift` was previously duplicated in both:
- `/Sources/Core/Storage/DeviceStorage.swift`
- `/Sources/Core/Device/DeviceStorage.swift`

To resolve compilation errors and maintain a cleaner codebase, the duplicate file in this directory has been marked for deletion. All device storage functionality is now maintained in the Core/Storage directory.

### Important: Delete the duplicate file

To completely resolve this issue, please delete the duplicate file by running:

```bash
rm /Users/danielkng/Documents/YeelightControl/Sources/Core/Device/DeviceStorage.swift
```

If you need to modify device storage functionality, please edit the file in `/Sources/Core/Storage/DeviceStorage.swift`.

## Module Components

This directory contains the following components:
- YeelightDevice: Core device model and functionality
- YeelightManager: Central manager for device discovery and control 