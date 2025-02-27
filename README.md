# YeelightControl

<div align="center">

![YeelightControl](https://raw.githubusercontent.com/DanielKng/YeelightControl/main/Resources/header.png)

*A modern iOS app for controlling Yeelight smart lighting devices*

[![Swift Version](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SwiftUI](https://img.shields.io/badge/Framework-SwiftUI-purple.svg)](https://developer.apple.com/xcode/swiftui/)
[![Build Status](https://github.com/DanielKng/YeelightControl/actions/workflows/swift.yml/badge.svg)](https://github.com/DanielKng/YeelightControl/actions)
[![Issues](https://img.shields.io/github/issues/DanielKng/YeelightControl)](https://github.com/DanielKng/YeelightControl/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/DanielKng/YeelightControl)](https://github.com/DanielKng/YeelightControl/pulls)

</div>

## ✨ What is YeelightControl?

YeelightControl transforms your iPhone into a powerful smart lighting command center. Control your Yeelight devices with an elegant, intuitive interface designed for everyday use and creative lighting projects.

<div align="center">
  <img src="Resources/Screenshots/home.png" width="200" alt="Home Screen"/>
  <img src="Resources/Screenshots/controls.png" width="200" alt="Light Controls"/>
  <img src="Resources/Screenshots/scenes.png" width="200" alt="Scene Management"/>
</div>

## 🚀 Key Features

### 💡 Smart Control
- **Instant Control**: Power, brightness, and color with a tap
- **Group Management**: Control multiple lights simultaneously
- **Room Organization**: Organize lights by location
- **Status Monitoring**: Real-time device status updates

### 🎨 Creative Lighting
- **Dynamic Color Flows**: Create moving color patterns
- **Music Visualization**: Lights that react to sound
- **Scene Presets**: Save and recall your favorite settings
- **Custom Transitions**: Smooth fades between states

### ⚡ Smart Automation
- **Time-Based Triggers**: Schedule lights to change automatically
- **Sunrise/Sunset Sync**: Align with natural light cycles
- **Location Awareness**: Trigger based on your location
- **Multi-Device Routines**: Coordinate complex lighting scenes

### 🔌 Advanced Features
- **Home Screen Widgets**: Control lights without opening the app
- **Virtual LED Strips**: Combine lights for chase effects
- **Offline Support**: Control devices without internet
- **Backup & Restore**: Save your configurations

## 📱 Quick Start Guide

### First-Time Setup

1. **Enable LAN Control on Your Yeelight Devices**
   - Open the official Yeelight app
   - Go to device settings
   - Enable "LAN Control"
   
2. **Install YeelightControl**
   - Download from the App Store
   - Launch the app
   - Grant local network permission when prompted

3. **Discover Your Devices**
   - Ensure your iPhone is on the same WiFi as your Yeelight devices
   - The app will automatically discover available devices
   - Tap a device to start controlling it

### Tips for Best Experience

- Keep your Yeelight devices' firmware updated
- For music sync features, use in a quiet environment
- Create rooms first, then add devices to them
- Experiment with scenes for quick mood changes

## 🎬 Features in Action

### Music Sync Mode

Transform your space with lights that pulse and change with your music:

<div align="center">
  <img src="Resources/Screenshots/music-sync.png" width="300" alt="Music Sync Feature"/>
</div>

### Virtual LED Strip

Combine multiple lights to create chase effects and waves:

<div align="center">
  <img src="Resources/Screenshots/led-strip.png" width="300" alt="Virtual LED Strip"/>
</div>

### Scene Creation

Design and save custom lighting scenes for any occasion:

<div align="center">
  <img src="Resources/Screenshots/scene-editor.png" width="300" alt="Scene Editor"/>
</div>

## 🔧 Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| **Devices not discovered** | Ensure "LAN Control" is enabled in the official Yeelight app. Check that your iPhone and lights are on the same WiFi network. |
| **Music sync not responsive** | Increase sensitivity in settings. Ensure microphone permission is granted. Try in a quieter environment. |
| **Widgets not updating** | Enable background app refresh for YeelightControl in iOS settings. Try removing and re-adding the widget. |

Need more help? Check the [full troubleshooting guide](https://github.com/DanielKng/YeelightControl/wiki/Troubleshooting) in our wiki.

---

## 💻 Developer Information

### Project Structure

YeelightControl uses a unique project structure that separates source code from the Xcode build environment:

```
YeelightControl/
├── Sources/        # Main source code (development happens here)
│   ├── App/          # Main app setup
│   ├── Core/         # Core functionality
│   │   ├── Networking/   # Network operations
│   │   ├── Device/      # Device management
│   │   ├── Utils/       # Utilities
│   │   ├── Background/  # Background tasks
│   │   └── Storage/     # Data persistence
│   ├── Features/     # Main features
│   │   ├── Scenes/      # Scene management
│   │   ├── Rooms/       # Room organization
│   │   ├── Effects/     # Light effects
│   │   ├── Groups/      # Group management
│   │   └── Automation/  # Automation system
│   ├── UI/           # UI components
│   └── Widget/       # Widget extension
│
├── Xcode/         # Generated Xcode project (for building only)
│   ├── YeelightControl/
│   ├── YeelightControl.xcodeproj/
│   └── YeelightControl.xcworkspace/
│
└── setup_xcode_project.sh  # Script to generate Xcode project from Sources
```

This separation allows for:
- Clean source code management without Xcode project file noise
- Easy script-based project generation
- Better git workflow with fewer conflicts
- Simplified CI/CD integration

### Development Workflow

1. Make changes to files in the `/Sources` directory
2. Run `./setup_xcode_project.sh` to update the Xcode project
3. Open the generated workspace in `/Xcode` to build and run

### Technical Highlights

- **SwiftUI Framework**: Modern declarative UI
- **Combine Framework**: Reactive programming for state management
- **Background Tasks**: Reliable background updates
- **WidgetKit**: Home screen widgets for quick control
- **Network Discovery**: Automatic device detection using Bonjour
- **Async/Await**: Modern concurrency for network operations

### Building from Source

<details>
<summary>Click to expand build instructions</summary>

#### Requirements
- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

#### Steps
1. Clone the repository
```bash
git clone https://github.com/DanielKng/YeelightControl.git
```

2. Generate the Xcode project
```bash
cd YeelightControl
./setup_xcode_project.sh
```

3. Open the project
```bash
open Xcode/YeelightControl.xcworkspace
```

4. Configure signing and build
</details>

## 👥 Contributing

We welcome contributions! See our [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas for Improvement

- Additional device type support
- HomeKit integration
- Localization to more languages
- Advanced automation conditions

## 📄 License

YeelightControl is available under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

This project wouldn't be possible without the amazing work of:

- [Apple](https://developer.apple.com)
  - [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Modern UI framework
  - [Combine](https://developer.apple.com/documentation/combine) - Reactive programming
  - [SF Symbols](https://developer.apple.com/sf-symbols/) - Beautiful system icons
  - [WidgetKit](https://developer.apple.com/documentation/widgetkit) - Home screen widgets

- [Yeelight](https://www.yeelight.com)
  - [Inter-Operation Specification](https://www.yeelight.com/download/Yeelight_Inter-Operation_Spec.pdf) - Comprehensive API documentation
  - Local Network Control Protocol - Enabling direct device communication

- Open Source Community
  - [Swift Package Manager](https://swift.org/package-manager/) - Dependency management
  - [Swift](https://swift.org) - Programming language
  - [Bonjour](https://developer.apple.com/bonjour/) - Network discovery

Special thanks to all contributors and testers who have helped improve this project.

---

<div align="center">
  
Made with ❤️ by [Daniel Kng](https://github.com/DanielKng)

[Report Bug](https://github.com/DanielKng/YeelightControl/issues/new?template=bug_report.md) · 
[Request Feature](https://github.com/DanielKng/YeelightControl/issues/new?template=feature_request.md)

</div>