# YeelightControl

<div align="center">

![YeelightControl Header](Resources/header.png)

> Transform your space with intelligent lighting control

[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/Framework-SwiftUI-purple.svg)](https://developer.apple.com/xcode/swiftui/)
[![Build Status](https://github.com/DanielKng/YeelightControl/actions/workflows/ios.yml/badge.svg)](https://github.com/DanielKng/YeelightControl/actions)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

[Features](#features) • [Quick Start](#quick-start) • [Documentation](#documentation) • [Contributing](CONTRIBUTING.md)

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

## Features

📱 **Smart Control**
- Dynamic color flows and transitions
- Scene management and scheduling
- Group control and room organization
- Chase light effects (combine multiple lights)
- Music synchronization

🤖 **Automation**
- Time-based triggers
- Location awareness
- Custom rules and conditions
- Offline support

🔒 **Security & Reliability**
- Local network communication
- Secure device control
- Robust error handling
- Comprehensive logging

> 📚 [View all features in documentation](docs/reference/api-reference.md#core-apis)

## Quick Start

### Prerequisites
- macOS Ventura or later
- Xcode 15.2+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### Installation

1. **Clone and Setup**
   ```bash
   git clone https://github.com/DanielKng/YeelightControl.git
   cd YeelightControl
   ```

2. **Generate Xcode Project**
   ```bash
   ./Scripts/setup_xcode_project.sh
   ```
   This script will:
   - Create the build directory structure
   - Set up source file symlinks
   - Generate the Xcode project using XcodeGen

3. **Open Project**
   ```bash
   open Build/YeelightControl.xcodeproj
   ```

> 🚀 [Detailed installation guide](docs/guides/getting-started.md#installation)

## Documentation

### Guides
- [Getting Started Guide](docs/guides/getting-started.md)
- [Security Best Practices](docs/guides/security.md)
- [Troubleshooting](docs/guides/troubleshooting.md)

### API Reference
- [Core APIs](docs/reference/api-reference.md#core-apis)
- [Feature APIs](docs/reference/api-reference.md#feature-apis)
- [UI Components](docs/reference/api-reference.md#ui-components)

### Examples
- [Basic Device Control](docs/examples/basic-control/README.md)
- [Lighting Effects](docs/examples/effects/README.md)
- [Scene Management](docs/examples/scenes/README.md)

### Module Documentation
- [Core Module](Sources/Core/README.md)
- [Features Module](Sources/Features/README.md)
- [UI Module](Sources/UI/README.md)

## Project Structure

```
Sources/
├── App/          # Application entry point
├── Core/         # Core functionality
├── Features/     # Feature modules
├── UI/          # User interface
├── Tests/       # Test suites
└── Widget/      # Home screen widgets
```

> 📘 [Detailed architecture overview](docs/reference/api-reference.md#overview)

## Contributing

Want to contribute? Check out the [Contributing Guidelines](CONTRIBUTING.md) for details on submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.