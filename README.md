# YeelightControl

<div align="center">

![YeelightControl Header](Resources/header.png)

> Transform your space with intelligent lighting control

[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/Framework-SwiftUI-purple.svg)](https://developer.apple.com/xcode/swiftui/)
[![Build Status](https://github.com/DanielKng/YeelightControl/actions/workflows/ios.yml/badge.svg)](https://github.com/DanielKng/YeelightControl/actions)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

[Features](#-key-features) • [Installation](#-getting-started) • [Documentation](docs/API.md) • [Contributing](CONTRIBUTING.md)

---

<p align="center">
  <img src="Resources/Screenshots/home.png" width="200" alt="Home Screen"/>
  &nbsp;&nbsp;&nbsp;
  <img src="Resources/Screenshots/scenes.png" width="200" alt="Scene Management"/>
  &nbsp;&nbsp;&nbsp;
  <img src="Resources/Screenshots/automation.png" width="200" alt="Automation"/>
</p>

</div>

A modern iOS app for controlling Yeelight smart lighting devices. Built with SwiftUI and following a modular architecture.

## ✨ Key Features

### 🎨 Creative Lighting Control
- **Dynamic Color Flows** - Create mesmerizing patterns and transitions
- **Music Sync** - Light effects that pulse with your music
- **Scene Presets** - Save and recall your perfect lighting setups
- **Group Control** - Manage multiple lights simultaneously

### 🤖 Smart Automation
- **Time-Based Triggers** - Schedule automatic light changes
- **Location Awareness** - Lights respond to your presence
- **Sunrise/Sunset** - Sync with natural light cycles
- **Custom Rules** - Create complex automation scenarios

### 🔌 Advanced Capabilities
- **Offline Support** - Full functionality without internet
- **Quick Actions** - Control from home screen widgets
- **Virtual LED Strips** - Combine lights for chase effects
- **Secure Control** - Local network communication

### 💡 Device Features
- **Instant Control** - Quick brightness and color adjustments
- **Room Organization** - Group lights by location
- **Status Monitoring** - Real-time device updates
- **Energy Saving** - Optimize power consumption

### 🛠 Power User Tools
- **Network Diagnostics** - Built-in connectivity testing
- **Backup & Restore** - Save your configurations
- **Advanced Settings** - Fine-tune every aspect
- **Detailed Logging** - Track system behavior

## 🛠 Project Structure

```
Sources/
├── App/
├── Controllers/
├── Core/
│   ├── Analytics/
│   ├── Background/
│   ├── Configuration/
│   ├── Device/
│   ├── Effect/
│   ├── Error/
│   ├── Location/
│   ├── Network/
│   ├── Notification/
│   ├── Permission/
│   ├── Scene/
│   ├── Security/
│   ├── Services/
│   ├── State/
│   └── Storage/
│
├── Extensions/
│
├── Features/
│   ├── Automation/
│   ├── Effects/
│   ├── Rooms/
│   └── Scenes/
│
├── Models/
│
├── Services/
│
├── Tests/
│   ├── UITests/
│   └── UnitTests/
│
├── UI/
│   ├── Components/
│   │   └── Common/
│   └── Views/
│       └── Unified/
│
├── Utils/
│
├── Views/
│
└── Widget/
```

## 🏗 Architecture

The project follows a modular architecture with clear separation of concerns:

### Core Module
- **Services Layer** - Core business logic and protocols
- **Models** - Shared data models
- **Utils** - Common utilities and helpers

### Features Module
- **Automation** - Scheduling and triggers
- **Effects** - Dynamic lighting effects
- **Scenes** - Lighting scene management

### UI Module
- **Components** - Reusable UI elements
- **Views** - Feature-specific interfaces

## 🚀 Getting Started

### Prerequisites

- macOS Ventura or later
- Xcode 15.2+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/DanielKng/YeelightControl.git
   cd YeelightControl
   ```

2. **Generate Xcode Project**
   ```bash
   ./Scripts/setup_xcode_project.sh
   ```
   This script will:
   - Create the necessary build directory structure
   - Set up symlinks for source files
   - Generate the Xcode project using XcodeGen

3. **Open and Build**
   ```bash
   open Build/YeelightControl.xcodeproj
   ```

## 🧪 Testing

The project includes both UI and Unit tests:

```bash
cd Build
xcodebuild test -scheme YeelightControl -destination "platform=iOS Simulator,name=iPhone 16 Pro Max"
```

## 📦 Continuous Integration

GitHub Actions automatically builds and tests the project on every push and pull request to the main branch. The workflow:
- Sets up the macOS environment
- Installs dependencies
- Generates the Xcode project
- Builds and tests the app

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.