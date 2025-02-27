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

I've designed YeelightControl with a clean and modular project structure:

```
YeelightControl/
├── Sources/           # Main source code
│   ├── App/          # Main app target
│   │   ├── YeelightControlApp.swift
│   │   ├── ContentView.swift
│   │   └── Info.plist
│   │
│   ├── Widget/       # Widget extension
│   │   ├── YeelightWidget.swift
│   │   └── Info.plist
│   │
│   ├── Models/       # Data models
│   ├── Views/        # SwiftUI views
│   ├── Controllers/  # View controllers
│   ├── Utils/        # Utility functions
│   ├── Extensions/   # Swift extensions
│   └── Services/     # Core services
│
├── Resources/        # App resources
│   ├── Assets/       # Images and assets
│   ├── Configs/      # Configuration files
│   │   ├── Package.swift  # Swift package definition
│   │   └── project.yml    # XcodeGen configuration
│   └── Localization/ # Localization files
│
├── Scripts/         # Development scripts
│   ├── setup_xcode_project.sh  # Generate Xcode project
│   ├── cleanup.sh              # Clean temporary files
│   ├── reorganize.sh           # Maintain project structure
│   └── git_push.sh            # Git push helper
│
├── Tests/          # Test files
│   └── YeelightControlTests/  # Unit tests
│
└── .github/        # GitHub configuration
```

### Development Scripts

I've provided several utility scripts to help maintain the project:

1. **Project Setup**
   ```bash
   ./Scripts/setup_xcode_project.sh
   ```
   - Generates Xcode project using XcodeGen
   - Creates necessary directory structure
   - Sets up main app and widget targets
   - Configures build settings
   - Creates initial SwiftUI views

2. **Project Cleanup and Reorganization**
   ```bash
   ./Scripts/reorganize.sh
   ```
   - Creates verified backup of current state
   - Cleans derived data and temporary files
   - Removes build artifacts and old backups
   - Maintains consistent directory structure
   - Safely restores files with verification
   - Performs multiple safety checks
   - Auto-recovers from failures
   - Maintains proper file permissions
   - Verifies Swift file count at each step

3. **Git Push Helper**
   ```bash
   ./Scripts/git_push.sh
   ```
   - Shows pending changes
   - Prompts for confirmation
   - Collects commit message
   - Handles git add, commit, and push
   - Supports any current branch

### Development Workflow

I've designed the development workflow to be smooth and maintainable:

1. **Initial Setup**
   ```bash
   # Clone and setup
   git clone https://github.com/DanielKng/YeelightControl.git
   cd YeelightControl
   chmod +x Scripts/*.sh
   
   # Install required tools
   brew install xcodegen
   
   # Generate project
   ./Scripts/setup_xcode_project.sh
   ```

2. **Daily Development**
   - Work directly in the `/Sources` directory
   - All source code changes should be made in the appropriate `/Sources` subdirectories
   - The `/Build` directory is temporary and automatically generated
   - Run `./Scripts/setup_xcode_project.sh` when you need to test in Xcode
   - Use your preferred editor to modify source files
   - Changes are tracked in git from the `/Sources` and `/Resources` directories

3. **Before Committing**
   ```bash
   # Clean and reorganize project
   ./Scripts/reorganize.sh
   ```

4. **After Pulling Updates**
   ```bash
   # Clean, reorganize, and regenerate project
   ./Scripts/reorganize.sh
   ./Scripts/setup_xcode_project.sh
   ```

### Project Maintenance

The project uses several strategies to maintain cleanliness and organization:

1. **Build Management**
   - Build directory is temporary and regenerated
   - Never commit Build directory contents
   - Use cleanup script before commits

2. **Resource Management**
   - Keep Resources directory organized
   - Use Assets catalog for images
   - Maintain localization files

3. **Source Organization**
   - Follow modular architecture
   - Keep features isolated
   - Use clear naming conventions

4. **Script Management**
   - Scripts are in dedicated directory
   - Symbolic links for convenience
   - Regular cleanup and maintenance

### Advanced Troubleshooting

#### Build Issues

1. **Clean Build Fails**
   ```bash
   # Full cleanup
   ./Scripts/cleanup.sh
   rm -rf ~/Library/Developer/Xcode/DerivedData/*YeelightControl*
   rm -rf Build/
   
   # Regenerate
   ./Scripts/setup_xcode_project.sh
   ```

2. **Symbolic Link Issues**
   ```bash
   # Check symbolic links
   ls -la
   
   # Recreate if needed
   ./Scripts/reorganize.sh
   ```

3. **Resource Missing**
   ```bash
   # Verify resources
   ls -la Resources/
   
   # Restore from backup
   git checkout Resources/
   ```

4. **Script Permission Issues**
   ```bash
   # Fix permissions
   chmod +x Scripts/*.sh
   chmod +x *.sh  # For symbolic links
   ```

#### Project Structure Issues

1. **Missing Directories**
   ```bash
   # Recreate structure
   ./Scripts/reorganize.sh
   
   # Verify
   tree -L 3
   ```

2. **Backup Recovery**
   ```bash
   # Check backups
   ls -la temp_backup/
   
   # Restore specific backup
   cp -R temp_backup/backup_YYYYMMDD_HHMMSS/* .
   ```

3. **Git Issues**
   ```bash
   # Clean untracked files
   git clean -fdx
   
   # Reset to clean state
   git reset --hard HEAD
   ./Scripts/reorganize.sh
   ```

#### Common Error Solutions

| Error | Solution |
|-------|----------|
| **"Build directory not found"** | Run `./Scripts/setup_xcode_project.sh` to regenerate |
| **"Permission denied"** | Run `chmod +x Scripts/*.sh` and try again |
| **"Resource not found"** | Check symbolic links with `ls -la` |
| **"Script not found"** | Ensure you're in project root directory |
| **"Invalid project structure"** | Run `./Scripts/reorganize.sh` to fix |

#### Performance Issues

1. **Slow Build Times**
   - Clean DerivedData
   - Remove Build directory
   - Close other Xcode projects
   - Reset simulator state

2. **Git Performance**
   ```bash
   # Optimize repository
   git gc --aggressive --prune=now
   git repack -a -d --depth=250 --window=250
   ```

3. **Xcode Issues**
   - Reset window arrangement
   - Clear derived data
   - Reset simulator content
   - Restart Xcode

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