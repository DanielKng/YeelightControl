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
├── App/                    # Main app entry point
├── Core/                   # Core functionality and services
│   ├── Analytics/         # Analytics tracking
│   ├── Background/        # Background task handling
│   ├── Configuration/     # App configuration
│   ├── Device/           # Device management
│   ├── Effect/           # Effect handling
│   ├── Error/            # Centralized error handling
│   ├── Location/         # Location services
│   ├── Network/          # Network communication
│   ├── Notification/     # Push notifications
│   ├── Permission/       # Permission handling
│   ├── Scene/            # Scene management
│   ├── Security/         # Security features
│   ├── Services/         # Core service protocols
│   ├── State/            # State management
│   └── Storage/          # Data persistence
│
├── Features/              # Feature-specific implementations
│   ├── Automation/       # Automation features
│   ├── Effects/          # Light effects
│   ├── Rooms/            # Room management
│   └── Scenes/           # Scene management
│
├── UI/                    # UI components and views
│   ├── Components/       # Reusable UI components
│   └── Views/            # Feature-specific views
│       ├── DeviceViews/
│       ├── SceneViews/
│       └── EffectViews/
│
├── Tests/                 # Test files
│   └── UITests/          # UI Tests
│
└── Widget/                # Widget extension
```

## 🏗 Architecture

The project follows a clean, modular architecture with clear separation of concerns:

### Core Module
> Foundation of the application, containing essential services and managers.

- **Device Management** - Device discovery and control
- **Error Handling** - Centralized error management
- **Storage** - Data persistence layer
- **Network** - Communication protocols
- **Security** - Authentication and encryption

### Features Module
> Self-contained feature implementations building on core functionality.

- **Automation** - Scheduling and triggers
- **Scenes** - Lighting scene management
- **Effects** - Dynamic lighting effects
- **Rooms** - Space organization

### UI Module
> SwiftUI views and components organized by feature.

- **Components** - Reusable UI elements
- **Views** - Feature-specific interfaces
  - Device management
  - Scene creation
  - Effect configuration

## 🚀 Getting Started

### Prerequisites

- macOS Ventura or later
- Xcode 15.2+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Installation

1. **Clone and Setup**
   ```bash
   # Clone repository
   git clone https://github.com/DanielKng/YeelightControl.git
   cd YeelightControl

   # Make scripts executable
   chmod +x Scripts/*.sh
   ```

2. **Project Generation**
   ```bash
   # Clean and organize
   ./Scripts/reorganize.sh

   # Generate Xcode project
   ./Scripts/setup_xcode_project.sh
   ```

3. **Open in Xcode**
   ```