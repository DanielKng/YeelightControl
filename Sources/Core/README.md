# Core Module

## Overview
The Core module serves as the foundation of the YeelightControl application, providing essential services, types, and utilities that power the entire system.

> 📘 For detailed documentation, see:
> - [Core APIs Reference](../../docs/reference/api-reference.md#core-apis)
> - [Implementation Examples](../../docs/examples/)
> - [Best Practices](../../docs/reference/api-reference.md#best-practices)

## Directory Structure
```
Core/
├── Analytics/      - Usage tracking and performance monitoring
├── Background/     - Background task management
├── Configuration/  - System and user preferences
├── Device/         - Device discovery and control
├── Effect/         - Lighting effect implementation
├── Error/         - Error handling and recovery
├── Location/      - Geolocation services
├── Logging/       - System logging and debugging
├── Network/       - Network communication
├── Notification/  - Push and local notifications
├── Permission/    - System permission handling
├── Scene/         - Scene management
├── Security/      - Authentication and encryption
├── Services/      - Core service implementations
├── State/         - Application state management
├── Storage/       - Data persistence
└── Types/         - Common type definitions
```

## Key Components

### Device Management
> 📘 [Device Management Documentation](../../docs/reference/api-reference.md#device-management)

### Effect System
> 📘 [Effect Management Documentation](../../docs/reference/api-reference.md#effect-management)

### Scene Management
> 📘 [Scene Management Documentation](../../docs/reference/api-reference.md#scene-management)

### Error Handling
> 📘 [Error Handling Documentation](../../docs/reference/api-reference.md#error-handling)

## Dependencies
- Foundation
- Combine
- CoreLocation
- Network
- Security

## Thread Safety
The Core module is designed with thread safety in mind. All public APIs are thread-safe, state modifications are synchronized, and background operations are properly queued.

> 🔒 For security considerations, see the [Security Guide](../../docs/guides/security.md)
> 
> 🔧 For troubleshooting, see the [Troubleshooting Guide](../../docs/guides/troubleshooting.md)
