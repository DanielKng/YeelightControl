# YeelightControl

<div align="center">

![YeelightControl](https://raw.githubusercontent.com/DanielKng/YeelightControl/main/Resources/header.png)

*My modern iOS app for controlling Yeelight smart lighting devices*

[![Swift Version](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SwiftUI](https://img.shields.io/badge/Framework-SwiftUI-purple.svg)](https://developer.apple.com/xcode/swiftui/)
[![Build Status](https://github.com/DanielKng/YeelightControl/actions/workflows/swift.yml/badge.svg)](https://github.com/DanielKng/YeelightControl/actions)
[![Issues](https://img.shields.io/github/issues/DanielKng/YeelightControl)](https://github.com/DanielKng/YeelightControl/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/DanielKng/YeelightControl)](https://github.com/DanielKng/YeelightControl/pulls)

</div>

## ✨ What is YeelightControl?

I've created YeelightControl to transform your iPhone into a powerful smart lighting command center. You can control your Yeelight devices with an elegant, intuitive interface I've designed for everyday use and creative lighting projects.

<div align="center">
  <img src="Resources/Screenshots/home.png" width="200" alt="Home Screen"/>
  <img src="Resources/Screenshots/controls.png" width="200" alt="Light Controls"/>
  <img src="Resources/Screenshots/scenes.png" width="200" alt="Scene Management"/>
</div>

## 🚀 Key Features

### 💡 Smart Control
- **Instant Control**: I've made it easy to adjust power, brightness, and color with a tap
- **Group Management**: You can control multiple lights simultaneously
- **Room Organization**: I've added ways to organize lights by location
- **Status Monitoring**: You'll get real-time device status updates

### 🎨 Creative Lighting
- **Dynamic Color Flows**: Create moving color patterns with my custom flow editor
- **Music Visualization**: I've built a system for lights that react to sound
- **Scene Presets**: You can save and recall your favorite settings
- **Custom Transitions**: I've implemented smooth fades between states

### ⚡ Smart Automation
- **Time-Based Triggers**: I've made it possible to schedule lights to change automatically
- **Sunrise/Sunset Sync**: Your lights can align with natural light cycles
- **Location Awareness**: I've added triggers based on your location
- **Multi-Device Routines**: You can coordinate complex lighting scenes

### 🔌 Advanced Features
- **Home Screen Widgets**: I've created widgets so you can control lights without opening the app
- **Virtual LED Strips**: You can combine lights for chase effects
- **Offline Support**: I've ensured you can control devices without internet
- **Backup & Restore**: You can save your configurations

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
- For my music sync features, use in a quiet environment
- I recommend creating rooms first, then adding devices to them
- Experiment with scenes for quick mood changes

## 🎬 Features in Action

### Music Sync Mode

I've created a way to transform your space with lights that pulse and change with your music:

<div align="center">
  <img src="Resources/Screenshots/music-sync.png" width="300" alt="Music Sync Feature"/>
</div>

### Virtual LED Strip

I've implemented a system to combine multiple lights to create chase effects and waves:

<div align="center">
  <img src="Resources/Screenshots/led-strip.png" width="300" alt="Virtual LED Strip"/>
</div>

### Scene Creation

I've built a powerful editor to design and save custom lighting scenes for any occasion:

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

I've designed YeelightControl with a unique project structure that separates source code from the Xcode build environment:

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

- **SwiftUI Framework**: I've built the app with modern declarative UI
- **Combine Framework**: I've used reactive programming for state management
- **Background Tasks**: I've implemented reliable background updates
- **WidgetKit**: I've created home screen widgets for quick control
- **Network Discovery**: I've added automatic device detection using Bonjour
- **Async/Await**: I've utilized modern concurrency for network operations

### Module Documentation

For detailed documentation on specific modules, see:
- [Device Module Documentation](Sources/Core/Device/DEVICE_MODULE.md)
- [Scenes Feature Documentation](Sources/Features/Scenes/SCENES_FEATURE.md)

> **Note**: To avoid build conflicts, all module-specific README files have been renamed to follow the pattern `MODULE_README.md` or given unique names like `DEVICE_MODULE.md`. This prevents the "Multiple commands produce README.md" error during build.

### Building from Source

<details>
<summary>Click to expand build instructions</summary>

#### Requirements
- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- xcodegen (`brew install xcodegen`)

#### Steps
1. Clone my repository
```bash
git clone https://github.com/DanielKng/YeelightControl.git
cd YeelightControl
```

2. Install xcodegen if you haven't already
```bash
brew install xcodegen
```

3. Generate the Xcode project
```bash
chmod +x ./setup_xcode_project.sh
./setup_xcode_project.sh
```

4. Open the project
```bash
cd Xcode
./open_project.sh
```

> **Important**: The `/Xcode` directory is generated by the setup script and is NOT tracked by Git. 
> Do not manually commit any files from this directory as they are automatically generated.

5. Configure signing and build

#### Troubleshooting Project Generation
If you encounter issues with the generated Xcode project:

1. Verify xcodegen is installed correctly:
```bash
xcodegen --version
```

2. If xcodegen is not found, install it:
```bash
brew install xcodegen
```

3. If you see an error about Xcode's Info.plist:
```
Couldn't find Xcode's Info.plist at /Library/Contents/Info.plist
```
Run the following command to set your Xcode path correctly:
```bash
sudo xcode-select -s /Applications/Xcode.app
```
Then run the setup script again.

4. If issues persist, you can create a new Xcode project manually:
   - Create a new iOS App project with SwiftUI interface in Xcode
   - Add the source files from the `/Sources` directory
   - Configure the Info.plist with required permissions for network and microphone access
</details>

## 👥 Contributing

I welcome contributions! See my [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas for Improvement

- Additional device type support
- HomeKit integration
- Localization to more languages
- Advanced automation conditions

## 📄 License

I'm making YeelightControl available under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

I couldn't have built this project without the amazing work of:

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

Special thanks to all contributors and testers who have helped me improve this project.

---

<div align="center">
  
Made with ❤️ by [Daniel Kng](https://github.com/DanielKng)

[Report Bug](https://github.com/DanielKng/YeelightControl/issues/new?template=bug_report.md) · 
[Request Feature](https://github.com/DanielKng/YeelightControl/issues/new?template=feature_request.md)

</div>