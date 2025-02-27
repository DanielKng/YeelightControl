# Scenes Feature README

This directory contains the implementation of the Scenes feature in YeelightControl.

## Note on DeviceStorage+Scenes.swift

The file `DeviceStorage+Scenes.swift` was previously duplicated in both:
- `/Sources/Core/Storage/DeviceStorage+Scenes.swift`
- `/Sources/Features/Scenes/DeviceStorage+Scenes.swift`

To resolve compilation errors and maintain a cleaner codebase, the duplicate file in this directory has been marked for deletion. All scene-related DeviceStorage extensions are now maintained in the Core/Storage directory.

### Important: Delete the duplicate file

To completely resolve this issue, please delete the duplicate file by running:

```bash
rm /Users/danielkng/Documents/YeelightControl/Sources/Features/Scenes/DeviceStorage+Scenes.swift
```

If you need to modify scene storage functionality, please edit the file in `/Sources/Core/Storage/DeviceStorage+Scenes.swift`.

## Feature Components

This directory contains the following components:
- Scene creation and editing
- Scene discovery and sharing
- Scene application to devices
- Scene presets and templates 